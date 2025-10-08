import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
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
  final LatLng _mubsMaingate = const LatLng(0.32626314488423924, 32.616607995731286);
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();

  Set<Marker> markers = {};
  Set<Polygon> polygons = {};
  Set<Polyline> polylines = {};
  final String _googleApiKey = 'AIzaSyBTk9548rr1JiKe1guF1i8z2wqHV8CZjRA';
  List<Building> fetchedBuildings = [];
  String _userFullName = 'User';
  bool _isMenuVisible = false;
  File? _profileImage;

  final List<LatLng> _mubsBounds = const [
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
    _loadProfileImage();
  }

  Future<void> _fetchUserFullName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
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
            }
          } else {
            if (mounted) {
              setState(() {
                _userFullName = 'User';
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _userFullName = 'User';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userFullName = 'User';
          });
        }
      }
    } catch (e) {
      print('Error fetching user full name: $e');
      if (mounted) {
        setState(() {
          _userFullName = 'User';
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

  Future<void> _markFeedbackAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final feedbackDocs = await FirebaseFirestore.instance
            .collection('feedback')
            .where('userEmail', isEqualTo: user.email)
            .where('adminReply', isNotEqualTo: '')
            .where('userRead', isEqualTo: false)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in feedbackDocs.docs) {
          batch.update(doc.reference, {'userRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking feedback as read: $e');
    }
  }

  void _initializeMarkers() {
    markers.add(
      Marker(
        markerId: const MarkerId('mubs_maingate'),
        position: _mubsMaingate,
        infoWindow: const InfoWindow(
          title: 'MUBS Maingate',
          snippet: 'Makerere University Business School',
        ),
      ),
    );
  }

  void _initializePolygons() {
    polygons.add(
      Polygon(
        polygonId: const PolygonId('mubs_campus'),
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
    } catch (e) {
      print("Failed to fetch buildings: $e");
      rethrow;
    }
  }

  Future<void> createTheBuildings() async {
    try {
      List<Building> buildings = mubsBuildings;
      BuildingRepository buildingRepository = BuildingRepository();

      for (var item in buildings) {
        await buildingRepository.addBuilding(item);
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
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/SignInScreen');
      }
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
            style: TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
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

      mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
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

    FirebaseFirestore.instance.collection('feedback').add({
      'userEmail': FirebaseAuth.instance.currentUser?.email ?? 'anonymous',
      'userName': _userFullName,
      'buildingName': building.name,
      'issueType': issueType,
      'issueTitle': issueTitle,
      'description': description,
      'timestamp': Timestamp.now(),
      'status': 'Submitted',
      'read': false,
      'userRead': false,
    });
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
            fontSize: textScaler.scale(16),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            size: textScaler.scale(24),
          ),
          onPressed: _toggleMenu,
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                    .collection('feedback')
                    .where('userEmail', isEqualTo: FirebaseAuth.instance.currentUser!.email)
                    .where('adminReply', isNotEqualTo: '')
                    .where('userRead', isEqualTo: false)
                    .snapshots()
                : Stream.empty(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      _markFeedbackAsRead();
                      Navigator.pushNamed(context, '/NotificationsScreen');
                    },
                    icon: Icon(
                      Icons.notifications_rounded,
                      size: textScaler.scale(24),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: textScaler.scale(16),
                        height: textScaler.scale(16),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: textScaler.scale(10),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
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
                          style: TextStyle(
                            fontSize: textScaler.scale(14),
                            fontFamily: 'Poppins',
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

                          final descriptionScore =
                              StringSimilarity.compareTwoStrings(
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
                          (a, b) => (b['score'] as double).compareTo(
                            a['score'] as double,
                          ),
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
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      suggestion.description,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: textScaler.scale(14),
                                        fontFamily: 'Poppins',
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
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      emptyBuilder: (context) => Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: Text(
                          'No places found. Try another keyword.',
                          style: TextStyle(
                            fontSize: textScaler.scale(14),
                            fontFamily: 'Poppins',
                          ),
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
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: screenWidth * 0.6,
                  height: screenHeight * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(2, 4),
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
                              width: screenWidth * 0.14,
                              height: screenWidth * 0.14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.7),
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child: _profileImage != null
                                    ? Image.file(
                                        _profileImage!,
                                        width: screenWidth * 0.14,
                                        height: screenWidth * 0.14,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: Colors.black.withOpacity(0.8),
                                        size: screenWidth * 0.07,
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
                                fontSize: textScaler.scale(15),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                          ),
                          Positioned(
                            left: screenWidth * 0.19,
                            top: screenHeight * 0.085,
                            child: Text(
                              _userFullName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: textScaler.scale(12),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Urbanist',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                          onTap: () =>
                              Navigator.pushNamed(context, '/HomeScreen'),
                          child: Row(
                            children: [
                              Icon(
                                Icons.home,
                                color: Colors.black,
                                size: textScaler.scale(20),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Home',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(14),
                                  fontWeight: FontWeight.w500,
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
                                size: textScaler.scale(20),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Profile Settings',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(14),
                                  fontWeight: FontWeight.w500,
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
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/NotificationsScreen',
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications,
                                color: Colors.black,
                                size: textScaler.scale(20),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(14),
                                  fontWeight: FontWeight.w500,
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
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/LocationSelectScreen',
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: textScaler.scale(20),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Search Locations',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(14),
                                  fontWeight: FontWeight.w500,
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
                                size: textScaler.scale(20),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(14),
                                  fontWeight: FontWeight.w500,
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final textScaler = MediaQuery.textScalerOf(context);

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: screenWidth * 0.1,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              widget.building.name,
              style: TextStyle(
                fontSize: textScaler.scale(20),
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              widget.building.description,
              style: TextStyle(
                fontSize: textScaler.scale(14),
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton('Details', 0),
                _buildTabButton('Feedback', 1),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            if (_selectedTabIndex == 0) ...[
              _buildDetailsTab(),
            ] else ...[
              _buildFeedbackTab(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final textScaler = MediaQuery.textScalerOf(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.height * 0.01,
        ),
        decoration: BoxDecoration(
          color: _selectedTabIndex == index
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: textScaler.scale(16),
            fontWeight: FontWeight.w500,
            color: _selectedTabIndex == index
                ? Theme.of(context).primaryColor
                : Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final textScaler = MediaQuery.textScalerOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Location',
              style: TextStyle(
                fontSize: textScaler.scale(16),
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            GestureDetector(
              onTap: widget.onDirectionsTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Get Directions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: textScaler.scale(14),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        Text(
          'Latitude: ${widget.building.location.latitude}',
          style: TextStyle(
            fontSize: textScaler.scale(14),
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          'Longitude: ${widget.building.location.longitude}',
          style: TextStyle(
            fontSize: textScaler.scale(14),
            fontFamily: 'Poppins',
          ),
        ),
        if (widget.building.otherNames != null &&
            widget.building.otherNames!.isNotEmpty) ...[
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Text(
            'Other Names',
            style: TextStyle(
              fontSize: textScaler.scale(16),
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          ...widget.building.otherNames!.map(
            (name) => Text(
              '- $name',
              style: TextStyle(
                fontSize: textScaler.scale(14),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeedbackTab() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final textScaler = MediaQuery.textScalerOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submit Feedback',
          style: TextStyle(
            fontSize: textScaler.scale(16),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        DropdownButtonFormField<String>(
          value: _selectedIssueType,
          decoration: InputDecoration(
            labelText: 'Issue Type',
            labelStyle: TextStyle(
              fontSize: textScaler.scale(14),
              fontFamily: 'Poppins',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: _issueTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(
                type,
                style: TextStyle(
                  fontSize: textScaler.scale(14),
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedIssueType = newValue!;
            });
          },
        ),
        SizedBox(height: screenHeight * 0.02),
        TextField(
          controller: _issueTitleController,
          decoration: InputDecoration(
            labelText: 'Issue Title',
            labelStyle: TextStyle(
              fontSize: textScaler.scale(14),
              fontFamily: 'Poppins',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(
            fontSize: textScaler.scale(14),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description',
            labelStyle: TextStyle(
              fontSize: textScaler.scale(14),
              fontFamily: 'Poppins',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          style: TextStyle(
            fontSize: textScaler.scale(14),
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              if (_issueTitleController.text.trim().isEmpty ||
                  _descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please fill in all fields',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
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
                SnackBar(
                  content: Text(
                    'Feedback submitted successfully',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Container(
              width: screenWidth * 0.3,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: textScaler.scale(14),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}