import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors MyTasksPage: the worker's submissions with status badges.
class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  List<TaskItem> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = context.read<AuthService>().profile;
    if (profile == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final rows = await Supabase.instance.client
          .from('tasks')
          .select('*, jobs(*)')
          .eq('worker_id', profile.id)
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() => _tasks = rows.map(TaskItem.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Load my tasks error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingView()
            : _tasks.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyView(Icons.assignment_outlined, 'No tasks yet',
                          subtitle:
                              'Accept a job from Find Jobs to get started.'),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = _tasks[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.job?.title ?? 'Job',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                  ),
                                  StatusBadge(t.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    fmtMoney(t.job?.rewardPerWorker),
                                    style: const TextStyle(
                                        color: AppColors.earnGreen,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  if (t.tipAmount > 0) ...[
                                    const SizedBox(width: 8),
                                    Text('+ ${fmtMoney(t.tipAmount)} tip',
                                        style: const TextStyle(
                                            color: AppColors.accent500,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                  const Spacer(),
                                  if (t.submittedAt != null)
                                    Text(
                                      DateFormat('d MMM yyyy').format(
                                          DateTime.tryParse(t.submittedAt!) ??
                                              DateTime.now()),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.gray500),
                                    ),
                                ],
                              ),
                              if (t.status == 'rejected' &&
                                  (t.adminNote?.isNotEmpty ?? false)) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.error50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Reject reason: ${t.adminNote}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.error600),
                                  ),
                                ),
                              ],
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
