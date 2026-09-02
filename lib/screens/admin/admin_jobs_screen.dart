import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminJobsPage: review all jobs and delete via delete_job RPC.
class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  List<Job> _jobs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await Supabase.instance.client
          .from('jobs')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() => _jobs = rows.map(Job.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Admin jobs error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(Job j) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text('"${j.title}" will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client
          .rpc('delete_job', params: {'p_job_id': j.id});
      if (mounted) showSnack(context, 'Job deleted');
      _load();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Jobs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _jobs.isEmpty
              ? const EmptyView(Icons.work_outline, 'No jobs')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final j = _jobs[i];
                      return Card(
                        child: ListTile(
                          title: Text(j.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          subtitle: Text(
                            '${j.filledSlots}/${j.totalSlots} • ${fmtMoney(j.rewardPerWorker)} • ${j.category}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusBadge(j.status),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error600, size: 20),
                                onPressed: () => _delete(j),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
