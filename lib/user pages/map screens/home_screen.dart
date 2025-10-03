import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mubs_locator/models/building_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mubs_locator/repository/building_repo.dart';
import 'package:string_similarity/string_similarity.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LatLng _mubsMaingate = LatLng(0.32626314488423924, 32.616607995731286);
  final LatLng _mubsCentre = LatLng(0.3282482847196531, 32.61798173177951);
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();

  Set<Marker> markers = {};
  Set<Polygon> polygons = {};
  Set<Polyline> polylines = {};
  final String _googleApiKey = 'AIzaSyBTk9548rr1JiKe1guF1i8z2wqHV8CZjRA';
  List<Building> fetchedBuildings = [];
  bool searchActive = true;

  // Updated MUBS boundary coordinates - using your exact coordinates
  final List<LatLng> _mubsBounds = [
    LatLng(0.32665770214412915, 32.615554267866116),
    LatLng(0.329929943362535, 32.61561864088474),
    LatLng(0.33011233054641215, 32.616401845944665),
    LatLng(0.3309920804452059, 32.61645549012686),
    LatLng(0.3309491658180317, 32.61709922025041),
    LatLng(0.32991921470477137, 32.61831157876784),
    LatLng(0.32925403788744845, 32.61857979967877),
    LatLng(0.3280202420604525, 32.619599039140326),
    LatLng(0.32748380904471847, 32.62030714234519),
    LatLng(0.32528443338059565, 32.61775367927309),
    LatLng(0.32652895820572553, 32.61566155616781),
  ];

  @override
  void initState() {
    super.initState();
    fetchAllData();
    _initializeMarkers();
    _initializePolygons();
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

  void _initializePolygons() {
    // Create the main MUBS campus polygon with blue border
    polygons.add(
      Polygon(
        polygonId: PolygonId('mubs_campus'),
        points: _mubsBounds,
        strokeColor: Colors.blue,
        strokeWidth: 2,
        fillColor: Colors.transparent,
        geodesic: true,
      ),
    );
  }

  List<LatLng> _createLargeOuterBounds() {
    // Create a large rectangular boundary that encompasses the entire map view
    // This ensures the blur effect covers all areas outside the campus
    double minLat = _mubsBounds.map((p) => p.latitude).reduce(math.min) - 0.02;
    double maxLat = _mubsBounds.map((p) => p.latitude).reduce(math.max) + 0.02;
    double minLng = _mubsBounds.map((p) => p.longitude).reduce(math.min) - 0.02;
    double maxLng = _mubsBounds.map((p) => p.longitude).reduce(math.max) + 0.02;

    return [
      LatLng(minLat, minLng),
      LatLng(minLat, maxLng),
      LatLng(maxLat, maxLng),
      LatLng(maxLat, minLng),
    ];
  }

  Future<void> fetchAllData() async {
    try {
      BuildingRepository buildingRepository = BuildingRepository();
      final buildings = await buildingRepository.getAllBuildings();
      fetchedBuildings.addAll(buildings);
      setState(() {
        for (var element in buildings) {
          markers.add(
            Marker(
              markerId: MarkerId(element.id),
              position: LatLng(
                element.location.latitude,
                element.location.longitude,
              ),
              infoWindow: InfoWindow(
                title: element.name,
                snippet: element.description,
              ),
            ),
          );
        }
      });

      print("✅ Successfully fetched ${buildings.length} buildings.");
    } catch (e, stackTrace) {
      print("❌ Failed to fetch buildings: $e");
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> createTheBuildings() async {
    try {
      List<Building> buildings = mubsBuildings;
      BuildingRepository buildingRepository = BuildingRepository();

      for (var item in buildings) {
        buildingRepository.addBuilding(item);
        print('Added building: ${item.name} to Firestore');
      }
    } catch (e) {
      print('Error creating buildings: $e');
    }
  }

  void _showBuildingBottomSheet(BuildContext context, Building building) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6, // Start at 60% of screen height
          minChildSize: 0.3, // Can be dragged down to 30%
          maxChildSize: 0.9, // Can be expanded to 90%
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: _BuildingBottomSheetContent(
                building: building,
                scrollController: scrollController,
                onDirectionsTap: () {
                  _clearSearchBar(); // <-- Clear search bar before navigation
                  _navigateToBuilding(building);
                },
                onFeedbackSubmit:
                    (String issueType, String issueTitle, String description) {
                      _submitFeedback(
                        building,
                        issueType,
                        issueTitle,
                        description,
                      );
                    },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToBuilding(Building building) async {
    if (mapController != null) {
      LatLng buildingLocation = LatLng(
        building.location.latitude,
        building.location.longitude,
      );

      // Keep only the origin marker (MUBS Maingate)
      markers.removeWhere((marker) => marker.markerId.value != 'mubs_maingate');

      // Remove any previous destination marker
      markers.removeWhere((marker) => marker.markerId.value == 'destination');

      // Add new marker for the building (destination)
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: buildingLocation,
          infoWindow: InfoWindow(
            title: building.name,
            snippet: building.description,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Get directions
      await _getDirections(buildingLocation);

      // Update the map
      setState(() {});

      // Animate camera to show both markers and route
      final bounds = LatLngBounds(
        southwest: LatLng(
          _mubsMaingate.latitude < buildingLocation.latitude
              ? _mubsMaingate.latitude
              : buildingLocation.latitude,
          _mubsMaingate.longitude < buildingLocation.longitude
              ? _mubsMaingate.longitude
              : buildingLocation.longitude,
        ),
        northeast: LatLng(
          _mubsMaingate.latitude > buildingLocation.latitude
              ? _mubsMaingate.latitude
              : buildingLocation.latitude,
          _mubsMaingate.longitude > buildingLocation.longitude
              ? _mubsMaingate.longitude
              : buildingLocation.longitude,
        ),
      );

      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          100, // padding
        ),
      );
    }
  }

  Future<void> _getDirections(LatLng destination) async {
    final origin = _mubsMaingate;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}&'
      'destination=${destination.latitude},${destination.longitude}&'
      'key=$_googleApiKey&mode=walking',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final points = data['routes'][0]['overview_polyline']['points'];
          List<LatLng> routeCoords = _convertToLatLng(_decodePoly(points));

          setState(() {
            polylines.clear();
            polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: routeCoords,
                color: Colors.blue,
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
            );
          });
        }
      }
    } catch (e) {
      print('Error getting directions: $e');
    }
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = [];
    for (int i = 0; i < points.length; i++) {
      if (points[i] is double) {
        result.add(LatLng(points[i], points[i + 1]));
        i++;
      } else if (points[i] is LatLng) {
        result.add(points[i]);
      }
    }
    return result;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = polygon.length - 1, i = 0; i < polygon.length; j = i++) {
      if (((polygon[i].latitude <= point.latitude &&
                  point.latitude < polygon[j].latitude) ||
              (polygon[j].latitude <= point.latitude &&
                  point.latitude < polygon[i].latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  void _submitFeedback(
    Building building,
    String issueType,
    String issueTitle,
    String description,
  ) {
    print('Feedback submitted for ${building.name}:');
    print('Issue Type: $issueType');
    print('Title: $issueTitle');
    print('Description: $description');
  }

  void _clearSearchBar() {
    searchController.clear();
    setState(() {
      searchActive = false; // Disable suggestions after navigation
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Good morning, User'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: createTheBuildings,
            icon: Icon(Icons.notifications_rounded),
          ),
        ],
      ),
      drawer: Drawer(),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _mubsCentre,
              zoom: 17, // Adjusted zoom to better show the campus
            ),
            markers: markers,
            polygons: polygons,
            polylines: polylines,
            mapType: MapType.normal,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),

          // Search bar positioned on top
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
              child: TypeAheadField<Building>(
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
                      setState(() {
                        searchActive = true; // Enable suggestions when typing
                      });
                    },
                  );
                },
                suggestionsCallback: (pattern) async {
                  if (!searchActive || pattern.isEmpty) return [];

                  final matches = fetchedBuildings.map((building) {
                    final nameScore = StringSimilarity.compareTwoStrings(
                      building.name.toLowerCase(),
                      pattern.toLowerCase(),
                    );
                    final otherNameScore =
                        (building.otherNames != null &&
                            building.otherNames!.isNotEmpty)
                        ? building.otherNames!
                              .map(
                                (name) => StringSimilarity.compareTwoStrings(
                                  name.toLowerCase(),
                                  pattern.toLowerCase(),
                                ),
                              )
                              .fold<double>(
                                0,
                                (prev, curr) => curr > prev ? curr : prev,
                              )
                        : 0;

                    final descriptionScore = StringSimilarity.compareTwoStrings(
                      building.description.toLowerCase(),
                      pattern.toLowerCase(),
                    );

                    final maxScore = [
                      nameScore,
                      otherNameScore,
                      descriptionScore,
                    ].reduce((a, b) => a > b ? a : b);

                    return {'building': building, 'score': maxScore};
                  }).toList();

                  matches.sort(
                    (a, b) =>
                        (b['score'] as double).compareTo(a['score'] as double),
                  );

                  return matches
                      .where((m) => (m['score'] as double) > 0.1)
                      .take(10)
                      .map((m) => m['building'] as Building)
                      .toList();
                },
                itemBuilder: (context, Building suggestion) {
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
                                suggestion.description,
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
                onSelected: (Building suggestion) {
                  debugPrint("Selected: ${suggestion.name}");
                  searchController.text = suggestion.name;
                  _showBuildingBottomSheet(context, suggestion);
                },
                errorBuilder: (context, error) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Something went wrong 😢: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                emptyBuilder: (context) {
                  if (!searchActive)
                    return SizedBox.shrink(); // Hide message if not active
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No places found. Try another keyword.'),
                  );
                },
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

