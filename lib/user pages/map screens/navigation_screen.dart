import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _steps = [];
  String _distanceText = '';
  String _durationText = '';
  bool _loading = true;

  // ...existing code...
  static const String _apiKey = 'AIzaSyCEGBl8TYQLOGqw6qIgBu2bX43uz1WAzzw';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAndShowRoute());
  }

  Future<void> _fetchAndShowRoute() async {
    debugPrint('🚀 Starting route fetch...');

    final originLatLng = widget.origin ?? widget.destination;
    final originStr = '${originLatLng.latitude},${originLatLng.longitude}';
    final destStr = '${widget.destination.latitude},${widget.destination.longitude}';

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
            const SnackBar(content: Text('No internet connection.')),
          );
        }
        setState(() => _loading = false);
        return;
      }

      final resp = await http.get(Uri.parse(url));
      debugPrint('📡 API Response Status: ${resp.statusCode}');
      debugPrint('📦 Full Response Body: ${resp.body}');

      if (resp.statusCode != 200) {
        debugPrint('❌ HTTP error ${resp.statusCode}');
        setState(() => _loading = false);
        return;
      }

      final data = json.decode(resp.body);
      debugPrint('✅ Received JSON response');

      if (data['status'] != 'OK') {
        debugPrint('❌ API Status not OK: ${data['status']}');
        debugPrint('❌ Error Message: ${data['error_message'] ?? 'No error message'}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not find route: ${data['status']}')),
          );
        }
        setState(() => _loading = false);
        return;
      }

      final routes = (data['routes'] as List);
      if (routes.isEmpty) {
        debugPrint('⚠️ No routes found in response');
        setState(() => _loading = false);
        return;
      }

      final route = routes[0];
      final legs = (route['legs'] as List);
      if (legs.isEmpty) {
        debugPrint('⚠️ No legs in route');
        setState(() => _loading = false);
        return;
      }

      final leg = legs[0];
      final polyEncoded = route['overview_polyline']?['points'] as String? ?? '';
      debugPrint('📏 Distance: ${leg['distance']?['text']}');
      debugPrint('⏱️ Duration: ${leg['duration']?['text']}');
      debugPrint('👣 Number of steps: ${(leg['steps'] as List).length}');

      final points = _decodePolyline(polyEncoded);
      debugPrint('📍 Decoded ${points.length} polyline points');

      final stepsList = (leg['steps'] as List).map((s) {
        final instructionRaw = (s['html_instructions'] ?? '').toString();
        final instruction = instructionRaw.replaceAll(RegExp(r'<[^>]*>'), '');
        final distance = (s['distance']?['text'] ?? '').toString();
        final duration = (s['duration']?['text'] ?? '').toString();
        debugPrint('➡️ Step: $instruction — $distance / $duration');
        return {
          'instruction': instruction,
          'distance': distance,
          'duration': duration,
        };
      }).toList();

      final poly = Polyline(
        polylineId: const PolylineId('route_poly'),
        points: points,
        color: Colors.blue,
        width: 5,
      );

      final originMarker = Marker(
        markerId: const MarkerId('origin'),
        position: originLatLng,
        infoWindow: InfoWindow(title: widget.originName ?? 'Start'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
      final destMarker = Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        infoWindow: InfoWindow(title: widget.destinationName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );

      setState(() {
        _polylines = {poly};
        _markers = {originMarker, destMarker};
        _steps = stepsList;
        _distanceText = leg['distance']?['text'] ?? '';
        _durationText = leg['duration']?['text'] ?? '';
        _loading = false;
      });

      if (_mapController != null && points.isNotEmpty) {
        final bounds = _computeBounds(points);
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
        debugPrint('🗺️ Map camera updated to bounds');
      }
    } catch (e) {
      debugPrint('❌ Error fetching route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching route: $e')),
        );
      }
      setState(() => _loading = false);
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
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < len);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      final latitude = lat / 1e5;
      final longitude = lng / 1e5;
      poly.add(LatLng(latitude, longitude));
    }
    return poly;
  }

  LatLngBounds _computeBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      if (minLat == null || p.latitude < minLat) minLat = p.latitude;
      if (maxLat == null || p.latitude > maxLat) maxLat = p.latitude;
      if (minLng == null || p.longitude < minLng) minLng = p.longitude;
      if (maxLng == null || p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  IconData _getDirectionIcon(String instruction) {
    final text = instruction.toLowerCase();
    if (text.contains('turn right') || text.contains('right')) {
      return Icons.turn_right;
    } else if (text.contains('turn left') || text.contains('left')) {
      return Icons.turn_left;
    } else if (text.contains('slight right')) {
      return Icons.turn_slight_right;
    } else if (text.contains('slight left')) {
      return Icons.turn_slight_left;
    } else if (text.contains('straight') || text.contains('head')) {
      return Icons.arrow_upward;
    } else if (text.contains('roundabout')) {
      return Icons.circle;
    } else if (text.contains('destination')) {
      return Icons.flag;
    } else {
      return Icons.directions_walk;
    }
  }

  void _showStepsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Text(
                    'Steps',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: _steps.length,
                      itemBuilder: (_, i) {
                        final s = _steps[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.12),
                            child: Icon(
                              _getDirectionIcon(s['instruction'] ?? ''),
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(s['instruction'] ?? ''),
                          subtitle: Text('${s['distance']} • ${s['duration']}'),
                        );
                      },
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

  void _stopNavigation() {
    debugPrint('⛔ Navigation stopped by user');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar with back arrow + destination name + distance/duration
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.destinationName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            if (_distanceText.isNotEmpty || _durationText.isNotEmpty)
              Text(
                '${_durationText.isNotEmpty ? _durationText + ' • ' : ''}${_distanceText}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: widget.destination, zoom: 16),
            onMapCreated: (c) {
              _mapController = c;
              if (_polylines.isNotEmpty) {
                final allPoints = _polylines.first.points;
                if (allPoints.isNotEmpty) {
                  final bounds = _computeBounds(allPoints);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    try {
                      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                    } catch (e) {
                      debugPrint('⚠️ animateCamera error: $e');
                    }
                  });
                }
              }
            },
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Center bottom Steps button
          if (!_loading)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: _steps.isNotEmpty ? _showStepsSheet : null,
                  icon: const Icon(Icons.list),
                  label: const Text('Steps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ),

          // Floating X stop button at bottom-right
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _stopNavigation,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.close),
            ),
          ),

          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}