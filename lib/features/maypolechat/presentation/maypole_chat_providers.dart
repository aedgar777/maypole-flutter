import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/features/maypolechat/domain/maypole_image.dart';
import 'package:maypole/features/maypolechat/domain/maypole_message.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/maypole_chat_view_model.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/maypole_gallery_view_model.dart';

import '../data/maypole_chat_service.dart';
import '../data/maypole_image_service.dart';

final maypoleChatThreadServiceProvider = Provider<MaypoleChatService>((ref) {
  return MaypoleChatService();
});

final maypoleChatViewModelProvider = AsyncNotifierProvider
    .family<MaypoleChatViewModel, List<MaypoleMessage>, String>(
      (threadId) => MaypoleChatViewModel(threadId),
    );

/// Provider for the maypole image service
final maypoleImageServiceProvider = Provider<MaypoleImageService>((ref) {
  return MaypoleImageService();
});

/// Provider for streaming images from a maypole (deprecated - use gallery view model instead)
final maypoleImagesProvider = StreamProvider.autoDispose.family<List<MaypoleImage>, String>((ref, maypoleId) {
  final service = ref.watch(maypoleImageServiceProvider);
  return service.getImages(maypoleId);
});

/// Provider for the maypole gallery view model with pagination support
final maypoleGalleryViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<MaypoleGalleryViewModel, List<MaypoleImage>, String>(
      (maypoleId) => MaypoleGalleryViewModel(maypoleId),
    );
