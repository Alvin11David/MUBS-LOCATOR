import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class NavigationScreen extends StatefulWidget {
  final LatLng destination;
  final String destinationName;
  final LatLng? origin;
  final String? originName;

  const NavigationScreen({
    super.key,
    required this.destination,
    required this.destinationName,
    this.origin,
    this.originName,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  List<Map<String, dynamic>> _steps = [];
  String _distanceText = '';
  String _durationText = '';

  static const String _apiKey = 'AIzaSyCEGBl8TYQLOGqw6qIgBu2bX43uz1WAzzw';

  @override
  void initState() {
    super.initState();
    _fetchAndShowRoute();
  }

  Future<void> _fetchAndShowRoute() async {
    debugPrint('🚀 Starting route fetch...');

    final origin = widget.origin ?? widget.destination;
    final originStr = '${origin.latitude},${origin.longitude}';
    final destStr =
        '${widget.destination.latitude},${widget.destination.longitude}';

    debugPrint('📍 Origin: $originStr');
    debugPrint('🎯 Destination: $destStr');

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&mode=walking&key=$_apiKey';
    debugPrint('🌐 Fetching from URL: $url');

    try {
      if (!await _checkInternetConnection()) {
        debugPrint('❌ No internet connection');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No internet connection. Please check your network settings.',
              ),
            ),
          );
        }
        return;
      }

      final resp = await http.get(Uri.parse(url));
      debugPrint('📡 API Response Status: ${resp.statusCode}');
      debugPrint('📦 Full Response Body: ${resp.body}'); // Add this line

      if (resp.statusCode != 200) {
        debugPrint('❌ API Error: ${resp.statusCode} ${resp.body}');
        return;
      }

      final data = json.decode(resp.body);
      debugPrint('✅ Received JSON response');

      // Check the API status
      if (data['status'] != 'OK') {
        debugPrint('❌ API Status not OK: ${data['status']}');
        debugPrint(
          '❌ Error Message: ${data['error_message'] ?? 'No error message'}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not find route: ${data['status']}')),
          );
        }
        return;
      }

      if ((data['routes'] as List).isEmpty) {
        debugPrint('⚠️ No routes found in response');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No route found between these locations'),
            ),
          );
        }
        return;
      }

      // Validate coordinates are within reasonable bounds
      if (origin.latitude == 0 ||
          origin.longitude == 0 ||
          widget.destination.latitude == 0 ||
          widget.destination.longitude == 0) {
        debugPrint('⚠️ Invalid coordinates detected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid location coordinates')),
          );
        }
        return;
      }

      final route = data['routes'][0];
      final leg = route['legs'][0];

      debugPrint('📏 Distance: ${leg['distance']['text']}');
      debugPrint('⏱️ Duration: ${leg['duration']['text']}');
      debugPrint('👣 Number of steps: ${(leg['steps'] as List).length}');

      final points = _decodePolyline(
        route['overview_polyline']['points'] as String,
      );
      debugPrint('📍 Decoded ${points.length} polyline points');

      setState(() {
        _distanceText = leg['distance']['text'];
        _durationText = leg['duration']['text'];
        _steps = (leg['steps'] as List).map((s) {
          debugPrint('🚶 Step: ${s['html_instructions']}');
          return {
            'instruction': ((s['html_instructions'] ?? '') as String)
                .replaceAll(RegExp(r'<[^>]*>'), ''),
            'distance': (s['distance']['text'] ?? '').toString(),
            'duration': (s['duration']['text'] ?? '').toString(),
          };
        }).toList();

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ),
        };
        debugPrint('✅ Updated UI with route data');
      });

      if (_mapController != null && points.isNotEmpty) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points[0], 16),
        );
        debugPrint('🗺️ Map camera updated');
      }
    } catch (e) {
      debugPrint('❌ Error fetching route: $e');
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  IconData _getDirectionIcon(String instruction) {
    instruction = instruction.toLowerCase();
    if (instruction.contains('turn right')) {
      return Icons.turn_right;
    } else if (instruction.contains('turn left')) {
      return Icons.turn_left;
    } else if (instruction.contains('head')) {
      return Icons.straight;
    } else if (instruction.contains('destination')) {
      return Icons.place;
    } else if (instruction.contains('continue')) {
      return Icons.arrow_forward;
    } else if (instruction.contains('slight right')) {
      return Icons.turn_slight_right;
    } else if (instruction.contains('slight left')) {
      return Icons.turn_slight_left;
    } else {
      return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.destinationName} ($_distanceText, $_durationText)',
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.destination,
              zoom: 16,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('dest'),
                position: widget.destination,
              ),
              if (widget.origin != null)
                Marker(
                  markerId: const MarkerId('origin'),
                  position: widget.origin!,
                ),
            },
            polylines: _polylines,
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white.withOpacity(0.9),
              height: 180,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: _steps.map((s) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                      child: Icon(
                        _getDirectionIcon(s['instruction'] ?? ''),
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text(s['instruction'] ?? ''),
                    subtitle: Text('${s['distance']} • ${s['duration']}'),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
