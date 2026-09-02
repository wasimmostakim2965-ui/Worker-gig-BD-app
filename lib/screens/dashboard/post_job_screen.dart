import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors PostJobPage: creates a job via the post_job RPC which handles
/// the deposit-balance charge atomically on the server.
class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  final _requirements = TextEditingController();
  final _reward = TextEditingController();
  final _slots = TextEditingController();

  List<Category> _categories = [];
  Category? _category;
  String? _subcategory;
  int _screenshotCount = 0;
  bool _premiumOnly = false;
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final rows = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order');
      if (mounted) {
        setState(() =>
            _categories = rows.map(Category.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Load categories error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _totalCost =>
      (double.tryParse(_reward.text) ?? 0) * (int.tryParse(_slots.text) ?? 0);

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _error = 'Please select a category.');
      return;
    }
    final profile = context.read<AuthService>().profile;
    if (profile == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.rpc('post_job', params: {
        'p_uid': profile.id,
        'p_title': _title.text.trim(),
        'p_description': _description.text.trim(),
        'p_category': _category!.name,
        'p_subcategory': _subcategory ?? '',
        'p_url': _url.text.trim(),
        'p_proof_instructions': _requirements.text.trim(),
        'p_reward_per_worker': double.parse(_reward.text),
        'p_total_slots': int.parse(_slots.text),
        'p_is_premium_only': _premiumOnly,
        'p_screenshot_count': _screenshotCount,
        'p_screenshot_instructions': '',
        'p_image_url': '',
      });
      if (mounted) {
        showSnack(context, 'Job posted successfully!');
        context.read<AuthService>().refreshProfile();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = '$e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: _loading
          ? const LoadingView()
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Job Title'),
                    validator: (v) =>
                        (v == null || v.trim().length < 5)
                            ? 'At least 5 characters'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Category>(
                    initialValue: _category,
                    decoration:
                        const InputDecoration(labelText: 'Category'),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => setState(() {
                      _category = c;
                      _subcategory = null;
                    }),
                  ),
                  if ((_category?.subcategories.isNotEmpty) ?? false) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _subcategory,
                      decoration: const InputDecoration(
                          labelText: 'Subcategory (optional)'),
                      items: _category!.subcategories
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (s) => setState(() => _subcategory = s),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Explain what workers need to do...'),
                    validator: (v) => (v == null || v.trim().length < 10)
                        ? 'At least 10 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                        labelText: 'Task URL (optional)',
                        hintText: 'https://...'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _requirements,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Proof Instructions',
                        hintText:
                            'What proof must workers submit?'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _reward,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Reward per worker (\$)'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) =>
                              (double.tryParse(v ?? '') ?? 0) <= 0
                                  ? 'Invalid'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _slots,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Total workers'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) =>
                              (int.tryParse(v ?? '') ?? 0) <= 0
                                  ? 'Invalid'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _screenshotCount,
                    decoration: const InputDecoration(
                        labelText: 'Required screenshots'),
                    items: const [0, 1, 2, 3]
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (n) =>
                        setState(() => _screenshotCount = n ?? 0),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Premium members only',
                        style: TextStyle(fontSize: 14)),
                    value: _premiumOnly,
                    onChanged: (v) => setState(() => _premiumOnly = v),
                  ),
                  if (_totalCost > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total cost (from deposit balance)',
                              style: TextStyle(fontSize: 13)),
                          Text(fmtMoney(_totalCost),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary700)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_error != null) ...[
                    ErrorBox(_error!),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Post Job'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
