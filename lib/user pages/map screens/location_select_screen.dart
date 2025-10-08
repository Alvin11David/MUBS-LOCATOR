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
  GoogleMapController? _mapController;

  // Default camera position (you can change this to your preferred location)
  
  final LatLng _mubsMaingate = LatLng(0.32626314488423924, 32.616607995731286);


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
        _fromController.text = " Start";
        _isLoadingLocation = false;
      });

      // Move camera to current location
      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentLocation!),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _isLoadingLocation = false;
        _fromController.text = "Unable to get location";
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
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
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Google Maps Background
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _mubsMaingate, zoom: 17),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _buildMarkers(),
          ),

          // Overlay UI
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                //Padding(
                //  padding: EdgeInsets.symmetric(
                //    horizontal: MediaQuery.of(context).size.width * 0.05,
                //    vertical: MediaQuery.of(context).size.height * 0.02,
                //  ),
                  //child: Row(
                  //  children: [
                  //    GestureDetector(
                  //      onTap: () => Navigator.pop(context),
                  //      child: Container(
                  //        padding: const EdgeInsets.all(8),
                  //        decoration: BoxDecoration(
                  //          color: Colors.white,
                  //          shape: BoxShape.circle,
                  //          boxShadow: [
                  //            BoxShadow(
                  //              color: Colors.black.withOpacity(0.1),
                  //              blurRadius: 8,
                  //              offset: const Offset(0, 2),
                  //            ),
                  //          ],
                  //        ),
                  //        child: Icon(
                  //          Icons.arrow_back,
                  //          color: Colors.black,
                  //          size: MediaQuery.of(context).size.width * 0.06,
                  //        ),
                  //      ),
                  //    ),
                  //    SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  //    
                  //  ],
                  //),
                //),

                // From and To location container
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: MediaQuery.of(context).size.height * 0.01,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
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
                          hint: 'Start location',
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
                          hint: 'Destination',
                          isFrom: false,
                        ),
                      ],
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.swap_vert,
                        color: Colors.black,
                        size: MediaQuery.of(context).size.width * 0.06,
                      ),
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
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

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add selected from location marker
    if (_selectedFromLocation != null && _selectedFromLocation!.location.latitude != null && _selectedFromLocation!.location.longitude != null) {
      markers.add(
        Marker(
          markerId: MarkerId('from_${_selectedFromLocation!.id}'),
          position: LatLng(_selectedFromLocation!.location.latitude!, _selectedFromLocation!.location.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: _selectedFromLocation!.name),
        ),
      );
    }

    // Add selected to location marker
    if (_selectedToLocation != null && _selectedToLocation!.location.latitude != null && _selectedToLocation!.location.longitude != null) {
      markers.add(
        Marker(
          markerId: MarkerId('to_${_selectedToLocation!.id}'),
          position: LatLng(_selectedToLocation!.location.latitude!, _selectedToLocation!.location.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: _selectedToLocation!.name),
        ),
      );

      // Move camera to show the destination
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_selectedToLocation!.location.latitude!, _selectedToLocation!.location.longitude),
          ),
        );
      }
    }

    return markers;
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
        horizontal: MediaQuery.of(context).size.width * 0.025,
        vertical: MediaQuery.of(context).size.height * 0.008,
      ),
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.065,
            height: MediaQuery.of(context).size.width * 0.065,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3E5891).withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF3E5891),
                size: MediaQuery.of(context).size.width * 0.038,
              ),
            ),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
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
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.008,
                    ),
                    suffixIcon: textController.text.isNotEmpty &&
                            !(isFrom && textController.text == "Your Current Location")
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: MediaQuery.of(context).size.width * 0.04,
                              color: Colors.grey[600],
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: const Color(0xFF3E5891),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              suggestion.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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

                // Move camera to selected location if coordinates are available
                if (suggestion.location.latitude != null && suggestion.location.longitude != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(suggestion.location.latitude!, suggestion.location.longitude!),
                    ),
                  );
                }
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