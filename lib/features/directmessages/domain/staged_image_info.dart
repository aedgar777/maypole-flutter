import 'package:flutter/foundation.dart';

/// Holds information about a staged image for upload
/// Works on both mobile and web
class StagedImageInfo {
  final String path; // File path or blob URL
  final String? mimeType; // MIME type for web (e.g., 'image/png')

  const StagedImageInfo({
    required this.path,
    this.mimeType,
  });

  String get extension {
    if (mimeType != null && mimeType!.isNotEmpty) {
      final ext = mimeType!.split('/').last.toLowerCase();
      return ext == 'jpeg' ? 'jpg' : ext;
    }
    // Fallback to path extension
    return path.split('.').last.toLowerCase();
  }
}
