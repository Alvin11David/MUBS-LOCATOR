import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'dart:ui';
import 'package:mubs_locator/components/bottom_navbar.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mubs_locator/models/building_model.dart';
import 'package:mubs_locator/repository/building_repo.dart';
import 'package:mubs_locator/services/navigation_service.dart';
import 'package:mubs_locator/user%20pages/map%20screens/navigation_screen.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationSelectScreen extends StatefulWidget {
  final VoidCallback onDirectionsTap;
  const LocationSelectScreen({super.key, required this.onDirectionsTap});

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _fromFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();
  final NavigationService _navigationService = Get.find<NavigationService>();
  bool _isCheckingPermissions = false;

  List<Building> fetchedBuildings = [];
  bool _isLoadingBuildings = true;
  bool _isLoadingLocation = true;
  LatLng? _currentLocation;
  Building? _selectedFromLocation;
  Building? _selectedToLocation;
  GoogleMapController? _mapController;

  final LatLng _mubsMaingate = const LatLng(
    0.32626314488423924,
    32.616607995731286,
  );

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void onDirectionsTap() async {
    if (_selectedToLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a destination.')));
      return;
    }

    final destinationLatLng = LatLng(
      _selectedToLocation!.location.latitude,
      _selectedToLocation!.location.longitude,
    );
    final destinationName = _selectedToLocation!.name;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NavigationScreen(
          destination: destinationLatLng,
          destinationName: destinationName,
        ),
      ),
    );
  }

  Future<void> _handleStartNavigation() async {
    setState(() {
      _isCheckingPermissions = true;
    });
    try {
      final hasPermission = await _navigationService
          .checkAndRequestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _isCheckingPermissions = false;
        });
        if (!mounted) return;
        _showPermissionDialog();
        return;
      }
      final currentLocation = await _navigationService.getCurrentLocation();
      if (currentLocation == null) {
        setState(() {
          _isCheckingPermissions = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to get your location. Please check your GPS settings.',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        return;
      }
      setState(() {
        _isCheckingPermissions = false;
      });
      if (!mounted) return;
      onDirectionsTap();
    } catch (e) {
      setState(() {
        _isCheckingPermissions = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting navigation: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _handleStartNavigation,
          ),
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Location Permission'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _navigationService.errorMessage.value.isNotEmpty
                  ? _navigationService.errorMessage.value
                  : 'Location permission is required for navigation.',
              style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please enable location permission in your device settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleStartNavigation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeData() async {
    await Future.wait([_fetchBuildings(), _getCurrentLocation()]);
  }

  Future<void> _fetchBuildings() async {
    try {
      BuildingRepository buildingRepository = BuildingRepository();
      final buildings = await buildingRepository.getAllBuildings();
      if (mounted) {
        setState(() {
          fetchedBuildings = buildings;
          _isLoadingBuildings = false;
        });
      }
      print("✅ Successfully fetched ${buildings.length} buildings.");
    } catch (e) {
      print("❌ Failed to fetch buildings: $e");
      if (mounted) {
        setState(() {
          _isLoadingBuildings = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _fromController.text = "Location services disabled";
          });
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _fromController.text = "Location permission denied";
            });
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _fromController.text = "Location permission permanently denied";
          });
        }
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _fromController.text = "Your Current Location";
          _isLoadingLocation = false;
        });
      }
      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentLocation!),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _fromController.text = "Unable to get location";
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  List<Building> _getSuggestions(String pattern) {
    if (pattern.isEmpty) return [];
    final matches = fetchedBuildings.map((building) {
      final nameScore = StringSimilarity.compareTwoStrings(
        building.name.toLowerCase(),
        pattern.toLowerCase(),
      );
      final otherNameScore =
          (building.otherNames != null && building.otherNames!.isNotEmpty)
          ? building.otherNames!
                .map(
                  (name) => StringSimilarity.compareTwoStrings(
                    name.toLowerCase(),
                    pattern.toLowerCase(),
                  ),
                )
                .fold<double>(0, (prev, curr) => curr > prev ? curr : prev)
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
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    return matches
        .where((m) => (m['score'] as double) > 0.1)
        .take(10)
        .map((m) => m['building'] as Building)
        .toList();
  }

  void _swapLocations() {
    if (mounted) {
      setState(() {
        final tempController = _fromController.text;
        final tempLocation = _selectedFromLocation;
        _fromController.text = _toController.text;
        _selectedFromLocation = _selectedToLocation;
        _toController.text = tempController;
        _selectedToLocation = tempLocation;
      });
    }
  }

  void _navigateToHomeScreen() {
    Navigator.pushReplacementNamed(context, '/HomeScreen');
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _searchController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
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
    if (_selectedFromLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId('from_${_selectedFromLocation!.id}'),
          position: LatLng(
            _selectedFromLocation!.location.latitude,
            _selectedFromLocation!.location.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: _selectedFromLocation!.name),
        ),
      );
    }
    if (_selectedToLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId('to_${_selectedToLocation!.id}'),
          position: LatLng(
            _selectedToLocation!.location.latitude,
            _selectedToLocation!.location.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: _selectedToLocation!.name),
        ),
      );
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(
              _selectedToLocation!.location.latitude,
              _selectedToLocation!.location.longitude,
            ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaler = MediaQuery.textScalerOf(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenHeight * 0.008,
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.065,
            height: screenWidth * 0.065,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3E5891).withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF3E5891),
                size: screenWidth * 0.038,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
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
                    fontSize: textScaler.scale(14),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: textScaler.scale(14),
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.008,
                    ),
                    suffixIcon:
                        textController.text.isNotEmpty &&
                            !(isFrom &&
                                textController.text == "Your Current Location")
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: screenWidth * 0.04,
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
                  readOnly:
                      isFrom &&
                      _currentLocation != null &&
                      textController.text == "Your Current Location",
                  onTap: () {
                    if (isFrom &&
                        textController.text == "Your Current Location") {
                      textController.clear();
                      setState(() {});
                    }
                  },
                );
              },
              suggestionsCallback: (pattern) async {
                if (pattern.isEmpty || _isLoadingBuildings) return [];
                // Case-insensitive, any part of name
                final lowerPattern = pattern.toLowerCase();
                return fetchedBuildings
                    .where(
                      (building) =>
                          building.name.toLowerCase().contains(lowerPattern),
                    )
                    .toList();
              },
              itemBuilder: (context, Building suggestion) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF3E5891),
                            size: textScaler.scale(18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: textScaler.scale(14),
                                    fontFamily: 'Poppins',
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  suggestion.description,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: textScaler.scale(12),
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
                focusNode.unfocus();
                if (_mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(
                        suggestion.location.latitude,
                        suggestion.location.longitude,
                      ),
                    ),
                  );
                }
              },
              emptyBuilder: (context) => Container(
                color: Colors.white.withOpacity(0.35),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No locations found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: textScaler.scale(14),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              errorBuilder: (context, error) => Container(
                color: Colors.white.withOpacity(0.35),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: $error',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: textScaler.scale(14),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaler = MediaQuery.textScalerOf(context);
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _mubsMaingate,
              zoom: 17,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _buildMarkers(),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
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
                            Icons.arrow_back,
                            color: Colors.black,
                            size: screenWidth * 0.06,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: screenWidth * 0.9,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
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
                                  _buildLocationField(
                                    controller: _fromController,
                                    focusNode: _fromFocusNode,
                                    icon: Icons.my_location,
                                    hint: 'Start location',
                                    isFrom: true,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.12,
                                    ),
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
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
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: _swapLocations,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.01,
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
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ),
                ),
                if (_fromController.text.isNotEmpty &&
                    _toController.text.isNotEmpty &&
                    _fromController.text != "Location services disabled" &&
                    _fromController.text != "Location permission denied" &&
                    _fromController.text !=
                        "Location permission permanently denied" &&
                    _fromController.text != "Unable to get location")
                  Center(
                    child: GestureDetector(
                      onTap: _handleStartNavigation,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.08,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.018,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.run_circle,
                                  color: const Color(0xFF3E5891),
                                  size: MediaQuery.textScalerOf(
                                    context,
                                  ).scale(22),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.03,
                                ),
                                Text(
                                  'Start',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(16),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.01,
                  ),
                  child: GestureDetector(
                    onTap: _navigateToHomeScreen,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: screenWidth * 0.065,
                            height: screenWidth * 0.065,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3E5891).withOpacity(0.1),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.location_on,
                                color: const Color(0xFF3E5891),
                                size: screenWidth * 0.038,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: Text(
                              'Choose on map',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: textScaler.scale(14),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: screenWidth * 0.05,
          right: screenWidth * 0.05,
          bottom: screenHeight * 0.015,
        ),
        child: SizedBox(
          width: screenWidth * 0.9,
          child: const BottomNavBar(initialIndex: 1),
        ),
      ),
    );
  }
}
