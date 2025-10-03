import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mubs_locator/models/building_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mubs_locator/repository/building_repo.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

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
  Set<Polygon> polygons = {};
  Set<Polyline> polylines = {};
  final String _googleApiKey = 'AIzaSyBTk9548rr1JiKe1guF1i8z2wqHV8CZjRA';
  List<Building> fetchedBuildings = [];
  String _userFullName = 'User';
  bool _isMenuVisible = false;
  File? _profileImage; // Store the profile image

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
    _fetchUserFullName();
    _loadProfileImage(); // Load image from saved data
  }

  Future<void> _fetchUserFullName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        print('Fetching full name for email: ${user.email}');
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          final fullName = userData['fullName'] as String?;
          if (fullName != null && fullName.isNotEmpty) {
            if (mounted) {
              setState(() {
                _userFullName = fullName;
              });
              print('Successfully fetched full name: $_userFullName');
            }
          } else {
            print('Full name not found in Firestore document');
            if (mounted) {
              setState(() {
                _userFullName = 'User'; // Fallback if fullName is empty
              });
            }
          }
        } else {
          print('No Firestore document found for email: ${user.email}');
          if (mounted) {
            setState(() {
              _userFullName = 'User'; // Fallback if no document found
            });
          }
        }
      } else {
        print('No user signed in or email is null');
        if (mounted) {
          setState(() {
            _userFullName = 'User'; // Fallback if no user signed in
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error fetching user full name: $e');
      print(stackTrace);
      if (mounted) {
        setState(() {
          _userFullName = 'User'; // Fallback on error
        });
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profileImagePath');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
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

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await FirebaseAuth.instance.signOut();
      print('User signed out successfully');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/SignInScreen');
      }
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _toggleMenu() {
    setState(() {
      _isMenuVisible = !_isMenuVisible;
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logout successful')),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
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
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
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
                onDirectionsTap: () => _navigateToBuilding(building),
                onFeedbackSubmit: (
                  String issueType,
                  String issueTitle,
                  String description,
                ) {
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

      markers.removeWhere((marker) => marker.markerId.value == 'destination');
      polylines.clear();

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

      await _getDirections(buildingLocation);

      setState(() {});

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
          100,
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Good morning, $_userFullName',
          style: TextStyle(
            fontSize: textScaler.scale(18), // Responsive font size
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            size: textScaler.scale(24), // Responsive icon size
          ),
          onPressed: _toggleMenu,
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/NotificationsScreen'),
            icon: Icon(
              Icons.notifications_rounded,
              size: textScaler.scale(24), // Responsive icon size
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              // Check if the tap is outside the sidebar when it’s visible
              if (_isMenuVisible) {
                final tapX = details.globalPosition.dx;
                if (tapX > screenWidth * 0.6) {
                  setState(() {
                    _isMenuVisible = false;
                  });
                }
              }
            },
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _mubsMaingate,
                    zoom: 18.5,
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
                Positioned(
                  top: screenHeight * 0.02,
                  left: screenWidth * 0.04,
                  right: screenWidth * 0.04,
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
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: textScaler.scale(14),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[500],
                              size: textScaler.scale(20),
                            ),
                            suffixIcon: textController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: textScaler.scale(20),
                                    ),
                                    onPressed: () {
                                      textController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.015,
                            ),
                          ),
                          style: TextStyle(fontSize: textScaler.scale(14)),
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
                            .take(10)
                            .map((m) => m['building'] as Building)
                            .toList();
                      },
                      itemBuilder: (context, Building suggestion) {
                        return Container(
                          padding: EdgeInsets.all(screenWidth * 0.03),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                                size: textScaler.scale(20),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: textScaler.scale(16),
                                      ),
                                    ),
                                    Text(
                                      suggestion.description,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: textScaler.scale(14),
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
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: Text(
                          'Something went wrong 😢: $error',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: textScaler.scale(14),
                          ),
                        ),
                      ),
                      emptyBuilder: (context) => Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: Text(
                          'No places found. Try another keyword.',
                          style: TextStyle(fontSize: textScaler.scale(14)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isMenuVisible ? 0 : -screenWidth * 0.6,
            top: 0,
            child: Container(
              width: screenWidth * 0.6,
              height: screenHeight * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.asset(
                        'assets/images/sidebar.png',
                        width: screenWidth * 0.6,
                        height: screenHeight * 0.16,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: screenWidth * 0.03,
                        top: screenHeight * 0.03,
                        child: Container(
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(
                                    _profileImage!,
                                    width: screenWidth * 0.15,
                                    height: screenWidth * 0.15,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    color: Colors.black,
                                    size: screenWidth * 0.08,
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.19,
                        top: screenHeight * 0.05,
                        child: Text(
                          'MUBS Locator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: textScaler.scale(18),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.19,
                        top: screenHeight * 0.09,
                        child: Text(
                          _userFullName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: textScaler.scale(14),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Urbanist',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Handle long names
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.03,
                      top: screenHeight * 0.02,
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/HomeScreen'),
                      child: Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.black,
                            size: textScaler.scale(24),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Home',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: textScaler.scale(16),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.03,
                      top: screenHeight * 0.02,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/ProfileScreen');
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: Colors.black,
                            size: textScaler.scale(24),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Profile Settings',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: textScaler.scale(16),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.03,
                      top: screenHeight * 0.02,
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/NotificationsScreen'),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: Colors.black,
                            size: textScaler.scale(24),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: textScaler.scale(16),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.03,
                      top: screenHeight * 0.02,
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/LocationSelectScreen'),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.black,
                            size: textScaler.scale(24),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Search Locations',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: textScaler.scale(16),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.03,
                      top: screenHeight * 0.02,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.exit_to_app,
                            color: Colors.black,
                            size: textScaler.scale(24),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: textScaler.scale(16),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Urbanist',
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

// _BuildingBottomSheetContent remains unchanged
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
    final textScaler = MediaQuery.textScalerOf(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              Text(
                widget.building.name,
                style: TextStyle(
                  fontSize: textScaler.scale(24),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Text(
                widget.building.description,
                style: TextStyle(
                  fontSize: textScaler.scale(16),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      icon: Icons.info_outline,
                      label: 'Details',
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      icon: Icons.directions,
                      label: 'Directions',
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Expanded(
                    child: _buildTabButton(
                      index: 2,
                      icon: Icons.feedback_outlined,
                      label: 'Feedback',
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
              _buildTabContent(),
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
    final textScaler = MediaQuery.textScalerOf(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.015,
          horizontal: MediaQuery.of(context).size.width * 0.02,
        ),
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
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.03,
                right: MediaQuery.of(context).size.width * 0.01,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: textScaler.scale(20),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: textScaler.scale(12),
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
    final textScaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: textScaler.scale(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        Text(
          widget.building.description,
          style: TextStyle(
            fontSize: textScaler.scale(14),
            height: 1.5,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.025),
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location Coordinates',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: textScaler.scale(14),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
              Text(
                'Lat: ${widget.building.location.latitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: textScaler.scale(12),
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Long: ${widget.building.location.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: textScaler.scale(12),
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionsContent() {
    final textScaler = MediaQuery.textScalerOf(context);
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.navigation,
            size: textScaler.scale(48),
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          Text(
            'Get Directions',
            style: TextStyle(
              fontSize: textScaler.scale(18),
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            'Navigate to ${widget.building.name}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: textScaler.scale(14),
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.025),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onDirectionsTap();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    size: textScaler.scale(20),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Text(
                    'Start Navigation',
                    style: TextStyle(
                      fontSize: textScaler.scale(16),
                      fontWeight: FontWeight.w600,
                    ),
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
    final textScaler = MediaQuery.textScalerOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submit Feedback',
          style: TextStyle(
            fontSize: textScaler.scale(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        Text(
          'Issue Type',
          style: TextStyle(
            fontSize: textScaler.scale(14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedIssueType,
              isExpanded: true,
              items: _issueTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(fontSize: textScaler.scale(14)),
                  ),
                );
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        Text(
          'Issue Title',
          style: TextStyle(
            fontSize: textScaler.scale(14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        TextField(
          controller: _issueTitleController,
          decoration: InputDecoration(
            hintText: 'Enter a brief title for the issue',
            hintStyle: TextStyle(fontSize: textScaler.scale(14)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.03,
              vertical: MediaQuery.of(context).size.height * 0.015,
            ),
          ),
          style: TextStyle(fontSize: textScaler.scale(14)),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        Text(
          'Description',
          style: TextStyle(
            fontSize: textScaler.scale(14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the issue in detail...',
            hintStyle: TextStyle(fontSize: textScaler.scale(14)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.03,
              vertical: MediaQuery.of(context).size.height * 0.015,
            ),
          ),
          style: TextStyle(fontSize: textScaler.scale(14)),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.025),
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
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Submit Feedback',
              style: TextStyle(
                fontSize: textScaler.scale(16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}