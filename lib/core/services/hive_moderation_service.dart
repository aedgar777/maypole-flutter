import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for reporting content to Hive.ai for moderation
/// 
/// Hive.ai provides AI-powered content moderation for text and images.
/// This service allows users to report inappropriate content which will be
/// reviewed by Hive's moderation dashboard.
class HiveModerationService {
  final String apiToken;
  final String accessKeyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // V3 API endpoints (Playground)
  static const String _baseUrl = 'https://api.thehive.ai';
  static const String _textApiEndpoint = '/api/v3/hive/text-moderation';
  static const String _imageApiEndpoint = '/api/v3/hive/visual-moderation';

  HiveModerationService({
    required this.apiToken,
    required this.accessKeyId,
  });

  /// Report text content (messages) to Hive.ai
  /// 
  /// [contentId] - Unique identifier for the content being reported
  /// [reporterId] - User ID of the person reporting
  /// [textContent] - The actual text content to moderate
  /// [additionalContext] - Optional additional information (e.g., sender info)
  Future<bool> reportTextContent({
    required String contentId,
    required String reporterId,
    required String textContent,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      debugPrint('🔍 Reporting text content to Hive.ai V3: $contentId');
      
      // Hive.ai V3 API format for text moderation
      final requestBody = {
        'input': [
          {
            'text': textContent,
          }
        ],
      };
      
      debugPrint('📤 Request URL: $_baseUrl$_textApiEndpoint');
      debugPrint('📤 Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl$_textApiEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Successfully reported text content to Hive.ai: $contentId');
        
        // Parse response to check moderation results
        final responseData = jsonDecode(response.body);
        debugPrint('📊 Moderation results: $responseData');
        
        // Store the report in Firestore for review
        await _storeReportInFirestore(
          contentId: contentId,
          reporterId: reporterId,
          contentType: 'text',
          content: textContent,
          moderationResults: responseData,
          additionalContext: additionalContext,
        );
        
        return true;
      } else {
        debugPrint('❌ Failed to report to Hive.ai: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error reporting to Hive.ai: $e');
      return false;
    }
  }

  /// Report image content to Hive.ai
  /// 
  /// [contentId] - Unique identifier for the content being reported
  /// [reporterId] - User ID of the person reporting
  /// [imageUrl] - URL of the image to moderate
  /// [additionalContext] - Optional additional information (e.g., uploader info)
  Future<bool> reportImageContent({
    required String contentId,
    required String reporterId,
    required String imageUrl,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      debugPrint('🔍 Reporting image content to Hive.ai V3: $contentId');
      
      // Hive.ai V3 API format for image moderation
      final requestBody = {
        'input': [
          {
            'media_url': imageUrl,
          }
        ],
      };
      
      debugPrint('📤 Request URL: $_baseUrl$_imageApiEndpoint');
      debugPrint('📤 Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl$_imageApiEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Successfully reported image to Hive.ai: $contentId');
        
        // Parse response to check moderation results
        final responseData = jsonDecode(response.body);
        debugPrint('📊 Moderation results: $responseData');
        
        // Store the report in Firestore for review
        await _storeReportInFirestore(
          contentId: contentId,
          reporterId: reporterId,
          contentType: 'image',
          content: imageUrl,
          moderationResults: responseData,
          additionalContext: additionalContext,
        );
        
        return true;
      } else {
        debugPrint('❌ Failed to report to Hive.ai: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error reporting to Hive.ai: $e');
      return false;
    }
  }

  /// Report image within a message (message with images attached)
  /// 
  /// This handles the case where a DM has attached images
  Future<bool> reportMessageWithImages({
    required String contentId,
    required String reporterId,
    required String textContent,
    required List<String> imageUrls,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      // Report text content first if it exists
      if (textContent.isNotEmpty) {
        final textSuccess = await reportTextContent(
          contentId: '${contentId}_text',
          reporterId: reporterId,
          textContent: textContent,
          additionalContext: additionalContext,
        );
        if (!textSuccess) {
          return false;
        }
      }

      // Report each image
      for (int i = 0; i < imageUrls.length; i++) {
        final imageSuccess = await reportImageContent(
          contentId: '${contentId}_image_$i',
          reporterId: reporterId,
          imageUrl: imageUrls[i],
          additionalContext: additionalContext,
        );
        if (!imageSuccess) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error reporting message with images to Hive.ai: $e');
      return false;
    }
  }

  /// Store a content report in Firestore for admin review
  Future<void> _storeReportInFirestore({
    required String contentId,
    required String reporterId,
    required String contentType,
    required String content,
    required Map<String, dynamic> moderationResults,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      // Extract high-risk scores for quick filtering
      final scores = _extractHighRiskScores(moderationResults);
      final highestRisk = _calculateHighestRisk(scores);
      
      await _firestore.collection('reported_content').add({
        'contentId': contentId,
        'reporterId': reporterId,
        'contentType': contentType, // 'text' or 'image'
        'content': content, // The actual text or image URL
        'moderationScores': moderationResults,
        'highRiskCategories': scores,
        'highestRiskScore': highestRisk,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'pending_review', // pending_review, reviewed, actioned, dismissed
        'context': additionalContext ?? {},
      });
      
      debugPrint('💾 Stored report in Firestore for content: $contentId');
    } catch (e) {
      debugPrint('❌ Error storing report in Firestore: $e');
      // Don't throw - we don't want to fail the report if storage fails
    }
  }

  /// Extract high-risk moderation scores (>0.5) for easy filtering
  Map<String, double> _extractHighRiskScores(Map<String, dynamic> moderationResults) {
    final highRiskScores = <String, double>{};
    
    try {
      final output = moderationResults['output'] as List<dynamic>?;
      if (output == null || output.isEmpty) return highRiskScores;
      
      final classes = output[0]['classes'] as List<dynamic>?;
      if (classes == null) return highRiskScores;
      
      for (final classData in classes) {
        final className = classData['class_name'] as String?;
        final value = classData['value'] as num?;
        
        if (className != null && value != null && value > 0.5) {
          // Only store concerning classes (those that indicate presence of something)
          if (!className.startsWith('no_') && 
              !className.contains('not_') &&
              className != 'natural' &&
              className != 'animated') {
            highRiskScores[className] = value.toDouble();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error extracting high-risk scores: $e');
    }
    
    return highRiskScores;
  }

  /// Calculate the highest risk score from moderation results
  double _calculateHighestRisk(Map<String, double> scores) {
    if (scores.isEmpty) return 0.0;
    return scores.values.reduce((a, b) => a > b ? a : b);
  }
}
