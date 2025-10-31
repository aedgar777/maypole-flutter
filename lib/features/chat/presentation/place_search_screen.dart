import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:maypole/core/app_config.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Places'),
      ),
      body: GooglePlaceAutoCompleteTextField(
        textEditingController: _searchController,
        googleAPIKey: AppConfig.googlePlacesApiKey,
        inputDecoration: const InputDecoration(
          hintText: "Search for a place",
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        debounceTime: 800,
        countries: const ["us", "ca"], // You can add more countries here
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (prediction) {
          // Called when a place is selected
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Selected: ${prediction.description}\nLat: ${prediction.lat}\nLng: ${prediction.lng}'),
            ),
          );
          Navigator.of(context).pop();
        },
        itemClick: (prediction) {
          _searchController.text = prediction.description ?? "";
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: prediction.description?.length ?? 0),
          );
        },
      ),
    );
  }
}
