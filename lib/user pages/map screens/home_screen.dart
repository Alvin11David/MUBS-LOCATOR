import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mubs_locator/models/places_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng _mubsMaingate = LatLng(0.32626314488423924, 32.616607995731286);
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();

  List<Place> places = [];
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    loadPlaces();
    _initializeMarkers();
  }

  void _initializeMarkers() {
    markers.add(
      Marker(
        markerId: MarkerId('mubs_maingate'),
        position: _mubsMaingate,
        infoWindow: InfoWindow(
          title: 'MUBS Maingate',
          snippet: 'Makerere University Business School',
        ),
      ),
    );
  }

  Future<void> loadPlaces() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/places.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    setState(() {
      places = jsonList.map((json) => Place.fromJson(json)).toList();
    });
  }

  void _showPlaceBottomSheet(BuildContext context, Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag indicator
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Place name
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Department
                      Text(
                        place.department,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _navigateToPlace(place);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.navigation),
                              label: const Text('Navigate'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _sharePlace(place);
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Description
                      Text(
                        'Description',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place.description,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      // Coordinates info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location Coordinates',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${place.latitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              'Long: ${place.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons
                      

                      // Bottom padding for safe area
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 10,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToPlace(Place place) {
    if (mapController != null) {
      // Ensure the place is within MUBS bounds before navigating
      LatLng placeLocation = LatLng(place.latitude, place.longitude);

      if (!_isWithinMubsBounds(placeLocation)) {
        // Show warning if place is outside campus
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location is outside MUBS campus area'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Add marker for the selected place
      final placeMarker = Marker(
        markerId: MarkerId('selected_${place.id}'),
        position: placeLocation,
        infoWindow: InfoWindow(title: place.name, snippet: place.department),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      setState(() {
        markers.add(placeMarker);
      });

      // Animate camera to the place with constrained zoom
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          placeLocation,
          18.0, // Close zoom for details
        ),
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 90,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _startNavigation(Place place) {
    debugPrint("Starting navigation to: ${place.name}");
    // Implement start navigation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting navigation to ${place.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFeedback(Place place) {
    debugPrint("Showing feedback for: ${place.name}");
    // Implement feedback functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feedback for ${place.name}'),
        content: Text('Feedback functionality would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _sharePlace(Place place) {
    final shareText =
        '${place.name}\n${place.description}\nDepartment: ${place.department}\nLocation: (${place.latitude}, ${place.longitude})';
    Share.share(shareText);
  }

  bool _isWithinMubsBounds(LatLng location) {
    // Example bounds, adjust to your campus area
    const double minLat = 0.3260;
    const double maxLat = 0.3490;
    const double minLng = 32.5810;
    const double maxLng = 32.6170;

    return location.latitude >= minLat &&
        location.latitude <= maxLat &&
        location.longitude >= minLng &&
        location.longitude <= maxLng;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Good morning, User'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications_rounded)),
        ],
      ),
      drawer: Drawer(),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _mubsMaingate,
              zoom: 13,
            ),
            markers: markers,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TypeAheadField<Place>(
                controller: searchController,
                builder: (context, textController, focusNode) {
                  return TextField(
                    controller: textController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search buildings, departments, etc.',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: textController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                textController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  );
                },
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) return [];

                  final matches = places.map((place) {
                    final nameScore = StringSimilarity.compareTwoStrings(
                      place.name.toLowerCase(),
                      pattern.toLowerCase(),
                    );
                    final deptScore = StringSimilarity.compareTwoStrings(
                      place.department.toLowerCase(),
                      pattern.toLowerCase(),
                    );
                    final descScore = StringSimilarity.compareTwoStrings(
                      place.description.toLowerCase(),
                      pattern.toLowerCase(),
                    );

                    final maxScore = [
                      nameScore,
                      deptScore,
                      descScore,
                    ].reduce((a, b) => a > b ? a : b);

                    return {'place': place, 'score': maxScore};
                  }).toList();

                  matches.sort(
                    (a, b) =>
                        (b['score'] as double).compareTo(a['score'] as double),
                  );

                  return matches
                      .where((m) => (m['score'] as double) > 0.1)
                      .take(10) // Limit to top 10 results
                      .map((m) => m['place'] as Place)
                      .toList();
                },
                itemBuilder: (context, Place suggestion) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                suggestion.department,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onSelected: (Place suggestion) {
                  debugPrint("Selected: ${suggestion.name}");
                  searchController.text = suggestion.name;
                  _showPlaceBottomSheet(context, suggestion);
                },
                errorBuilder: (context, error) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Something went wrong 😢: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                emptyBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No places found. Try another keyword.'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
