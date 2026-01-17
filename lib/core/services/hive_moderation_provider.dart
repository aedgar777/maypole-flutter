import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'hive_moderation_service.dart';

/// Provider for Hive.ai moderation service
final hiveModerationServiceProvider = Provider<HiveModerationService>((ref) {
  final apiToken = dotenv.env['HIVE_API_TOKEN'] ?? '';
  final accessKeyId = dotenv.env['HIVE_ACCESS_ID_KEY'] ?? '';
  
  if (apiToken.isEmpty || accessKeyId.isEmpty) {
    throw Exception('HIVE_API_TOKEN and HIVE_ACCESS_ID_KEY not found in .env file. Please add your Hive.ai API credentials to the .env file.');
  }
  
  return HiveModerationService(
    apiToken: apiToken,
    accessKeyId: accessKeyId,
  );
});
