import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../domain/staged_image_info.dart';

/// Widget for displaying staged images before sending in a DM
/// Allows users to preview and remove images with an X button
class StagedImagesWidget extends StatelessWidget {
  final List<StagedImageInfo> images;
  final Function(int) onRemoveImage;

  const StagedImagesWidget({
    super.key,
    required this.images,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _StagedImageItem(
            imageInfo: images[index],
            onRemove: () => onRemoveImage(index),
          );
        },
      ),
    );
  }
}

/// Individual staged image item with remove button
class _StagedImageItem extends StatelessWidget {
  final StagedImageInfo imageInfo;
  final VoidCallback onRemove;

  const _StagedImageItem({
    required this.imageInfo,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    imageInfo.path,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(imageInfo.path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
          ),
          // Remove button (X)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
