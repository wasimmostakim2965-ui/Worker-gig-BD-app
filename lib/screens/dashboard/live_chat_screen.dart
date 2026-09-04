import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors LiveChatPage.tsx: one conversation per user with the admin team,
/// powered by get_or_create_chat_conversation + chat_messages + realtime.
class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _convId;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _init() async {
    final auth = context.read<AuthService>();
    try {
      // Same RPC the web app calls (SECURITY DEFINER, uses auth.uid()).
      final convId =
          await auth.client.rpc('get_or_create_chat_conversation') as String;
      _convId = convId;
      final rows = await auth.client
          .from('chat_messages')
          .select()
          .eq('conversation_id', convId)
          .order('created_at', ascending: true);
      _messages = List<Map<String, dynamic>>.from(rows);
      // Mark admin messages as read by this user.
      await auth.client
          .from('chat_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', convId)
          .eq('is_admin_reply', true)
          .isFilter('read_at', null);
      await auth.client
          .from('chat_conversations')
          .update({'user_unread_count': 0})
          .eq('id', convId);

      _channel = auth.client
          .channel('chat-user-$convId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: convId,
            ),
            callback: (payload) async {
              final msg = payload.newRecord;
              if (mounted && !_messages.any((m) => m['id'] == msg['id'])) {
                setState(() => _messages = [..._messages, msg]);
                _jumpToBottom();
              }
              if (msg['is_admin_reply'] == true && msg['read_at'] == null) {
                try {
                  await auth.client
                      .from('chat_messages')
                      .update({'read_at': DateTime.now().toIso8601String()})
                      .eq('id', msg['id']);
                  await auth.client
                      .from('chat_conversations')
                      .update({'user_unread_count': 0})
                      .eq('id', convId);
                } catch (e) {
                  debugPrint('Chat read-mark error: $e');
                }
              }
            },
          )
          .subscribe();
    } catch (e) {
      _error = 'Could not load the chat. Please try again.';
    }
    if (mounted) {
      setState(() => _loading = false);
      _jumpToBottom();
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    if (_input.text.trim().isEmpty || _convId == null) return;
    final auth = context.read<AuthService>();
    final senderId = auth.profile?.id;
    if (senderId == null) return;
    setState(() => _busy = true);
    try {
      final row = await auth.client
          .from('chat_messages')
          .insert({
            'conversation_id': _convId,
            'sender_id': senderId,
            'message': _input.text.trim(),
            'is_admin_reply': false,
          })
          .select()
          .single();
      _input.clear();
      if (mounted && !_messages.any((m) => m['id'] == row['id'])) {
        setState(() => _messages = [..._messages, row]);
        _jumpToBottom();
      }
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
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live Chat', style: TextStyle(fontSize: 16)),
            Text(
              'Talk to support in real time',
              style: TextStyle(fontSize: 11, color: AppColors.primary100),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.danger600),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const EmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'No messages yet',
                          subtitle: 'Say hello — support replies here.',
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final m = _messages[i];
                            final mine =
                                m['sender_id'] == myId &&
                                m['is_admin_reply'] != true;
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
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? AppColors.primary600
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gray200),
                                ),
                                child: Text(
                                  m['message'] ?? '',
                                  style: TextStyle(
                                    color: mine
                                        ? Colors.white
                                        : AppColors.gray900,
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
                              hintText: 'Type a message...',
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
