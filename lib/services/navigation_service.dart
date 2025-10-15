import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class NavigationService extends GetxController {
  // Observable state variables
  final RxBool isNavigating = false.obs;
  final RxBool isLoadingRoute = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxList<LatLng> routePolylinePoints = <LatLng>[].obs;
  final RxList<NavigationStep> navigationSteps = <NavigationStep>[].obs;
  final Rx<NavigationStep?> currentStep = Rx<NavigationStep?>(null);
  final RxInt currentStepIndex = 0.obs;
  final RxDouble distanceToNextStep = 0.0.obs;
  final RxDouble totalDistance = 0.0.obs;
  final RxDouble totalDuration = 0.0.obs;
  final RxString errorMessage = ''.obs;

  // Google Maps API key - REPLACE WITH YOUR ACTUAL KEY
  final String _googleMapsApiKey = 'AIzaSyCEGBl8TYQLOGqw6qIgBu2bX43uz1WAzzw';

  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _destination;

  // Constants for navigation
  static const double _stepCompletionThreshold = 20.0; // meters
  static const double _routeDeviationThreshold = 50.0; // meters

  @override
  void onClose() {
    stopNavigation();
    super.onClose();
  }

  /// Check and request location permissions
  Future<bool> checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage.value =
          'Location services are disabled. Please enable them.';
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        errorMessage.value = 'Location permission denied.';
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      errorMessage.value =
          'Location permissions are permanently denied. Please enable them in settings.';
      return false;
    }

    return true;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = position;
      return position;
    } catch (e) {
      errorMessage.value = 'Error getting location: $e';
      return null;
    }
  }

  /// Fetch route from Google Directions API
  Future<bool> fetchRoute(LatLng origin, LatLng destination) async {
    try {
      isLoadingRoute.value = true;
      errorMessage.value = '';
      _destination = destination;

      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=walking&'
          'key=$_googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Extract total distance and duration
          totalDistance.value = (leg['distance']['value'] / 1000)
              .toDouble(); // km
          totalDuration.value = (leg['duration']['value'] / 60)
              .toDouble(); // minutes

          // Parse polyline points
          final List<PointLatLng> decodedPoints = PolylinePoints.decodePolyline(
            route['overview_polyline']['points'],
          );

          routePolylinePoints.value = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          // Parse navigation steps
          navigationSteps.value = (leg['steps'] as List)
              .map((step) => NavigationStep.fromJson(step))
              .toList();

          if (navigationSteps.isNotEmpty) {
            currentStep.value = navigationSteps[0];
            currentStepIndex.value = 0;
          }

          isLoadingRoute.value = false;
          return true;
        } else {
          errorMessage.value = 'Route not found: ${data['status']}';
          isLoadingRoute.value = false;
          return false;
        }
      } else {
        errorMessage.value = 'Failed to fetch route: ${response.statusCode}';
        isLoadingRoute.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error fetching route: $e';
      isLoadingRoute.value = false;
      return false;
    }
  }

  /// Start navigation with real-time location tracking
  Future<void> startNavigation(LatLng destination, {LatLng? origin, bool startTracking = false}) async {
    try {
      // Get current location
      final position = await getCurrentLocation();
      if (position == null) return;

      final origin = LatLng(position.latitude, position.longitude);

      // Fetch route
      final routeFetched = await fetchRoute(origin, destination);
      if (!routeFetched) return;

      // Start location tracking
      isNavigating.value = true;
      _startLocationTracking();
    } catch (e) {
      errorMessage.value = 'Error starting navigation: $e';
    }
  }

  /// Start tracking user location in real-time
  void _startLocationTracking() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            currentPosition.value = position;
            _updateNavigationState(position);
          },
          onError: (error) {
            errorMessage.value = 'Location tracking error: $error';
          },
        );
  }

  /// Update navigation state based on current location
  void _updateNavigationState(Position position) {
    if (!isNavigating.value || currentStep.value == null) return;

    final currentLatLng = LatLng(position.latitude, position.longitude);
    final stepEndLocation = currentStep.value!.endLocation;

    // Calculate distance to next step
    distanceToNextStep.value = Geolocator.distanceBetween(
      currentLatLng.latitude,
      currentLatLng.longitude,
      stepEndLocation.latitude,
      stepEndLocation.longitude,
    );

    // Check if step is completed
    if (distanceToNextStep.value < _stepCompletionThreshold) {
      _moveToNextStep();
    }

    // Check for route deviation
    _checkRouteDeviation(currentLatLng);
  }

  /// Move to the next navigation step
  void _moveToNextStep() {
    if (currentStepIndex.value < navigationSteps.length - 1) {
      currentStepIndex.value++;
      currentStep.value = navigationSteps[currentStepIndex.value];
    } else {
      // Navigation completed
      _completeNavigation();
    }
  }

  /// Check if user has deviated from the route
  void _checkRouteDeviation(LatLng currentLocation) {
    if (routePolylinePoints.isEmpty) return;

    // Find closest point on route
    double minDistance = double.infinity;
    for (var point in routePolylinePoints) {
      final distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    // If deviated significantly, recalculate route
    if (minDistance > _routeDeviationThreshold && _destination != null) {
      _recalculateRoute(currentLocation, _destination!);
    }
  }

  /// Recalculate route when user deviates
  Future<void> _recalculateRoute(LatLng origin, LatLng destination) async {
    print('Route deviation detected. Recalculating...');
    await fetchRoute(origin, destination);
  }

  /// Complete navigation
  void _completeNavigation() {
    isNavigating.value = false;
    _positionStreamSubscription?.cancel();
    // You can add a completion callback or notification here
  }

  /// Stop navigation
  void stopNavigation() {
    isNavigating.value = false;
    isLoadingRoute.value = false;
    _positionStreamSubscription?.cancel();
    routePolylinePoints.clear();
    navigationSteps.clear();
    currentStep.value = null;
    currentStepIndex.value = 0;
    distanceToNextStep.value = 0.0;
    _destination = null;
  }

  /// Get formatted instruction for current step
  String getCurrentInstruction() {
    if (currentStep.value == null) return '';
    return currentStep.value!.instruction;
  }

  /// Get remaining distance in human-readable format
  String getRemainingDistance() {
    if (distanceToNextStep.value < 1000) {
      return '${distanceToNextStep.value.toInt()} m';
    } else {
      return '${(distanceToNextStep.value / 1000).toStringAsFixed(1)} km';
    }
  }
}

/// Model class for navigation steps
class NavigationStep {
  final String instruction;
  final LatLng startLocation;
  final LatLng endLocation;
  final double distance; // in meters
  final double duration; // in seconds
  final String maneuver;

  NavigationStep({
    required this.instruction,
    required this.startLocation,
    required this.endLocation,
    required this.distance,
    required this.duration,
    required this.maneuver,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      instruction: json['html_instructions'].toString().replaceAll(
        RegExp(r'<[^>]*>'),
        '',
      ), // Remove HTML tags
      startLocation: LatLng(
        json['start_location']['lat'],
        json['start_location']['lng'],
      ),
      endLocation: LatLng(
        json['end_location']['lat'],
        json['end_location']['lng'],
      ),
      distance: json['distance']['value'].toDouble(),
      duration: json['duration']['value'].toDouble(),
      maneuver: json['maneuver'] ?? '',
    );
  }
}