// Keep all your existing _BuildingBottomSheetContent class unchanged
class _BuildingBottomSheetContent extends StatefulWidget {
  final Building building;
  final ScrollController scrollController;
  final VoidCallback onDirectionsTap;
  final Function(String, String, String) onFeedbackSubmit;

  const _BuildingBottomSheetContent({
    required this.building,
    required this.scrollController,
    required this.onDirectionsTap,
    required this.onFeedbackSubmit,
  });

  @override
  State<_BuildingBottomSheetContent> createState() =>
      _BuildingBottomSheetContentState();
}

class _BuildingBottomSheetContentState
    extends State<_BuildingBottomSheetContent> {
  int _selectedTabIndex = 0;
  final TextEditingController _issueTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedIssueType = 'General';

  final List<String> _issueTypes = [
    'General',
    'Location Incorrect',
    'Missing Information',
    'Accessibility Issue',
    'Facility Issue',
    'Other',
  ];

  @override
  void dispose() {
    _issueTitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height *
          0.75, // Takes up 75% of screen height
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
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

              // Building name
              Text(
                widget.building.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                widget.building.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Tab buttons
              Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      icon: Icons.info_outline,
                      label: 'Details',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      icon: Icons.directions,
                      label: 'Directions',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTabButton(
                      index: 2,
                      icon: Icons.feedback_outlined,
                      label: 'Feedback',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tab content
              _buildTabContent(),

              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });

        // Removed the automatic navigation trigger
        // Now only changes the tab, doesn't immediately start navigation
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 4.0),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDetailsContent();
      case 1:
        return _buildDirectionsContent();
      case 2:
        return _buildFeedbackContent();
      default:
        return _buildDetailsContent();
    }
  }

  Widget _buildDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          widget.building.description,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),

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
                'Lat: ${widget.building.location.latitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                'Long: ${widget.building.location.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionsContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.navigation,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Get Directions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Navigate to ${widget.building.name}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),

          // Start Navigation Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // This is where the actual navigation starts
                widget.onDirectionsTap();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Start Navigation',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submit Feedback',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        Text(
          'Issue Type',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedIssueType,
              isExpanded: true,
              items: _issueTypes.map((String type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedIssueType = newValue;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Issue Title',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _issueTitleController,
          decoration: InputDecoration(
            hintText: 'Enter a brief title for the issue',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Description',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the issue in detail...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_issueTitleController.text.trim().isNotEmpty &&
                  _descriptionController.text.trim().isNotEmpty) {
                widget.onFeedbackSubmit(
                  _selectedIssueType,
                  _issueTitleController.text.trim(),
                  _descriptionController.text.trim(),
                );

                _issueTitleController.clear();
                _descriptionController.clear();
                setState(() {
                  _selectedIssueType = 'General';
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feedback submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Submit Feedback',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
