import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mubs_locator/models/building_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mubs_locator/repository/building_repo.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LatLng _mubsMaingate = LatLng(0.32626314488423924, 32.616607995731286);
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();

  Set<Marker> markers = {};
  List<Building> fetchedBuildings = [];

  @override
  void initState() {
    super.initState();
    fetchAllData();
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

  Future<void> fetchAllData() async {
    try {
      BuildingRepository buildingRepository = BuildingRepository();

      // Await the async call (assuming getAllBuildings is async)
      final buildings = await buildingRepository.getAllBuildings();
      fetchedBuildings.addAll(buildings);
      print(fetchedBuildings);

      // You can add logging or state management here
      print("✅ Successfully fetched ${buildings.length} buildings.");
    } catch (e, stackTrace) {
      // Handle any errors properly
      print("❌ Failed to fetch buildings: $e");
      print(stackTrace);

      // Optionally rethrow or handle gracefully
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
            initialChildSize: 0.5,
            minChildSize: 0.5,
            maxChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) {
              return _BuildingBottomSheetContent(
                building: building,
                scrollController: scrollController,
                onDirectionsTap: () => _navigateToBuilding(building),
                onFeedbackSubmit:
                    (String issueType, String issueTitle, String description) {
                      _submitFeedback(
                        building,
                        issueType,
                        issueTitle,
                        description,
                      );
                    },
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToBuilding(Building building) {
    if (mapController != null) {
      // Ensure the building is within MUBS bounds before navigating
      LatLng buildingLocation = LatLng(
        building.location.latitude,
        building.location.longitude,
      );

      if (!_isWithinMubsBounds(buildingLocation)) {
        // Show warning if building is outside campus
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location is outside MUBS campus area'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Add marker for the selected building
      final buildingMarker = Marker(
        markerId: MarkerId('selected_${building.id}'),
        position: buildingLocation,
        infoWindow: InfoWindow(title: building.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      setState(() {
        markers.add(buildingMarker);
      });

      // Animate camera to the building with constrained zoom
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          buildingLocation,
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
    return SizedBox(
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

  void _startNavigation(Building building) {
    debugPrint("Starting navigation to: ${building.name}");
    // Implement start navigation functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting navigation to ${building.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFeedback(Building building) {
    debugPrint("Showing feedback for: ${building.name}");
    // Implement feedback functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feedback for ${building.name}'),
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

  void _shareBuilding(Building building) {
    final shareText =
        '${building.name}\n${building.description}\nDescription: ${building.description}\nLocation: (${building.location.latitude}, ${building.location.longitude})';
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

  // Add this method to handle feedback submission
  void _submitFeedback(
    Building building,
    String issueType,
    String issueTitle,
    String description,
  ) {
    // Implement your feedback submission logic here
    print('Feedback submitted for ${building.name}:');
    print('Issue Type: $issueType');
    print('Title: $issueTitle');
    print('Description: $description');

    // You can send this data to your backend API
    // Example:
    // await feedbackService.submitFeedback({
    //   'placeId': place.id,
    //   'placeName': place.name,
    //   'issueType': issueType,
    //   'issueTitle': issueTitle,
    //   'description': description,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
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
                      setState(() {});
                    },
                  );
                },
                suggestionsCallback: (pattern) async {
                  if (pattern.isEmpty) return [];

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
                      .take(10) // Limit to top 10 results
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

class _BuildingBottomSheetContent extends StatefulWidget {
  final Building building;
  final ScrollController scrollController;
  final VoidCallback onDirectionsTap;
  final Function(String, String, String) onFeedbackSubmit;

  const _BuildingBottomSheetContent({
    super.key,
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
  int _selectedTabIndex = 0; // 0: Details, 1: Directions, 2: Feedback

  // Feedback form controllers
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
    return SingleChildScrollView(
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

        // Special handling for directions tab
        if (index == 1) {
          widget.onDirectionsTap();
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
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
        // Description
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
            'Navigation Started',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A marker has been added to the map for ${widget.building.name}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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

        // Issue Type Dropdown
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

        // Issue Title
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

        // Description
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

        // Submit Button
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

                // Clear the form
                _issueTitleController.clear();
                _descriptionController.clear();
                setState(() {
                  _selectedIssueType = 'General';
                });

                // Show success message
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
