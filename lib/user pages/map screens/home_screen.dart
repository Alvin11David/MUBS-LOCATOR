import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mubs_locator/models/building_model.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mubs_locator/repository/building_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:get/get.dart';
import '../../services/navigation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:mubs_locator/components/bottom_navbar.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LatLng _mubsMaingate = const LatLng(
    0.32626314488423924,
    32.616607995731286,
  );
  final LatLng _mubsCentre = LatLng(0.3282482847196531, 32.61798173177951);
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();
  Set<Marker> markers = {};
  Set<Polygon> polygons = {};
  Set<Polyline> polylines = {};
  final String _googleApiKey = 'AIzaSyBTk9548rr1JiKe1guF1i8z2wqHV8CZjRA';
  List<Building> fetchedBuildings = [];
  bool searchActive = true;
  bool isNavigating = false;
  String _userFullName = 'User';
  bool _isMenuVisible = false;
  File? _profileImage;
  bool _isLoggingOut = false;
  bool _isBottomNavVisible = false;
  String? _profilePicUrl;

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
  StreamSubscription<Position>? _positionStream;

  BitmapDescriptor? smallMarkerIcon;

  @override
  void initState() {
    super.initState();
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(40, 40)), // Small size
      'assets/markers/small_marker.png',
    ).then((icon) {
      setState(() {
        smallMarkerIcon = icon;
      });
    });
    updateLastActiveTimestamp();
    fetchAllData();
    _initializePolygons();
    _fetchUserFullName();
    _loadProfileImage();
    //_listenToLocationChanges();
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: MediaQuery.textScalerOf(context).scale(15),
              fontFamily: 'Poppins',
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: MediaQuery.textScalerOf(context).scale(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _listenToLocationChanges() {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // meters
          ),
        ).listen((Position position) {
          final userMarker = Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          );
          setState(() {
            markers.removeWhere((m) => m.markerId.value == 'user_location');
            markers.add(userMarker);
            mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude),
              ),
            );
          });
        });
  }

  Future<void> updateLastActiveTimestamp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'lastActiveTimestamp': Timestamp.now()},
      );
    }
  }

  void _showCustomSnackBar(
    BuildContext context,
    String message, {
    bool isSuccess = false,
  }) {
    print('Showing SnackBar: $message');
    final screenWidth = MediaQuery.of(context).size.width;
    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSuccess ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/logo/logo.png',
              width: screenWidth * 0.08,
              height: screenWidth * 0.08,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(width: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        top: 10,
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).size.height - 100,
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.transparent,
      elevation: 0,
      onVisible: () {
        print('SnackBar is visible: $message');
      },
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      print('SnackBar closed: $message, reason: $reason');
    });
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
          final profilePicUrl = userData['profilePicUrl'] as String?;
          if (mounted) {
            setState(() {
              _userFullName = fullName != null && fullName.isNotEmpty
                  ? fullName
                  : 'User';
              _profilePicUrl = profilePicUrl;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userFullName = 'User';
              _profilePicUrl = null;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userFullName = 'User';
            _profilePicUrl = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching user full name: $e');
      if (mounted) {
        setState(() {
          _userFullName = 'User';
          _profilePicUrl = null;
        });
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profileImagePath');
    if (imagePath != null && mounted) {
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

  List<Marker> processBuildings(List<Building> buildings) {
    return buildings.map((element) {
      print(
        "📍 Adding marker for: ${element.name} at ${element.location.latitude}, ${element.location.longitude}",
      );
      return Marker(
        markerId: MarkerId(element.id),
        position: LatLng(element.location.latitude, element.location.longitude),
        infoWindow: InfoWindow(
          title: element.name,
          snippet: element.description,
        ),
        icon:
            smallMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () {
          _showBuildingBottomSheet(context, buildingName: element.name);
        },
      );
    }).toList();
  }

  Future<void> _showUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog asking user to enable location
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable Location'),
            content: const Text(
              'Location services are disabled. Please turn on location to use this feature.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openLocationSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showCustomSnackBar(context, 'Location permission denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showCustomSnackBar(context, 'Location permission permanently denied.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    setState(() {
      markers.removeWhere((m) => m.markerId.value == 'user_location');
      markers.add(userMarker);
      mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    });
  }

  Future<void> fetchAllData() async {
    try {
      BuildingRepository buildingRepository = BuildingRepository();
      final buildings = await buildingRepository.getAllBuildings();
      print("✅ Fetched buildings: ${buildings.length}");
      final processedMarkers = processBuildings(buildings);
      if (mounted) {
        setState(() {
          fetchedBuildings.addAll(buildings);
          markers.addAll(processedMarkers);
        });
      }
      print("✅ Markers added: ${processedMarkers.length}");
    } catch (e, stackTrace) {
      print("❌ Failed to fetch buildings: $e");
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> createTheBuildings() async {
    try {
      List<Building> buildings =
          mubsBuildings; // Ensure mubsBuildings is defined
      BuildingRepository buildingRepository = BuildingRepository();
      for (var item in buildings) {
        await buildingRepository.addBuilding(item);
      }
    } catch (e) {
      print('Error creating buildings: $e');
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        _showCustomSnackBar(context, 'Logout successful', isSuccess: true);
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacementNamed(context, '/SignInScreen');
      }
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        _showCustomSnackBar(context, 'Error signing out: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
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
              onPressed: _isLoggingOut
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _logout();
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

  void _showBuildingBottomSheet(
    BuildContext context, {
    required String buildingName,
  }) {
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
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _BuildingBottomSheetContent(
                    buildingName: buildingName,
                    scrollController: scrollController,
                    onDirectionsTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/LocationSelectScreen',
                        arguments: {'buildingName': buildingName},
                      );
                    },
                    onFeedbackSubmit: (a, b, c) {},
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  BitmapDescriptor getRandomDefaultMarkerHue() {
    final List<double> hues = [
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueYellow,
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueCyan,
      BitmapDescriptor.hueAzure,
      BitmapDescriptor.hueBlue,
      BitmapDescriptor.hueViolet,
      BitmapDescriptor.hueMagenta,
      BitmapDescriptor.hueRose,
    ];
    final math.Random random = math.Random();
    final int randomIndex = random.nextInt(hues.length);
    return BitmapDescriptor.defaultMarkerWithHue(hues[randomIndex]);
  }

  Future<void> _navigateToBuilding(Building building) async {
    if (mapController != null) {
      LatLng buildingLocation = LatLng(
        building.location.latitude,
        building.location.longitude,
      );
      markers.removeWhere((marker) => marker.markerId.value == 'destination');
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
      if (mounted) {
        setState(() {
          isNavigating = true;
        });
      }
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
          if (mounted) {
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

  void _clearSearchBar() {
    searchController.clear();
    if (mounted) {
      setState(() {
        searchActive = false;
      });
    }
  }

  void _endNavigation() {
    if (mounted) {
      setState(() {
        polylines.clear();
        isNavigating = false;
      });
    }
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
          icon: Icon(Icons.menu, size: textScaler.scale(24)),
          onPressed: _toggleMenu,
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                      .collection('feedback')
                      .where(
                        'userEmail',
                        isEqualTo: FirebaseAuth.instance.currentUser!.email,
                      )
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
                    target: _mubsCentre,
                    zoom: 17,
                  ),
                  markers: markers,
                  polygons: polygons,
                  polylines: isNavigating ? polylines : {},
                  mapType: MapType.normal,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                ),
                ...fetchedBuildings.map((building) {
                  if (mapController == null) return SizedBox.shrink();
                  return FutureBuilder<ScreenCoordinate>(
                    future: mapController!.getScreenCoordinate(
                      LatLng(
                        building.location.latitude,
                        building.location.longitude,
                      ),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return SizedBox.shrink();
                      final screenCoordinate = snapshot.data!;
                      return Positioned(
                        left: screenCoordinate.x.toDouble() + 24,
                        top: screenCoordinate.y.toDouble() - 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            building.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
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
                                      setState(() {
                                        searchActive = true;
                                      });
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
                            setState(() {
                              searchActive = true;
                            });
                          },
                        );
                      },
                      suggestionsCallback: (pattern) async {
                        if (pattern.isEmpty) return [];
                        // Fetch all buildings (or a reasonable subset if your dataset is large)
                        final querySnapshot = await FirebaseFirestore.instance
                            .collection('buildings')
                            .get();

                        final buildings = querySnapshot.docs
                            .map(
                              (doc) => Building.fromFirestore(
                                doc.data(),
                                doc.id,
                              ),
                            )
                            .toList();

                        // Filter by any part of name, case-insensitive
                        final lowerPattern = pattern.toLowerCase();
                        return buildings
                            .where(
                              (building) => building.name
                                  .toLowerCase()
                                  .contains(lowerPattern),
                            )
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
                                        color: const Color.fromARGB(
                                          255,
                                          250,
                                          250,
                                          250,
                                        ),
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
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return Stack(
                              children: [
                                _BuildingBottomSheetContent(
                                  buildingName: suggestion.name,
                                  scrollController: ScrollController(),
                                  onDirectionsTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(
                                      context,
                                      '/LocationSelectScreen',
                                      arguments: {
                                        'buildingName': suggestion.name,
                                      },
                                    );
                                  },
                                  onFeedbackSubmit:
                                      (issueType, issueTitle, description) {
                                        // Add your feedback logic here
                                      },
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).pop(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
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
                      emptyBuilder: (context) {
                        if (!searchActive) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          child: Text(
                            'No places found. Try another keyword.',
                            style: TextStyle(
                              fontSize: textScaler.scale(14),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        );
                      },
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
                                child:
                                    _profilePicUrl != null &&
                                        _profilePicUrl!.isNotEmpty
                                    ? Image.network(
                                        _profilePicUrl!,
                                        width: screenWidth * 0.14,
                                        height: screenWidth * 0.14,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.person,
                                                  color: Colors.black
                                                      .withOpacity(0.8),
                                                  size: screenWidth * 0.07,
                                                ),
                                      )
                                    : (_profileImage != null
                                          ? Image.file(
                                              _profileImage!,
                                              width: screenWidth * 0.14,
                                              height: screenWidth * 0.14,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(
                                              Icons.person,
                                              color: Colors.black.withOpacity(
                                                0.8,
                                              ),
                                              size: screenWidth * 0.07,
                                            )),
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
                          onTap: () =>
                              Navigator.pushNamed(context, '/FeedbackScreen'),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_rounded,
                                color: Colors.black,
                                size: textScaler.scale(20),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Feedback & Reports',
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
          if (isNavigating)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _endNavigation,
                child: Text(
                  'End Navigation',
                  style: TextStyle(
                    fontSize: textScaler.scale(16),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),

          // Rectangle handle to show navbar
          if (!_isBottomNavVisible)
            Positioned(
              bottom: screenHeight * 0.03,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isBottomNavVisible = true;
                  });
                },
                child: Container(
                  width: screenWidth * 0.13,
                  height: screenHeight * 0.025,
                  decoration: BoxDecoration(
                    color: Colors.blue[300],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: textScaler.scale(18),
                    ),
                  ),
                ),
              ),
            ),

          // Animated BottomNavBar
          AnimatedPositioned(
            duration: Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            left: 0,
            right: 0,
            bottom: _isBottomNavVisible ? 0 : -screenHeight * 0.12,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 0) {
                  // Swipe down to hide navbar
                  setState(() {
                    _isBottomNavVisible = false;
                  });
                }
              },
              child: BottomNavBar(
                initialIndex: 0, // or your preferred index
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
  final String buildingName;
  final ScrollController scrollController;
  final VoidCallback onDirectionsTap;

  final Function(String, String, String) onFeedbackSubmit;

  const _BuildingBottomSheetContent({
    required this.buildingName,
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
  bool _isCheckingPermissions = false;
  final NavigationService _navigationService = Get.find<NavigationService>();
  bool showDetails = true;
  late Future<QuerySnapshot> _buildingFuture; // <-- Add this

  @override
  void initState() {
    super.initState();
    _buildingFuture = FirebaseFirestore.instance
        .collection('buildings')
        .where('name', isEqualTo: widget.buildingName)
        .limit(1)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final textScaler = MediaQuery.textScalerOf(context);

    return FutureBuilder<QuerySnapshot>(
      future: _buildingFuture, // <-- Use the cached future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No details available.',
              style: TextStyle(
                fontSize: textScaler.scale(14),
                fontFamily: 'Poppins',
                color: Colors.grey[600],
              ),
            ),
          );
        }
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showDetails = true;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.10,
                          vertical: screenHeight * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color: showDetails ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Text(
                          'Details',
                          style: TextStyle(
                            color: showDetails ? Colors.white : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showDetails = false;
                        });
                        _handleStartNavigation();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.012,
                        ),
                        decoration: BoxDecoration(
                          color: !showDetails ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Text(
                          'Get Directions',
                          style: TextStyle(
                            color: !showDetails ? Colors.white : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Divider(
                  thickness: 1.5,
                  color: Colors.grey[300],
                  indent: screenWidth * 0.01,
                  endIndent: screenWidth * 0.01,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  data['name'] ?? '',
                  style: TextStyle(
                    fontSize: MediaQuery.textScalerOf(context).scale(16),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  data['description'] ?? '',
                  style: TextStyle(
                    fontSize: MediaQuery.textScalerOf(context).scale(14),
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Divider(
                  thickness: 1.5,
                  color: Colors.grey[300],
                  indent: screenWidth * 0.01,
                  endIndent: screenWidth * 0.01,
                ),
                SizedBox(height: screenHeight * 0.01),

                // Only show images and details if showDetails is true
                if (showDetails) ...[
                  Text(
                    'Image Section',
                    style: TextStyle(
                      fontSize: MediaQuery.textScalerOf(context).scale(16),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Builder(
                    builder: (context) {
                      final imageUrls = (data['imageUrls'] as List?) ?? [];
                      Widget buildImage(String? url, double radius) {
                        if (url == null || url.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            child: Center(
                              child: Text(
                                'No Image',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Text(
                                      'No Image',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First image (large, left)
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: screenHeight * 0.30,
                              child: buildImage(
                                imageUrls.isNotEmpty ? imageUrls[0] : null,
                                30, // Large radius for left image
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Second and third images (stacked, right)
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                Container(
                                  height: (screenHeight * 0.22 - 3) / 1.5,
                                  width: (screenWidth * 0.34),
                                  margin: EdgeInsets.only(bottom: 6),
                                  child: buildImage(
                                    imageUrls.length > 1 ? imageUrls[1] : null,
                                    12, // Smaller radius for column images
                                  ),
                                ),
                                SizedBox(
                                  height: (screenHeight * 0.22 - 3) / 1.5,
                                  width: (screenWidth * 0.34),
                                  child: buildImage(
                                    imageUrls.length > 2 ? imageUrls[2] : null,
                                    12, // Smaller radius for column images
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Divider(
                    thickness: 1.5,
                    color: Colors.grey[300],
                    indent: screenWidth * 0.01,
                    endIndent: screenWidth * 0.01,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Details Section',
                    style: TextStyle(
                      fontSize: MediaQuery.textScalerOf(context).scale(16),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.015,
                      horizontal: screenWidth * 0.03,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6),
                        _detailRow('Name', data['name']),
                        _detailRow('Description', data['description']),
                        _detailRow('MTN Number', data['mtnNumber']),
                        _detailRow('Airtel Number', data['airtelNumber']),
                        if (data['openingHours'] != null &&
                            data['openingHours'] is List) ...[
                          SizedBox(height: 8),
                          Text(
                            'Opening Hours',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          ...((data['openingHours'] as List).map((entry) {
                            final days =
                                (entry['days'] as List?)?.join(', ') ?? '';
                            final start = entry['startTime'] ?? '';
                            final end = entry['endTime'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '$days: $start - $end',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.blueGrey[800],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            );
                          })),
                        ],
                      ],
                    ),
                  ),
                ],
                if (!showDetails) ...[
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'You can now navigate to this building using the button below.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
      Navigator.pop(context);
      widget.onDirectionsTap();
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

  Widget _detailRow(String label, String? value) {
    final textScaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: textScaler.scale(15),
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: textScaler.scale(13),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
