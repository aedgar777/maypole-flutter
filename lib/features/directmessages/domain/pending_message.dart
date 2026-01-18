import 'package:flutter/foundation.dart';
import 'direct_message.dart';

/// Represents a message that is being sent or has upload states
@immutable
class PendingMessage {
  final String tempId; // Temporary ID for pending messages
  final DirectMessage message;
  final List<PendingImage> pendingImages;
  final MessageStatus status;
  final String? errorMessage;

  const PendingMessage({
    required this.tempId,
    required this.message,
    this.pendingImages = const [],
    this.status = MessageStatus.sending,
    this.errorMessage,
  });

  PendingMessage copyWith({
    String? tempId,
    DirectMessage? message,
    List<PendingImage>? pendingImages,
    MessageStatus? status,
    String? errorMessage,
  }) {
    return PendingMessage(
      tempId: tempId ?? this.tempId,
      message: message ?? this.message,
      pendingImages: pendingImages ?? this.pendingImages,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Represents an image that is being uploaded
@immutable
class PendingImage {
  final String localPath; // Local file path
  final String? uploadedUrl; // URL after upload completes
  final ImageUploadStatus status;
  final String? errorMessage;

  const PendingImage({
    required this.localPath,
    this.uploadedUrl,
    this.status = ImageUploadStatus.uploading,
    this.errorMessage,
  });

  PendingImage copyWith({
    String? localPath,
    String? uploadedUrl,
    ImageUploadStatus? status,
    String? errorMessage,
  }) {
    return PendingImage(
      localPath: localPath ?? this.localPath,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum MessageStatus {
  sending,
  sent,
  failed,
}

enum ImageUploadStatus {
  uploading,
  uploaded,
  failed,
}
