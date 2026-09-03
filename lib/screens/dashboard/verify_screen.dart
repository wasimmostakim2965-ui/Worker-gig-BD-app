import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors VerifyPage.tsx: uploads an ID document to the private
/// `verification-docs` bucket, creates a long-lived signed URL and inserts a
/// pending row into verification_requests (admin reviews it).
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _done = false;
  String? _existingStatus; // pending | approved | null
  Uint8List? _fileBytes;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final auth = context.read<AuthService>();
    try {
      final rows = await auth.client
          .from('verification_requests')
          .select('id, status')
          .eq('user_id', auth.profile!.id)
          .inFilter('status', ['pending', 'approved'])
          .limit(1);
      if (rows.isNotEmpty) _existingStatus = rows.first['status'] as String;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 2048, imageQuality: 90);
    if (picked == null) return;
    _fileBytes = await picked.readAsBytes();
    _fileName = picked.name;
    setState(() {});
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    if (_fileBytes == null || auth.profile == null) {
      setState(() => _error = 'Please choose a document image first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ext = (_fileName ?? 'doc.jpg').split('.').last;
      final path =
          '${auth.profile!.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await auth.client.storage.from('verification-docs').uploadBinary(
            path,
            _fileBytes!,
            fileOptions: const FileOptions(upsert: false),
          );
      // Same as the web: a 10-year signed URL stored on the request.
      final signed = await auth.client.storage
          .from('verification-docs')
          .createSignedUrl(path, 60 * 60 * 24 * 365 * 10);
      await auth.client.from('verification_requests').insert({
        'user_id': auth.profile!.id,
        'document_url': signed,
        'status': 'pending',
      });
      if (mounted) {
        setState(() {
          _done = true;
          _existingStatus = 'pending';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Account')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Identity Verification',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload a clear photo of your NID, passport or driving licence. '
                          'An admin will review it and add the verified badge to your account.',
                          style: TextStyle(
                              color: AppColors.gray600, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        if (_existingStatus == 'approved')
                          const StatusBadge('approved')
                        else if (_existingStatus == 'pending' || _done)
                          const Text(
                              'Your document is under review. You will get a notification once it is processed.',
                              style: TextStyle(
                                  color: AppColors.warning600, height: 1.5))
                        else ...[
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _pick,
                            icon: const Icon(Icons.upload_file),
                            label: Text(_fileBytes == null
                                ? 'Choose document image'
                                : (_fileName ?? 'Selected')),
                          ),
                          if (_fileBytes != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(_fileBytes!, height: 160),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.danger600, fontSize: 13)),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  _busy || _fileBytes == null ? null : _submit,
                              child:
                                  Text(_busy ? 'Uploading...' : 'Submit for Review'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
