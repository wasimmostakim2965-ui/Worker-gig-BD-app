import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'post_job_screen.dart';

/// Mirrors MyJobsPage + the buyer review flow from MyTasksPage:
/// the job owner reviews worker submissions and approves/rejects them
/// through the process_task RPC.
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  List<Job> _jobs = [];
  bool _loading = true;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = context.read<AuthService>().profile;
    if (profile == null) return;
    setState(() => _loading = true);
    try {
      final rows = await _db
          .from('jobs')
          .select()
          .eq('user_id', profile.id)
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() => _jobs = rows.map(Job.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Load my jobs error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Post a job',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostJobScreen()),
              );
              _load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingView()
            : _jobs.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      const EmptyView(Icons.business_center_outlined,
                          'No jobs posted yet',
                          subtitle: 'Post a job and let workers complete it.'),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PostJobScreen()),
                            );
                            _load();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Post a Job'),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final j = _jobs[i];
                      return Card(
                        child: ListTile(
                          title: Text(j.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${j.filledSlots}/${j.totalSlots} done • ${fmtMoney(j.rewardPerWorker)} per worker',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: StatusBadge(j.status),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    JobSubmissionsScreen(job: j)),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

/// Buyer-side review screen: all worker submissions for one job with
/// approve / reject buttons calling process_task (same RPC as the web).
class JobSubmissionsScreen extends StatefulWidget {
  final Job job;
  const JobSubmissionsScreen({super.key, required this.job});

  @override
  State<JobSubmissionsScreen> createState() => _JobSubmissionsScreenState();
}

class _JobSubmissionsScreenState extends State<JobSubmissionsScreen> {
  List<TaskItem> _subs = [];
  bool _loading = true;
  String? _busyId;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _db
          .from('tasks')
          .select('*, jobs(*)')
          .eq('job_id', widget.job.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _subs = rows.map(TaskItem.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Load submissions error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _process(TaskItem t, String action, {String note = ''}) async {
    final profile = context.read<AuthService>().profile;
    if (profile == null) return;
    setState(() => _busyId = t.id);
    try {
      await _db.rpc('process_task', params: {
        'p_task_id': t.id,
        'p_admin_uid': profile.id,
        'p_action': action,
        'p_note': note,
      });
      if (mounted) {
        showSnack(context,
            action == 'approve' ? 'Task approved' : 'Task rejected');
      }
      await _load();
      if (mounted) context.read<AuthService>().refreshProfile();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
    if (mounted) setState(() => _busyId = null);
  }

  Future<void> _rejectWithReason(TaskItem t) async {
    final ctrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject reason'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Why is this submission rejected? (optional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Reject')),
        ],
      ),
    );
    if (note != null) await _process(t, 'reject', note: note);
  }

  List<String> _proofImages(String proofUrl) {
    if (proofUrl.isEmpty) return [];
    try {
      final decoded = jsonDecode(proofUrl);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return [proofUrl];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.job.title)),
      body: _loading
          ? const LoadingView()
          : _subs.isEmpty
              ? const EmptyView(
                  Icons.inbox_outlined, 'No submissions yet')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = _subs[i];
                    final images = _proofImages(t.proofUrl);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Worker: ${t.workerId.substring(0, 8)}…',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                StatusBadge(t.status),
                              ],
                            ),
                            if (t.proofText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(t.proofText,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.gray600)),
                            ],
                            if (images.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 72,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, k) => GestureDetector(
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: InteractiveViewer(
                                          child:
                                              Image.network(images[k]),
                                        ),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: Image.network(images[k],
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (t.status == 'submitted') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            AppColors.success600,
                                        minimumSize:
                                            const Size.fromHeight(40),
                                      ),
                                      onPressed: _busyId == t.id
                                          ? null
                                          : () => _process(t, 'approve'),
                                      icon: const Icon(Icons.check,
                                          size: 18),
                                      label: const Text('Approve'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.error600,
                                        minimumSize:
                                            const Size.fromHeight(40),
                                      ),
                                      onPressed: _busyId == t.id
                                          ? null
                                          : () => _rejectWithReason(t),
                                      icon: const Icon(Icons.close,
                                          size: 18),
                                      label: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (t.status == 'rejected' &&
                                (t.adminNote?.isNotEmpty ?? false)) ...[
                              const SizedBox(height: 8),
                              Text('Reason: ${t.adminNote}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error600)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
