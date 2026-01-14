import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:maypole/core/app_config.dart';
import 'package:maypole/core/app_session.dart';
import 'package:maypole/core/utils/date_time_utils.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/maypolechat/domain/maypole_image.dart';
import 'package:maypole/features/maypolechat/presentation/maypole_chat_providers.dart';

/// Custom cache manager for maypole images with longer cache duration
class MaypoleImageCacheManager {
  static const key = 'maypoleImageCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Keep images for 30 days
      maxNrOfCacheObjects: 500, // Cache up to 500 images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}

/// Screen displaying a grid of images from a maypole chat room
class MaypoleGalleryScreen extends ConsumerStatefulWidget {
  final String threadId;
  final String maypoleName;
  final String? initialImageId; // If provided, opens this image immediately

  const MaypoleGalleryScreen({
    super.key,
    required this.threadId,
    required this.maypoleName,
    this.initialImageId,
  });

  @override
  ConsumerState<MaypoleGalleryScreen> createState() => _MaypoleGalleryScreenState();
}

class _MaypoleGalleryScreenState extends ConsumerState<MaypoleGalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasOpenedInitialImage = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger load more when user scrolls near the bottom (80% threshold)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreImages();
    }
  }

  Future<void> _loadMoreImages() async {
    await ref.read(maypoleGalleryViewModelProvider(widget.threadId).notifier).loadMoreImages();
  }

  void _showImageFullscreen(MaypoleImage image, List<MaypoleImage> allImages) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageFullscreenView(
          image: image,
          allImages: allImages,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagesAsyncValue = ref.watch(maypoleGalleryViewModelProvider(widget.threadId));
    final viewModel = ref.read(maypoleGalleryViewModelProvider(widget.threadId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.maypoleName} Gallery'),
        automaticallyImplyLeading: !AppConfig.isWideScreen,
      ),
      body: imagesAsyncValue.when(
        data: (images) {
          if (images.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.white38),
                  SizedBox(height: 16),
                  Text(
                    'No images yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the image icon to add photos',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Auto-open the initial image if specified
          if (widget.initialImageId != null && !_hasOpenedInitialImage) {
            _hasOpenedInitialImage = true;
            final initialImage = images.firstWhere(
              (img) => img.id == widget.initialImageId,
              orElse: () => images.first,
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showImageFullscreen(initialImage, images);
            });
          }

          final isLoadingMore = viewModel.isLoadingMore;
          final hasMore = viewModel.hasMoreImages;

          return GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: images.length + (isLoadingMore || hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == images.length) {
                if (isLoadingMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                // Empty placeholder for scroll detection
                return const SizedBox.shrink();
              }

              final image = images[index];
              return _ImageThumbnail(
                image: image,
                onTap: () => _showImageFullscreen(image, images),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorDialog.show(context, error);
          });
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

/// Widget for displaying an image thumbnail with timestamp overlay
class _ImageThumbnail extends StatelessWidget {
  final MaypoleImage image;
  final VoidCallback onTap;

  const _ImageThumbnail({
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateTimeUtils.formatShortRelative(
      image.uploadedAt,
      context: context,
    );

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4), // Optional: adds slight rounding
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with custom cache manager
            CachedNetworkImage(
              imageUrl: image.storageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center, // Ensure center cropping
              cacheManager: MaypoleImageCacheManager.instance,
              memCacheWidth: 400, // Resize in memory for thumbnails
              memCacheHeight: 400,
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 100),
              placeholder: (context, url) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                debugPrint('❌ Thumbnail load error: $error for URL: $url');
                return Container(
                  color: Colors.grey[900],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.white38, size: 32),
                      const SizedBox(height: 4),
                      Text(
                        'Load error',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Timestamp overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full screen view for viewing images with swipe navigation
class _ImageFullscreenView extends StatefulWidget {
  final MaypoleImage image;
  final List<MaypoleImage> allImages;

  const _ImageFullscreenView({
    required this.image,
    required this.allImages,
  });

  @override
  State<_ImageFullscreenView> createState() => _ImageFullscreenViewState();
}

class _ImageFullscreenViewState extends State<_ImageFullscreenView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allImages.indexOf(widget.image);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.allImages[_currentIndex];
    final currentUser = AppSession().currentUser;
    final canDelete = currentUser != null && currentImage.uploaderId == currentUser.firebaseID;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !AppConfig.isWideScreen,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currentImage.uploaderName),
            Text(
              DateTimeUtils.formatFullDateTime(currentImage.uploadedAt),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(currentImage),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.allImages.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final image = widget.allImages[index];
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: image.storageUrl,
                fit: BoxFit.contain,
                cacheManager: MaypoleImageCacheManager.instance,
                // No resize for full-screen view - use original quality
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white38, size: 64),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.allImages.length > 1
          ? Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black87,
              child: Text(
                '${_currentIndex + 1} / ${widget.allImages.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : null,
    );
  }

  Future<void> _showDeleteConfirmation(MaypoleImage image) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // TODO: Implement delete functionality with provider
      // For now, just close the view
      Navigator.pop(context);
    }
  }
}
