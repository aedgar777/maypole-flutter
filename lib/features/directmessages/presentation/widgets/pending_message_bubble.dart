import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../domain/pending_message.dart';
import '../../domain/staged_image_info.dart';

/// Widget for displaying a pending/uploading message with image upload states.
///
/// This widget shows a message bubble while images are being uploaded,
/// displaying upload progress, success states, and retry options for failed uploads.
///
/// Example usage:
/// ```dart
/// PendingMessageBubble(
///   pendingMessage: pendingMsg,
///   isOwnMessage: true,
///   onRetry: (imageIndex) => retryUpload(imageIndex),
/// )
/// ```
class PendingMessageBubble extends StatelessWidget {
  final PendingMessage pendingMessage;
  final bool isOwnMessage;
  final Function(int imageIndex) onRetry;

  const PendingMessageBubble({
    super.key,
    required this.pendingMessage,
    required this.isOwnMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const double standardRadius = 18.0;

    final borderRadius = BorderRadius.circular(standardRadius);
    final hasImages = pendingMessage.pendingImages.isNotEmpty;
    final hasText = pendingMessage.message.body.isNotEmpty;

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: hasImages && hasText
            ? _buildImageWithTextBubble(context, borderRadius)
            : Container(
                decoration: BoxDecoration(
                  color: hasImages && !hasText
                      ? Colors.transparent
                      : (isOwnMessage ? Colors.blue[200] : Colors.grey[300]),
                  borderRadius: borderRadius,
                ),
                padding: hasImages && !hasText
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Display uploading images (image-only)
                    if (hasImages && !hasText) _buildUploadingImages(context, borderRadius),
                    // Display text (text-only)
                    if (hasText && !hasImages)
                      Text(
                        pendingMessage.message.body,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Build Signal-style bubble with images flush to edges and text below
  Widget _buildImageWithTextBubble(BuildContext context, BorderRadius borderRadius) {
    // Image area has top corners rounded
    final imageRadius = BorderRadius.only(
      topLeft: const Radius.circular(18.0),
      topRight: const Radius.circular(18.0),
    );

    // Text area has bottom corners rounded
    final textRadius = BorderRadius.only(
      bottomLeft: const Radius.circular(18.0),
      bottomRight: const Radius.circular(18.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Images flush to edges with top rounded corners
        ClipRRect(
          borderRadius: imageRadius,
          child: _buildUploadingImages(context, BorderRadius.zero),
        ),
        // Text area with bubble color and bottom rounded corners
        Container(
          decoration: BoxDecoration(
            color: isOwnMessage ? Colors.blue[200] : Colors.grey[300],
            borderRadius: textRadius,
          ),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          width: double.infinity,
          child: Text(
            pendingMessage.message.body,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingImages(BuildContext context, BorderRadius borderRadius) {
    if (pendingMessage.pendingImages.length == 1) {
      return _buildSingleUploadingImage(context, 0, borderRadius);
    }

    // Multiple images - show in grid
    return Column(
      children: List.generate(
        (pendingMessage.pendingImages.length / 2).ceil(),
        (rowIndex) {
          final startIndex = rowIndex * 2;
          final endIndex = (startIndex + 2).clamp(0, pendingMessage.pendingImages.length);

          return Row(
            children: List.generate(
              endIndex - startIndex,
              (colIndex) {
                final imageIndex = startIndex + colIndex;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(1),
                    child: _buildUploadingImageTile(context, imageIndex),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleUploadingImage(BuildContext context, int index, BorderRadius borderRadius) {
    final pendingImage = pendingMessage.pendingImages[index];

    // Use provided borderRadius if not zero, otherwise use 8px for internal rounding
    final effectiveRadius = borderRadius == BorderRadius.zero
        ? BorderRadius.zero
        : (pendingMessage.message.body.isEmpty ? borderRadius : BorderRadius.circular(8));

    final imageWidget = ClipRRect(
      borderRadius: effectiveRadius,
      child: Stack(
        children: [
          // Show uploaded URL if available, otherwise local file
          if (pendingImage.uploadedUrl != null && pendingImage.status == ImageUploadStatus.uploaded)
            CachedNetworkImage(
              imageUrl: pendingImage.uploadedUrl!,
              height: 250,
              width: kIsWeb ? 250 : double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 250,
                width: kIsWeb ? 250 : double.infinity,
                color: Colors.grey[300],
              ),
              errorWidget: (context, url, error) => Image.file(
                File(pendingImage.localPath),
                height: 250,
                width: kIsWeb ? 250 : double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Image.file(
              File(pendingImage.localPath),
              height: 250,
              width: kIsWeb ? 250 : double.infinity,
              fit: BoxFit.cover,
            ),
          // Overlay for uploading/failed states
          if (pendingImage.status != ImageUploadStatus.uploaded)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: pendingImage.status == ImageUploadStatus.uploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 40),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Upload failed, tap to retry',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: pendingImage.status == ImageUploadStatus.failed
          ? () => onRetry(index)
          : null,
      child: kIsWeb
          ? Align(
              alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
              child: imageWidget,
            )
          : imageWidget,
    );
  }

  Widget _buildUploadingImageTile(BuildContext context, int index) {
    final pendingImage = pendingMessage.pendingImages[index];

    return GestureDetector(
      onTap: pendingImage.status == ImageUploadStatus.failed
          ? () => onRetry(index)
          : null,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Show uploaded URL if available, otherwise local file
              if (pendingImage.uploadedUrl != null && pendingImage.status == ImageUploadStatus.uploaded)
                CachedNetworkImage(
                  imageUrl: pendingImage.uploadedUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Image.file(
                    File(pendingImage.localPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              else
                Image.file(
                  File(pendingImage.localPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              // Overlay for uploading/failed states
              if (pendingImage.status != ImageUploadStatus.uploaded)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: pendingImage.status == ImageUploadStatus.uploading
                          ? const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline, color: Colors.white, size: 30),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to retry',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
