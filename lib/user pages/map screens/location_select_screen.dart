import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mubs_locator/components/bottom_navbar.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mubs_locator/models/building_model.dart';
import 'package:mubs_locator/repository/building_repo.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({super.key});

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();
  
  List<Building> fetchedBuildings = [];
  bool _isLoadingBuildings = true;
  bool _isLoadingLocation = true;
  LatLng? _currentLocation;
  Building? _selectedFromLocation;
  Building? _selectedToLocation;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchBuildings(),
      _getCurrentLocation(),
    ]);
  }

  Future<void> _fetchBuildings() async {
    try {
      BuildingRepository buildingRepository = BuildingRepository();
      final buildings = await buildingRepository.getAllBuildings();
      setState(() {
        fetchedBuildings = buildings;
        _isLoadingBuildings = false;
      });
      print("✅ Successfully fetched ${buildings.length} buildings.");
    } catch (e) {
      print("❌ Failed to fetch buildings: $e");
      setState(() {
        _isLoadingBuildings = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _fromController.text = "Location services disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _fromController.text = "Location permission denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _fromController.text = "Location permission permanently denied";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _fromController.text = "Your Current Location";
        _isLoadingLocation = false;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _isLoadingLocation = false;
        _fromController.text = "Unable to get location";
      });
    }
  }

  List<Building> _getSuggestions(String pattern) {
    if (pattern.isEmpty) return [];

    final matches = fetchedBuildings.map((building) {
      final nameScore = StringSimilarity.compareTwoStrings(
        building.name.toLowerCase(),
        pattern.toLowerCase(),
      );
      
      final otherNameScore = (building.otherNames != null && building.otherNames!.isNotEmpty)
          ? building.otherNames!
              .map((name) => StringSimilarity.compareTwoStrings(
                    name.toLowerCase(),
                    pattern.toLowerCase(),
                  ))
              .fold<double>(0, (prev, curr) => curr > prev ? curr : prev)
          : 0;

      final descriptionScore = StringSimilarity.compareTwoStrings(
        building.description.toLowerCase(),
        pattern.toLowerCase(),
      );

      final maxScore = [nameScore, otherNameScore, descriptionScore]
          .reduce((a, b) => a > b ? a : b);

      return {'building': building, 'score': maxScore};
    }).toList();

    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return matches
        .where((m) => (m['score'] as double) > 0.1)
        .take(10)
        .map((m) => m['building'] as Building)
        .toList();
  }

  void _swapLocations() {
    setState(() {
      final tempController = _fromController.text;
      final tempLocation = _selectedFromLocation;
      
      _fromController.text = _toController.text;
      _selectedFromLocation = _selectedToLocation;
      
      _toController.text = tempController;
      _selectedToLocation = tempLocation;
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFF93C5FD),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: MediaQuery.of(context).size.width * 0.06,
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                    Text(
                      'Select Locations',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                  ],
                ),
              ),

              // From and To location container
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // From location
                          _buildLocationField(
                            controller: _fromController,
                            focusNode: _fromFocusNode,
                            icon: Icons.my_location,
                            hint: 'Your location',
                            isFrom: true,
                          ),
                          
                          // Divider
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.12,
                            ),
                            child: Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          
                          // To location
                          _buildLocationField(
                            controller: _toController,
                            focusNode: _toFocusNode,
                            icon: Icons.location_on,
                            hint: 'Choose destination',
                            isFrom: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Swap button
              Center(
                child: GestureDetector(
                  onTap: _swapLocations,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.01,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.swap_vert,
                      color: Colors.black,
                      size: MediaQuery.of(context).size.width * 0.06,
                    ),
                  ),
                ),
              ),

              // Empty space
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        size: 64,
                        color: Colors.black.withOpacity(0.3),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Enter locations to get started',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.05,
          right: MediaQuery.of(context).size.width * 0.05,
          bottom: MediaQuery.of(context).size.height * 0.015,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: const BottomNavBar(),
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String hint,
    required bool isFrom,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.03,
        vertical: MediaQuery.of(context).size.height * 0.012,
      ),
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.08,
            height: MediaQuery.of(context).size.width * 0.08,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3E5891).withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF3E5891),
                size: MediaQuery.of(context).size.width * 0.045,
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.025),
          Expanded(
            child: TypeAheadField<Building>(
              controller: controller,
              focusNode: focusNode,
              builder: (context, textController, focusNode) {
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: MediaQuery.of(context).size.width * 0.038,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: MediaQuery.of(context).size.width * 0.038,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.01,
                    ),
                    suffixIcon: textController.text.isNotEmpty &&
                            !(isFrom && textController.text == "Your Current Location")
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: MediaQuery.of(context).size.width * 0.045,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              textController.clear();
                              if (isFrom) {
                                _selectedFromLocation = null;
                                if (_currentLocation != null) {
                                  textController.text = "Your Current Location";
                                }
                              } else {
                                _selectedToLocation = null;
                              }
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  readOnly: isFrom && _currentLocation != null && textController.text == "Your Current Location",
                  onTap: () {
                    if (isFrom && textController.text == "Your Current Location") {
                      textController.clear();
                      setState(() {});
                    }
                  },
                );
              },
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty || _isLoadingBuildings) return [];
                return _getSuggestions(pattern);
              },
              itemBuilder: (context, Building suggestion) {
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: const Color(0xFF3E5891),
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
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              suggestion.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              onSelected: (Building suggestion) {
                controller.text = suggestion.name;
                
                if (isFrom) {
                  _selectedFromLocation = suggestion;
                } else {
                  _selectedToLocation = suggestion;
                }
                
                setState(() {});
                
                // Unfocus to hide keyboard
                focusNode.unfocus();
              },
              emptyBuilder: (context) => Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'No locations found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              errorBuilder: (context, error) => Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}