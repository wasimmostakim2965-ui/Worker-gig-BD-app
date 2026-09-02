import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors NotificationsPage.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

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
      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', profile.id)
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(
            () => _items = rows.map(AppNotification.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Notifications load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    final profile = context.read<AuthService>().profile;
    if (profile == null) return;
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', profile.id)
        .eq('is_read', false);
    _load();
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client
        .from('notifications')
        .delete()
        .eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(
                onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingView()
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyView(Icons.notifications_none,
                          'No notifications yet'),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      final (icon, color) = switch (n.type) {
                        'success' => (Icons.check_circle, AppColors.success600),
                        'warning' =>
                          (Icons.warning_amber, AppColors.warning600),
                        'error' => (Icons.error, AppColors.error600),
                        _ => (Icons.info, AppColors.primary600),
                      };
                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete,
                              color: AppColors.error600),
                        ),
                        onDismissed: (_) => _delete(n.id),
                        child: Card(
                          color: n.isRead ? Colors.white : AppColors.primary50,
                          child: ListTile(
                            leading: Icon(icon, color: color),
                            title: Text(n.title,
                                style: TextStyle(
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.message,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('d MMM yyyy, h:mm a').format(
                                      DateTime.tryParse(n.createdAt) ??
                                          DateTime.now()),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.gray500),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
