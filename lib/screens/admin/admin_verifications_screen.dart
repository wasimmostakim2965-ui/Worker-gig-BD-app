import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminVerificationsPage.tsx: approve/reject verification requests.
/// Approval also calls set_user_verified and notifies the user — same as web.
class AdminVerificationsScreen extends StatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  State<AdminVerificationsScreen> createState() =>
      _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends State<AdminVerificationsScreen> {
  String _tab = 'pending';
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
          .from('verification_requests')
          .select('*, profiles(username)')
          .eq('status', _tab)
          .order('created_at', ascending: false)
          .limit(100);
      _rows = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _decide(Map<String, dynamic> req, String action) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action == 'approved' ? 'Approve' : 'Reject'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(labelText: 'Admin note (optional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action == 'approved' ? 'Approve' : 'Reject')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final client = context.read<AuthService>().client;
    try {
      await client.from('verification_requests').update({
        'status': action,
        'admin_note': noteCtrl.text.trim(),
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', req['id']);

      if (action == 'approved') {
        await client.rpc('set_user_verified',
            params: {'p_user_uid': req['user_id'], 'p_verified': true});
        await client.rpc('notify_user', params: {
          'target_uid': req['user_id'],
          'n_title': 'Account Verified!',
          'n_message':
              'Your identity has been verified. You now have the verified badge.',
          'n_type': 'success',
        });
      } else {
        await client.rpc('notify_user', params: {
          'target_uid': req['user_id'],
          'n_title': 'Verification Rejected',
          'n_message':
              'Your verification request was rejected. ${noteCtrl.text.trim()}',
          'n_type': 'error',
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Request $action.')));
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

  void _viewDoc(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url,
              errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Could not load document image.'))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Pending')),
                ButtonSegment(value: 'approved', label: Text('Approved')),
                ButtonSegment(value: 'rejected', label: Text('Rejected')),
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
                        icon: Icons.verified_user,
                        title: 'Nothing here',
                        subtitle: 'No requests in this tab.')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _rows.length,
                          itemBuilder: (context, i) {
                            final r = _rows[i];
                            final username =
                                (r['profiles']?['username'] ?? 'user')
                                    .toString();
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.badge_outlined,
                                    color: AppColors.primary600),
                                title: Text('@$username',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    fmtDate(r['created_at']),
                                    style: const TextStyle(fontSize: 12)),
                                trailing: _tab == 'pending'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_red_eye,
                                                color: AppColors.gray600),
                                            onPressed: () => _viewDoc(
                                                r['document_url'] ?? ''),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check_circle,
                                                color: AppColors.earnGreen),
                                            onPressed: () =>
                                                _decide(r, 'approved'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel,
                                                color: AppColors.danger600),
                                            onPressed: () =>
                                                _decide(r, 'rejected'),
                                          ),
                                        ],
                                      )
                                    : StatusBadge(r['status'] ?? ''),
                                onTap: () => _viewDoc(r['document_url'] ?? ''),
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
