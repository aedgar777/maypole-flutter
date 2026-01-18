import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/maypole_chat_service.dart';
import '../../domain/maypole.dart';
import '../../../maypolesearch/data/services/maypole_search_service.dart';
import 'maypole_chat_screen.dart';

/// Loader widget that fetches place details when navigating via deep link.
/// 
/// This widget:
/// 1. First checks Firestore for existing maypole metadata
/// 2. If not found, fetches from Google Places API
/// 3. Creates/updates Firestore document with place details
/// 4. Then shows the MaypoleChatScreen with the fetched data
class MaypoleChatLoader extends ConsumerStatefulWidget {
  final String threadId;

  const MaypoleChatLoader({
    super.key,
    required this.threadId,
  });

  @override
  ConsumerState<MaypoleChatLoader> createState() => _MaypoleChatLoaderState();
}

class _MaypoleChatLoaderState extends ConsumerState<MaypoleChatLoader> {
  final _chatService = MaypoleChatService();
  final _searchService = MaypoleSearchService();
  
  String? _placeName;
  String? _address;
  double? _latitude;
  double? _longitude;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlaceDetails();
  }

  Future<void> _fetchPlaceDetails() async {
    try {
      debugPrint('🔍 Fetching place details for threadId: ${widget.threadId}');
      
      // Step 1: Check Firestore for existing maypole metadata
      final maypoleDoc = await FirebaseFirestore.instance
          .collection('maypoles')
          .doc(widget.threadId)
          .get();
      
      if (maypoleDoc.exists && maypoleDoc.data() != null) {
        final data = maypoleDoc.data()!;
        debugPrint('✅ Found maypole in Firestore');
        
        setState(() {
          _placeName = data['name'] as String?;
          _address = data['address'] as String?;
          _latitude = data['latitude'] as double?;
          _longitude = data['longitude'] as double?;
          _isLoading = false;
        });
        
        // If we have the name, we're done
        if (_placeName != null && _placeName!.isNotEmpty) {
          return;
        }
      }
      
      // Step 2: Fetch from Google Places API
      debugPrint('📍 Fetching from Google Places API...');
      final placeDetails = await _searchService.getPlaceDetails(widget.threadId);
      
      if (placeDetails != null) {
        debugPrint('✅ Got place details from Google Places API');
        
        // Extract place information
        final displayName = placeDetails['displayName'];
        final placeName = displayName is Map 
            ? (displayName['text'] as String?) ?? 'Unknown Place'
            : 'Unknown Place';
        
        final formattedAddress = placeDetails['formattedAddress'] as String?;
        
        final location = placeDetails['location'] as Map<String, dynamic>?;
        final latitude = location?['latitude'] as double?;
        final longitude = location?['longitude'] as double?;
        
        // Step 3: Create/update Firestore document
        final metaData = MaypoleMetaData(
          id: widget.threadId,
          name: placeName,
          address: formattedAddress ?? '',
          latitude: latitude,
          longitude: longitude,
        );
        
        await FirebaseFirestore.instance
            .collection('maypoles')
            .doc(widget.threadId)
            .set(metaData.toMap(), SetOptions(merge: true));
        
        debugPrint('✅ Updated Firestore with place details');
        
        setState(() {
          _placeName = placeName;
          _address = formattedAddress;
          _latitude = latitude;
          _longitude = longitude;
          _isLoading = false;
        });
      } else {
        // Failed to fetch from API
        setState(() {
          _placeName = 'Unknown Place';
          _error = 'Could not fetch place details';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching place details: $e');
      setState(() {
        _placeName = 'Unknown Place';
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading place details...'),
            ],
          ),
        ),
      );
    }

    if (_error != null && _placeName == 'Unknown Place') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load place details', 
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_error ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchPlaceDetails();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Navigate to the actual chat screen with the fetched details
    return MaypoleChatScreen(
      threadId: widget.threadId,
      maypoleName: _placeName ?? 'Unknown Place',
      address: _address,
      latitude: _latitude,
      longitude: _longitude,
    );
  }
}
