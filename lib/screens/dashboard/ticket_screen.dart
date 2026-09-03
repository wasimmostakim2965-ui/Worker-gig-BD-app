import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors TicketPage.tsx: list my tickets, open a thread, create a new
/// ticket with subject/category/priority, and reply inside a ticket.
class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    try {
      final rows = await auth.client
          .from('tickets')
          .select()
          .eq('user_id', auth.profile!.id)
          .order('updated_at', ascending: false)
          .limit(50);
      _tickets = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _newTicket() async {
    final created = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const _NewTicketScreen()));
    if (created == true) {
      setState(() => _loading = true);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTicket,
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const EmptyState(
                  icon: Icons.support_agent,
                  title: 'No tickets yet',
                  subtitle: 'Open a ticket if you need help.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, i) {
                      final t = _tickets[i];
                      return Card(
                        child: ListTile(
                          title: Text(t['subject'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${t['category']} • ${t['priority']} • ${fmtDate(t['updated_at'])}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: StatusBadge(t['status'] ?? 'open'),
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => TicketThreadScreen(
                                        ticket: Map<String, dynamic>.from(t))));
                            _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _NewTicketScreen extends StatefulWidget {
  const _NewTicketScreen();

  @override
  State<_NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<_NewTicketScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'general';
  String _priority = 'normal';
  bool _busy = false;
  String? _error;

  static const _categories = [
    'general',
    'payment',
    'deposit',
    'withdrawal',
    'task',
    'account',
    'other',
  ];
  static const _priorities = ['low', 'normal', 'high', 'urgent'];

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _error = 'Subject and message are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    try {
      final ticket = await auth.client
          .from('tickets')
          .insert({
            'user_id': auth.profile!.id,
            'subject': _subject.text.trim(),
            'category': _category,
            'priority': _priority,
            'status': 'open',
          })
          .select()
          .single();
      await auth.client.from('ticket_messages').insert({
        'ticket_id': ticket['id'],
        'sender_id': auth.profile!.id,
        'message': _message.text.trim(),
        'is_admin_reply': false,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Ticket')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? 'general'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: _priorities
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _priority = v ?? 'normal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLines: 5,
            decoration: const InputDecoration(
                labelText: 'Message', alignLabelWithHint: true),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style:
                    const TextStyle(color: AppColors.danger600, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Submitting...' : 'Submit Ticket'),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketThreadScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const TicketThreadScreen({super.key, required this.ticket});

  @override
  State<TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends State<TicketThreadScreen> {
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
        'is_admin_reply': false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket['subject'] ?? 'Ticket',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child:
                Center(child: StatusBadge(widget.ticket['status'] ?? 'open')),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isAdmin = m['is_admin_reply'] == true;
                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Colors.white
                                : AppColors.primary600,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['message'] ?? '',
                                  style: TextStyle(
                                      color: isAdmin
                                          ? AppColors.gray900
                                          : Colors.white,
                                      height: 1.4)),
                              const SizedBox(height: 2),
                              Text(
                                '${isAdmin ? 'Support' : 'You'} • ${fmtDate(m['created_at'])}',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: isAdmin
                                        ? AppColors.gray500
                                        : AppColors.primary100),
                              ),
                            ],
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
                            hintText: 'Write a reply...', isDense: true),
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
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('This ticket is closed.',
                  style: TextStyle(color: AppColors.gray500, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
