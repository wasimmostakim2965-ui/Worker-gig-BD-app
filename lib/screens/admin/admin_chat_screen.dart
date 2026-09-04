import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminLiveChatPage.tsx: conversation list (with unread counts)
/// and a chat thread where the admin replies.
class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  List<Map<String, dynamic>> _convs = [];
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
          .from('chat_conversations')
          .select('*, profiles(username)')
          .order('updated_at', ascending: false)
          .limit(100);
      _convs = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _convs.isEmpty
          ? const EmptyState(
              icon: Icons.forum,
              title: 'No conversations',
              subtitle: 'User chats will appear here.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _convs.length,
                itemBuilder: (context, i) {
                  final c = _convs[i];
                  final username = (c['profiles']?['username'] ?? 'user')
                      .toString();
                  final unreadRaw = c['admin_unread_count'];
                  final unread = unreadRaw is num
                      ? unreadRaw.toInt()
                      : int.tryParse('$unreadRaw') ?? 0;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary50,
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary700),
                        ),
                      ),
                      title: Text(
                        '@$username',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        fmtDate(c['updated_at']),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: unread > 0
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.danger600,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : null,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _AdminChatThread(
                              convId: c['id'] as String,
                              username: username,
                            ),
                          ),
                        );
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

class _AdminChatThread extends StatefulWidget {
  final String convId;
  final String username;
  const _AdminChatThread({required this.convId, required this.username});

  @override
  State<_AdminChatThread> createState() => _AdminChatThreadState();
}

class _AdminChatThreadState extends State<_AdminChatThread> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    try {
      final rows = await auth.client
          .from('chat_messages')
          .select()
          .eq('conversation_id', widget.convId)
          .order('created_at', ascending: true);
      _messages = List<Map<String, dynamic>>.from(rows);
      // Mark user messages as read by admin.
      await auth.client
          .from('chat_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', widget.convId)
          .eq('is_admin_reply', false)
          .isFilter('read_at', null);
      await auth.client
          .from('chat_conversations')
          .update({'admin_unread_count': 0})
          .eq('id', widget.convId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    if (_input.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final auth = context.read<AuthService>();
    try {
      final row = await auth.client
          .from('chat_messages')
          .insert({
            'conversation_id': widget.convId,
            'sender_id': auth.profile!.id,
            'message': _input.text.trim(),
            'is_admin_reply': true,
          })
          .select()
          .single();
      _input.clear();
      if (mounted) setState(() => _messages = [..._messages, row]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthService>().profile?.id;
    return Scaffold(
      appBar: AppBar(title: Text('@${widget.username}')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final mine =
                          m['sender_id'] == myId || m['is_admin_reply'] == true;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: mine ? AppColors.primary600 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: Text(
                            m['message'] ?? '',
                            style: TextStyle(
                              color: mine ? Colors.white : AppColors.gray900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Reply...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
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
