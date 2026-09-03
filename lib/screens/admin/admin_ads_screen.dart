import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminAdsPage.tsx: create/edit/toggle/delete ad banners shown on
/// the platform (table: ad_banners).
class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({super.key});

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
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
          .from('ad_banners')
          .select()
          .order('created_at', ascending: false);
      _rows = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit([Map<String, dynamic>? banner]) async {
    final title = TextEditingController(text: banner?['title'] ?? '');
    final imageUrl =
        TextEditingController(text: banner?['image_url'] ?? '');
    final linkUrl = TextEditingController(text: banner?['link_url'] ?? '');
    final position = TextEditingController(
        text: banner?['position']?.toString() ?? 'dashboard');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(banner == null ? 'New Banner' : 'Edit Banner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                  controller: imageUrl,
                  decoration:
                      const InputDecoration(labelText: 'Image URL')),
              TextField(
                  controller: linkUrl,
                  decoration:
                      const InputDecoration(labelText: 'Link URL')),
              TextField(
                  controller: position,
                  decoration: const InputDecoration(
                      labelText: 'Position (dashboard/landing)')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final payload = {
      'title': title.text.trim(),
      'image_url': imageUrl.text.trim(),
      'link_url': linkUrl.text.trim(),
      'position': position.text.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    final client = context.read<AuthService>().client;
    try {
      if (banner != null) {
        await client.from('ad_banners').update(payload).eq('id', banner['id']);
      } else {
        await client.from('ad_banners').insert({...payload, 'is_active': true});
      }
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

  Future<void> _toggle(Map<String, dynamic> b) async {
    final client = context.read<AuthService>().client;
    try {
      await client
          .from('ad_banners')
          .update({'is_active': !(b['is_active'] == true)}).eq('id', b['id']);
      if (mounted) {
        setState(() => _loading = true);
        _load();
      }
    } catch (_) {}
  }

  Future<void> _delete(Map<String, dynamic> b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete banner?'),
        content: Text('Delete "${b['title'] ?? ''}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger600),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final client = context.read<AuthService>().client;
    try {
      await client.from('ad_banners').delete().eq('id', b['id']);
      if (mounted) {
        setState(() => _loading = true);
        _load();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ad Banners')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const EmptyState(
                  icon: Icons.campaign,
                  title: 'No banners',
                  subtitle: 'Create a banner to promote things in the app.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final b = _rows[i];
                      final active = b['is_active'] == true;
                      return Card(
                        child: ListTile(
                          leading: (b['image_url'] ?? '').toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    b['image_url'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.campaign),
                                  ),
                                )
                              : const Icon(Icons.campaign),
                          title: Text(b['title'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${b['position'] ?? 'dashboard'} • ${active ? 'Active' : 'Inactive'}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                  value: active,
                                  onChanged: (_) => _toggle(b)),
                              IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _edit(b)),
                              IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 20, color: AppColors.danger600),
                                  onPressed: () => _delete(b)),
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
