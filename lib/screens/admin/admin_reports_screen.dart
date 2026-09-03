import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminReportsPage.tsx: open/resolved tabs, resolve reports.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _tab = 'open';
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = context.read<AuthService>().client;
    try {
      final rows = await client
          .from('reports')
          .select()
          .eq('status', _tab)
          .order('created_at', ascending: false)
          .limit(100);
      _rows = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resolve(Map<String, dynamic> r) async {
    final client = context.read<AuthService>().client;
    try {
      await client.from('reports').update({
        'status': 'resolved',
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', r['id']);
      if (mounted) {
        setState(() => _loading = true);
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'open', label: Text('Open')),
                ButtonSegment(value: 'resolved', label: Text('Resolved')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) {
                setState(() {
                  _tab = s.first;
                  _loading = true;
                });
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const EmptyState(
                        icon: Icons.flag_outlined,
                        title: 'No reports',
                        subtitle: 'User reports will appear here.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) {
                            final r = _rows[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                              r['subject'] ?? r['reason'] ?? 'Report',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        StatusBadge(r['status'] ?? 'open'),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if ((r['description'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(r['description'],
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.gray600,
                                              height: 1.4)),
                                    if ((r['job_id'] ?? '').toString().isNotEmpty)
                                      Text('Job: ${r['job_id']}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.gray500)),
                                    const SizedBox(height: 4),
                                    Text(fmtDate(r['created_at']),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.gray500)),
                                    if (_tab == 'open') ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: FilledButton.tonal(
                                          onPressed: () => _resolve(r),
                                          child: const Text('Resolve'),
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
          ),
        ],
      ),
    );
  }
}
