import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../../../core/app_config.dart';
import '../models/autocomplete_request.dart';
import '../models/autocomplete_response.dart';

class PlacesService {
  final String _apiKey = AppConfig.googlePlacesApiKey;
  final String _baseUrl =
      'https://places.googleapis.com/v1/places:autocomplete';

  Future<AutocompleteResponse> autocomplete(AutocompleteRequest request) async {
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: request.toJson(),
    );

    if (response.statusCode == 200) {

      debugPrint("Place Response: ${response.body}");
      return AutocompleteResponse.fromJson(response.body);
    } else {
      throw Exception('Failed to load predictions');
    }
  }
}
