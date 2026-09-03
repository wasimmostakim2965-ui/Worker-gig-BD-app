import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminCategoriesPage.tsx: add/edit/toggle/delete job categories.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
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
          .from('categories')
          .select()
          .order('display_order', ascending: true);
      _rows = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit([Map<String, dynamic>? cat]) async {
    final name = TextEditingController(text: cat?['name'] ?? '');
    final order = TextEditingController(
        text: cat?['display_order']?.toString() ??
            (_rows.length + 1).toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cat == null ? 'New Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(
                controller: order,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Display order')),
          ],
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
    if (ok != true || name.text.trim().isEmpty || !mounted) return;

    final client = context.read<AuthService>().client;
    final payload = {
      'name': name.text.trim(),
      'display_order': int.tryParse(order.text.trim()) ?? 0,
    };
    try {
      if (cat != null) {
        await client.from('categories').update(payload).eq('id', cat['id']);
      } else {
        await client
            .from('categories')
            .insert({...payload, 'is_active': true});
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

  Future<void> _toggle(Map<String, dynamic> cat) async {
    final client = context.read<AuthService>().client;
    try {
      await client
          .from('categories')
          .update({'is_active': !(cat['is_active'] == true)})
          .eq('id', cat['id']);
      if (mounted) {
        setState(() => _loading = true);
        _load();
      }
    } catch (_) {}
  }

  Future<void> _delete(Map<String, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete "${cat['name']}"? Jobs using it keep their text.'),
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
      await client.from('categories').delete().eq('id', cat['id']);
      if (mounted) {
        setState(() => _loading = true);
        _load();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: _edit,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'No categories',
                  subtitle: 'Add categories workers can filter by.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final c = _rows[i];
                      final active = c['is_active'] == true;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.label_outline,
                              color: AppColors.primary600),
                          title: Text(c['name'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              'Order: ${c['display_order'] ?? 0} • ${active ? 'Active' : 'Hidden'}',
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                  value: active,
                                  onChanged: (_) => _toggle(c)),
                              IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _edit(c)),
                              IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 20,
                                      color: AppColors.danger600),
                                  onPressed: () => _delete(c)),
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
