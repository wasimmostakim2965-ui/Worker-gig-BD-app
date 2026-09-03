import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminSettingsPage.tsx: edit every admin_settings key/value
/// (payment numbers, withdrawal limits, toggles, premium price, etc).
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
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
          .from('admin_settings')
          .select()
          .order('key', ascending: true);
      _rows = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit(Map<String, dynamic> s) async {
    final ctrl = TextEditingController(
        text: (s['value'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['key'] ?? ''),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Value')),
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
    final client = context.read<AuthService>().client;
    try {
      await client.from('admin_settings').update({
        'value': ctrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', s['id']);
      setState(() => _loading = true);
      _load();
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
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const EmptyState(
                  icon: Icons.settings,
                  title: 'No settings',
                  subtitle: 'Admin settings will appear here.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final s = _rows[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.tune,
                              color: AppColors.primary600),
                          title: Text(_prettify(s['key'] ?? ''),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${s['key']}\n${(s['value'] ?? '').toString()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.edit, size: 18),
                          onTap: () => _edit(s),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  static String _prettify(String key) => key
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
