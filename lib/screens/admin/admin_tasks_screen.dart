import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminTasksPage: review all submitted tasks and
/// approve/reject via process_task RPC.
class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  List<TaskItem> _items = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await Supabase.instance.client
          .from('tasks')
          .select('*, jobs(title, reward_per_worker)')
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() => _items = rows.map(TaskItem.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Admin tasks error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _process(TaskItem t, String action, {String note = ''}) async {
    final admin = context.read<AuthService>().profile;
    if (admin == null) return;
    setState(() => _busyId = t.id);
    try {
      await Supabase.instance.client.rpc('process_task', params: {
        'p_task_id': t.id,
        'p_admin_uid': admin.id,
        'p_action': action,
        'p_note': note,
      });
      if (mounted) showSnack(context, 'Task ${action}d');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
    if (mounted) setState(() => _busyId = null);
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
    final submitted = _items.where((t) => t.status == 'submitted').toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Review (${submitted.length} waiting)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const EmptyView(Icons.assignment_outlined, 'No tasks')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = _items[i];
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
                                  child: Text(t.job?.title ?? 'Task',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                ),
                                StatusBadge(t.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                                'Worker: ${shortId(t.workerId)} • ${fmtMoney(t.job?.rewardPerWorker)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray500)),
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
                                          child: Image.network(images[k]),
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
                                          : () =>
                                              _process(t, 'approve'),
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
                                          : () => _process(t, 'reject',
                                              note:
                                                  'Task did not meet requirements.'),
                                      icon: const Icon(Icons.close,
                                          size: 18),
                                      label: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ),
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
