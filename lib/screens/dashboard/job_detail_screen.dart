import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../services/proof_upload.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors the website's inline job-detail view: instructions, proof upload,
/// submit. The server-side require_task_proof trigger and the fraud registry
/// enforce the same rules as on the web.
class JobDetailScreen extends StatefulWidget {
  final Job job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _proofCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _uploader = ProofUpload();

  List<String> _screenshots = [];
  bool _submitting = false;
  bool _uploading = false;
  bool _success = false;
  String? _error;

  Job get job => widget.job;

  @override
  void initState() {
    super.initState();
    _screenshots = List.filled(job.screenshotCount, '');
  }

  Future<void> _addScreenshot(int slot) async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await _uploader.uploadProof(file, jobId: job.id);
      setState(() => _screenshots[slot] = url);
    } on ProofDuplicateException catch (e) {
      setState(() => _error = e.toString());
    } catch (e) {
      setState(() => _error = 'Screenshot upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    final profile = context.read<AuthService>().profile;
    if (profile == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    String fail(String msg) {
      setState(() {
        _error = msg;
        _submitting = false;
      });
      return msg;
    }

    if (profile.status != 'active') {
      fail('Your account is not active. You cannot accept jobs.');
      return;
    }
    if (job.isPremiumOnly && !profile.premiumActive) {
      fail('This job is only available for active premium members.');
      return;
    }
    final filled = _screenshots.where((s) => s.isNotEmpty).toList();
    if (job.screenshotCount > 0 && filled.length < job.screenshotCount) {
      fail('Please upload all ${job.screenshotCount} required screenshot(s). '
          'You have uploaded ${filled.length}.');
      return;
    }
    if (filled.isEmpty && _proofCtrl.text.trim().isEmpty) {
      fail('Please describe your work in the proof box before submitting.');
      return;
    }

    final db = Supabase.instance.client;
    try {
      final existing = await db
          .from('tasks')
          .select('id')
          .eq('job_id', job.id)
          .eq('worker_id', profile.id)
          .maybeSingle();
      if (existing != null) {
        fail('You have already worked on this job.');
        return;
      }
      await db.from('tasks').insert({
        'job_id': job.id,
        'worker_id': profile.id,
        'proof_url': encodeProofUrls(filled),
        'proof_text':
            _proofCtrl.text.trim().isEmpty ? null : _proofCtrl.text.trim(),
        'status': 'submitted',
        'submitted_at': DateTime.now().toIso8601String(),
      });
      setState(() => _success = true);
      if (mounted) context.read<AuthService>().refreshProfile();
    } catch (e) {
      fail('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.success50,
                  child: Icon(Icons.star, color: AppColors.success600, size: 32),
                ),
                const SizedBox(height: 16),
                Text('Your task is submitted',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text('Your task has been submitted for review.',
                    style: TextStyle(color: AppColors.gray600)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to jobs'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(job.title,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (job.rewardPerWorker >= 0.1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8F7DC),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('TOP JOB',
                              style: TextStyle(
                                  color: AppColors.earnGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(fmtMoney(job.rewardPerWorker),
                          style: const TextStyle(
                              color: AppColors.earnGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      const SizedBox(width: 16),
                      Text(
                          'Slots: ${job.filledSlots}/${job.totalSlots}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray500)),
                      const Spacer(),
                      Text(job.category,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('What to do',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(job.description,
                      style: const TextStyle(
                          color: AppColors.gray600, height: 1.5)),
                  if (job.proofInstructions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('Proof requirements',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(job.proofInstructions,
                        style: const TextStyle(
                            color: AppColors.gray600, height: 1.5)),
                  ],
                  if (job.url.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(job.url),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open Task Link'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.screenshotCount > 0
                        ? 'Submit Proof (${job.screenshotCount} screenshot${job.screenshotCount > 1 ? 's' : ''} required)'
                        : 'Submit Proof',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (job.screenshotCount > 0)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < job.screenshotCount; i++)
                          _ShotSlot(
                            url: _screenshots[i],
                            uploading: _uploading,
                            onTap: () => _addScreenshot(i),
                            onRemove: _screenshots[i].isEmpty
                                ? null
                                : () => setState(() => _screenshots[i] = ''),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _proofCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Describe what you did (username, link, details)...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null) ...[
            ErrorBox(_error!),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: _submitting || _uploading ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Submit Task — ${fmtMoney(job.rewardPerWorker)}'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ShotSlot extends StatelessWidget {
  final String url;
  final bool uploading;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ShotSlot({
    required this.url,
    required this.uploading,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: uploading ? null : onTap,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray200),
              image: url.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(url), fit: BoxFit.cover)
                  : null,
            ),
            child: url.isEmpty
                ? const Icon(Icons.add_a_photo_outlined,
                    color: AppColors.gray500)
                : null,
          ),
        ),
        if (url.isNotEmpty && onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.error600,
                child: Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
