import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/maypolechat/data/maypole_image_service.dart';
import 'package:maypole/features/maypolechat/domain/maypole_image.dart';
import '../maypole_chat_providers.dart';

/// View model for managing the maypole gallery with pagination
class MaypoleGalleryViewModel extends AsyncNotifier<List<MaypoleImage>> {
  MaypoleGalleryViewModel(this._maypoleId);

  final String _maypoleId;
  late final MaypoleImageService _imageService;
  StreamSubscription<List<MaypoleImage>>? _imagesSubscription;
  bool _isLoadingMore = false;
  bool _hasMoreImages = true;
  List<MaypoleImage> _allLoadedImages = [];

  @override
  Future<List<MaypoleImage>> build() async {
    _imageService = ref.read(maypoleImageServiceProvider);

    // Cancel subscription when the provider is disposed
    ref.onDispose(() {
      _imagesSubscription?.cancel();
    });

    // Try to load cached images first for instant display
    final cachedImages = await _imageService.getCachedImages(_maypoleId);
    if (cachedImages != null && cachedImages.isNotEmpty) {
      _allLoadedImages = cachedImages;
      _hasMoreImages = cachedImages.length >= 50;
      debugPrint('📦 Loaded ${cachedImages.length} cached images for gallery');
    }

    // Initialize stream for real-time updates
    _initStream();

    // Return cached images or empty list (stream will update with fresh data)
    return cachedImages ?? [];
  }

  /// Initialize stream for real-time image updates
  void _initStream() {
    _imagesSubscription?.cancel();
    
    // Set up the stream listener
    _imagesSubscription = _imageService.getImages(_maypoleId).listen(
      (images) {
        debugPrint('📸 Gallery stream received ${images.length} images');
        _allLoadedImages = images;
        _hasMoreImages = images.length >= 50; // If we got 50, there might be more
        state = AsyncValue.data(images);
      },
      onError: (error, stackTrace) {
        debugPrint('❌ Gallery stream error: $error');
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  /// Loads more images for pagination
  Future<void> loadMoreImages() async {
    if (_isLoadingMore || !_hasMoreImages || !state.hasValue) return;

    final currentImages = state.value!;
    if (currentImages.isEmpty) return;

    _isLoadingMore = true;
    try {
      final lastImage = currentImages.last;
      debugPrint('📸 Loading more images after: ${lastImage.uploadedAt}');

      final newImages = await _imageService.getMoreImages(_maypoleId, lastImage);

      if (newImages.isEmpty) {
        _hasMoreImages = false;
        debugPrint('📸 No more images to load');
      } else {
        // Merge new images with existing ones
        final allImages = [...currentImages, ...newImages];
        _allLoadedImages = allImages;
        state = AsyncValue.data(allImages);
        debugPrint('📸 Loaded ${newImages.length} more images (total: ${allImages.length})');
        
        // If we got fewer than 50, we've probably reached the end
        if (newImages.length < 50) {
          _hasMoreImages = false;
        }
      }
    } catch (e, st) {
      debugPrint('❌ Error loading more images: $e');
      // Don't update state on error, just log it
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Returns whether there are more images to load
  bool get hasMoreImages => _hasMoreImages;

  /// Returns whether we're currently loading more images
  bool get isLoadingMore => _isLoadingMore;
}
