import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/directmessages/data/dm_thread_service.dart';
import 'package:maypole/features/directmessages/domain/direct_message.dart';

/// A widget that displays a DM message bubble with context menu support
class DmMessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isOwnMessage;
  final String partnerId;
  final String partnerUsername;
  final String partnerProfilePicUrl;
  final VoidCallback? onDelete;
  final bool isGroupedWithNext;
  final bool isGroupedWithPrevious;
  final bool isDeleted;

  const DmMessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.partnerId,
    required this.partnerUsername,
    required this.partnerProfilePicUrl,
    this.onDelete,
    this.isGroupedWithNext = false,
    this.isGroupedWithPrevious = false,
    this.isDeleted = false,
  });

  @override
  Widget build(BuildContext context) {
    // Define corner radius values
    const double standardRadius = 18.0;
    const double sharpRadius = 4.0;

    // Determine which corners should be sharp based on grouping
    BorderRadius borderRadius;
    if (isOwnMessage) {
      // Own messages aligned to right
      borderRadius = BorderRadius.only(
        topLeft: const Radius.circular(standardRadius),
        topRight: Radius.circular(isGroupedWithPrevious ? sharpRadius : standardRadius),
        bottomLeft: const Radius.circular(standardRadius),
        bottomRight: Radius.circular(isGroupedWithNext ? sharpRadius : standardRadius),
      );
    } else {
      // Other's messages aligned to left
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(isGroupedWithPrevious ? sharpRadius : standardRadius),
        topRight: const Radius.circular(standardRadius),
        bottomLeft: Radius.circular(isGroupedWithNext ? sharpRadius : standardRadius),
        bottomRight: const Radius.circular(standardRadius),
      );
    }

    // Dynamic vertical margin based on grouping
    // Grouped messages: 1px apart, Non-grouped messages: 4px apart
    final double topMargin = isGroupedWithPrevious ? 1.0 : 4.0;
    final double bottomMargin = isGroupedWithNext ? 1.0 : 4.0;

    final bool hasImages = message.imageUrls.isNotEmpty;
    final bool hasText = message.body.isNotEmpty && !isDeleted;

    return GestureDetector(
      onLongPress: !isDeleted ? () {
        HapticFeedback.mediumImpact();
        onDelete?.call();
      } : null,
      child: Align(
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.fromLTRB(8, topMargin, 8, bottomMargin),
          child: hasImages && hasText
              ? _buildImageWithTextBubble(context, borderRadius)
              : Container(
                  decoration: BoxDecoration(
                    color: isDeleted 
                        ? Colors.transparent
                        : (hasImages && !hasText 
                            ? Colors.transparent 
                            : (isOwnMessage ? Colors.blue[200] : Colors.grey[300])),
                    border: isDeleted 
                        ? Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                    borderRadius: borderRadius,
                  ),
                  padding: hasImages && !hasText 
                      ? EdgeInsets.zero 
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display images if present (image-only messages)
                      if (hasImages && !hasText) _buildImageGallery(context, borderRadius),
                      // Display text if present (text-only messages)
                      if (hasText && !hasImages)
                        Text(
                          message.body,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                          ),
                        ),
                      if (isDeleted)
                        Text(
                          'message deleted',
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.6),
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Build a Signal-style bubble with images flush to edges and text below
  Widget _buildImageWithTextBubble(BuildContext context, BorderRadius borderRadius) {
    // Create separate radius for image (top corners only) and text area (bottom corners only)
    final imageRadius = isOwnMessage
        ? BorderRadius.only(
            topLeft: const Radius.circular(18.0),
            topRight: Radius.circular(isGroupedWithPrevious ? 4.0 : 18.0),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(isGroupedWithPrevious ? 4.0 : 18.0),
            topRight: const Radius.circular(18.0),
          );
    
    final textRadius = isOwnMessage
        ? BorderRadius.only(
            bottomLeft: const Radius.circular(18.0),
            bottomRight: Radius.circular(isGroupedWithNext ? 4.0 : 18.0),
          )
        : BorderRadius.only(
            bottomLeft: Radius.circular(isGroupedWithNext ? 4.0 : 18.0),
            bottomRight: const Radius.circular(18.0),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Images with rounded corners on top only, flush to edges
        ClipRRect(
          borderRadius: imageRadius,
          child: _buildImageGallery(context, BorderRadius.zero), // Pass zero since we're clipping above
        ),
        // Text area with bubble color and rounded corners on bottom only
        Container(
          decoration: BoxDecoration(
            color: isOwnMessage ? Colors.blue[200] : Colors.grey[300],
            borderRadius: textRadius,
          ),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          width: double.infinity,
          child: Text(
            message.body,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(BuildContext context, BorderRadius borderRadius) {
    final imageCount = message.imageUrls.length;
    
    if (imageCount == 1) {
      return _buildSingleImage(context, message.imageUrls[0], borderRadius);
    } else if (imageCount == 2) {
      return _buildTwoImages(context, borderRadius);
    } else if (imageCount == 3) {
      return _buildThreeImages(context, borderRadius);
    } else if (imageCount == 4) {
      return _buildFourImages(context, borderRadius);
    } else {
      return _buildFiveImages(context, borderRadius);
    }
  }

  Widget _buildSingleImage(BuildContext context, String imageUrl, BorderRadius borderRadius) {
    // Use provided borderRadius if not zero, otherwise use 8px for internal rounding (except when flush)
    final effectiveRadius = borderRadius == BorderRadius.zero 
        ? BorderRadius.zero 
        : (message.body.isEmpty ? borderRadius : BorderRadius.circular(8));
    
    final imageWidget = ClipRRect(
      borderRadius: effectiveRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 250,
        width: kIsWeb ? 250 : double.infinity, // Keep square on web
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 250,
          width: kIsWeb ? 250 : null,
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 250,
          width: kIsWeb ? 250 : null,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );

    return GestureDetector(
      onTap: () => _showFullscreenImage(context, 0),
      child: kIsWeb 
          ? Align(
              alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
              child: imageWidget,
            )
          : imageWidget,
    );
  }

  Widget _buildTwoImages(BuildContext context, BorderRadius borderRadius) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showFullscreenImage(context, 0),
            child: _buildImageTile(message.imageUrls[0], height: 150),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: GestureDetector(
            onTap: () => _showFullscreenImage(context, 1),
            child: _buildImageTile(message.imageUrls[1], height: 150),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeImages(BuildContext context, BorderRadius borderRadius) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showFullscreenImage(context, 0),
          child: _buildImageTile(message.imageUrls[0], height: 150, width: double.infinity),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 1),
                child: _buildImageTile(message.imageUrls[1], height: 100),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 2),
                child: _buildImageTile(message.imageUrls[2], height: 100),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFourImages(BuildContext context, BorderRadius borderRadius) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 0),
                child: _buildImageTile(message.imageUrls[0], height: 125),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 1),
                child: _buildImageTile(message.imageUrls[1], height: 125),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 2),
                child: _buildImageTile(message.imageUrls[2], height: 125),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 3),
                child: _buildImageTile(message.imageUrls[3], height: 125),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiveImages(BuildContext context, BorderRadius borderRadius) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 0),
                child: _buildImageTile(message.imageUrls[0], height: 125),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 1),
                child: _buildImageTile(message.imageUrls[1], height: 125),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 2),
                child: _buildImageTile(message.imageUrls[2], height: 125),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 3),
                child: _buildImageTile(message.imageUrls[3], height: 125),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _showFullscreenImage(context, 4),
                child: _buildImageTile(message.imageUrls[4], height: 125),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageTile(String imageUrl, {double? height, double? width}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: height,
          width: width,
          color: Colors.grey[300],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: height,
          width: width,
          color: Colors.grey[300],
          child: const Icon(Icons.error, size: 20),
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullscreenImageViewer(
          imageUrls: message.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Fullscreen image viewer with swipe navigation
class _FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullscreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} of ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 50),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
