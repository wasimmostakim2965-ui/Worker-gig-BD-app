import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Proof-screenshot upload with the SAME fraud protection as the website:
///
/// The `job-assets` bucket doubles as a dedup registry. Before accepting a
/// screenshot we upload a 1-byte marker keyed by the file's SHA-256 at
/// `fraud-registry/proofs/{sha256}`. If Supabase returns "Duplicate" (409),
/// the exact same bytes were already submitted — by anyone — and we reject.
/// This is enforced server-side, so it cannot be bypassed from the client.
class ProofUpload {
  static const _bucket = 'job-assets';
  static final _marker = Uint8List.fromList([0x57]); // 'W'

  SupabaseClient get _db => Supabase.instance.client;

  /// Returns the public URL of the uploaded proof.
  /// Throws [ProofDuplicateException] if this exact image was used before.
  Future<String> uploadProof(XFile file, {required String jobId}) async {
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();

    // 1. Register in the fraud registry — duplicate = reject.
    try {
      await _db.storage.from(_bucket).uploadBinary(
            'fraud-registry/proofs/$hash',
            _marker,
            fileOptions: const FileOptions(
                contentType: 'application/octet-stream', upsert: false),
          );
    } on StorageException catch (e) {
      if (e.statusCode == '409' ||
          e.message.toLowerCase().contains('duplicate') ||
          (e.error ?? '').toLowerCase().contains('duplicate')) {
        throw ProofDuplicateException();
      }
      rethrow;
    }

    // 2. Upload the actual screenshot; the registry already guarantees it
    //    is unique, so upsert is fine.
    final ext = (file.name.split('.').last).toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
    final path = 'proofs/$jobId/$hash.$ext';
    await _db.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _db.storage.from(_bucket).getPublicUrl(path);
  }
}

class ProofDuplicateException implements Exception {
  @override
  String toString() =>
      'This screenshot has already been used as proof. Please take a fresh screenshot.';
}

/// Serialize screenshot URLs exactly like the website: a JSON array string
/// stored in tasks.proof_url (or null when there are no screenshots).
String? encodeProofUrls(List<String> urls) =>
    urls.isEmpty ? null : jsonEncode(urls);
