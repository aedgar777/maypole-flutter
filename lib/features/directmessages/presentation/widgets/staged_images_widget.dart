import 'dart:io';
import 'package:flutter/material.dart';

/// Widget for displaying staged images before sending in a DM
/// Allows users to preview and remove images with an X button
class StagedImagesWidget extends StatelessWidget {
  final List<String> imagePaths;
  final Function(int) onRemoveImage;

  const StagedImagesWidget({
    super.key,
    required this.imagePaths,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return _StagedImageItem(
            imagePath: imagePaths[index],
            onRemove: () => onRemoveImage(index),
          );
        },
      ),
    );
  }
}

/// Individual staged image item with remove button
class _StagedImageItem extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const _StagedImageItem({
    required this.imagePath,
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
            child: Image.file(
              File(imagePath),
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
