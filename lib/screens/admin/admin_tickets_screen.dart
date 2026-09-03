import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminTicketsPage.tsx: list all tickets, reply as admin
/// (trigger flips status to 'answered'), and close tickets.
class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
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
          .from('tickets')
          .select('*, profiles(username)')
          .order('updated_at', ascending: false)
          .limit(100);
      _rows = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const EmptyState(
                  icon: Icons.support_agent,
                  title: 'No tickets',
                  subtitle: 'User tickets will appear here.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final t = _rows[i];
                      final username =
                          (t['profiles']?['username'] ?? 'user').toString();
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.support_agent,
                              color: AppColors.primary600),
                          title: Text(t['subject'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '@$username • ${t['category']} • ${t['priority']} • ${fmtDate(t['updated_at'])}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: StatusBadge(t['status'] ?? 'open'),
                          onTap: () => _open(t),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _open(Map<String, dynamic> t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _AdminTicketThread(ticket: t)),
    );
    setState(() => _loading = true);
    _load();
  }

}

class _AdminTicketThread extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const _AdminTicketThread({required this.ticket});

  @override
  State<_AdminTicketThread> createState() => _AdminTicketThreadState();
}

class _AdminTicketThreadState extends State<_AdminTicketThread> {
  final _reply = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _busy = false;

  bool get _closed => widget.ticket['status'] == 'closed';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = context.read<AuthService>().client;
    try {
      final rows = await client
          .from('ticket_messages')
          .select()
          .eq('ticket_id', widget.ticket['id'])
          .order('created_at', ascending: true);
      _messages = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    if (_reply.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final auth = context.read<AuthService>();
    try {
      await auth.client.from('ticket_messages').insert({
        'ticket_id': widget.ticket['id'],
        'sender_id': auth.profile!.id,
        'message': _reply.text.trim(),
        'is_admin_reply': true,
      });
      _reply.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _close() async {
    final client = context.read<AuthService>().client;
    try {
      await client.from('tickets').update({
        'status': 'closed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.ticket['id']);
      widget.ticket['status'] = 'closed';
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket['subject'] ?? 'Ticket',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (!_closed)
            IconButton(
              tooltip: 'Close ticket',
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _close,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isAdmin = m['is_admin_reply'] == true;
                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AppColors.primary600
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: Text(
                            m['message'] ?? '',
                            style: TextStyle(
                                color: isAdmin
                                    ? Colors.white
                                    : AppColors.gray900,
                                height: 1.4),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (!_closed)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _reply,
                        decoration: const InputDecoration(
                            hintText: 'Reply as admin...', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
