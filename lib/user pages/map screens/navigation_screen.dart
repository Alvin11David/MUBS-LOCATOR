import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/navigation_service.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng destination;
  final String destinationName;

  const NavigationScreen({
    Key? key,
    required this.destination,
    required this.destinationName,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final NavigationService _navigationService = Get.put(NavigationService());
  GoogleMapController? _mapController;
  bool _showStepsList = false;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  Future<void> _initializeNavigation() async {
    await _navigationService.startNavigation(widget.destination);
  }

  @override
  void dispose() {
    _navigationService.stopNavigation();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map view
          _buildMapView(),

          // Top navigation info card
          _buildTopNavigationCard(),

          // Current instruction card
          Obx(() => _navigationService.currentStep.value != null
              ? _buildCurrentInstructionCard()
              : const SizedBox.shrink()),

          // Bottom action buttons
          _buildBottomActions(),

          // Steps list overlay
          if (_showStepsList) _buildStepsListOverlay(),

          // Loading indicator
          Obx(() => _navigationService.isLoadingRoute.value
              ? _buildLoadingOverlay()
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Obx(() {
      final currentPos = _navigationService.currentPosition.value;
      
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentPos != null
              ? LatLng(currentPos.latitude, currentPos.longitude)
              : widget.destination,
          zoom: 17,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _updateCamera();
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        tiltGesturesEnabled: false,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        polylines: {
          if (_navigationService.routePolylinePoints.isNotEmpty)
            Polyline(
              polylineId: const PolylineId('route'),
              points: _navigationService.routePolylinePoints,
              color: Theme.of(context).primaryColor,
              width: 6,
              patterns: [
                PatternItem.dash(20),
                PatternItem.gap(10),
              ],
            ),
        },
        markers: {
          // Destination marker
          Marker(
            markerId: const MarkerId('destination'),
            position: widget.destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(title: widget.destinationName),
          ),
          // Current step marker
          if (_navigationService.currentStep.value != null)
            Marker(
              markerId: const MarkerId('currentStep'),
              position: _navigationService.currentStep.value!.endLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
        },
      );
    });
  }

  Widget _buildTopNavigationCard() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _showExitDialog();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                
                // Destination info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.destinationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _navigationService.getRemainingDistance(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_navigationService.totalDuration.value.toInt()} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentInstructionCard() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Obx(() {
            final step = _navigationService.currentStep.value;
            if (step == null) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Maneuver icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getManeuverIcon(step.maneuver),
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Distance to next step
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'In ${_navigationService.getRemainingDistance()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _getStepProgress(),
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Instruction text
                Text(
                  step.instruction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Step counter
                Obx(() => Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Step ${_navigationService.currentStepIndex.value + 1} of ${_navigationService.navigationSteps.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // View all steps button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showStepsList = true;
                  });
                },
                icon: const Icon(Icons.list, size: 20),
                label: const Text('View Steps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[800],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Recenter button
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _updateCamera,
                icon: const Icon(Icons.my_location),
                color: Theme.of(context).primaryColor,
                iconSize: 24,
              ),
            ),
            const SizedBox(width: 12),
            
            // End navigation button
            Container(
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showExitDialog,
                icon: const Icon(Icons.close),
                color: Colors.red,
                iconSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsListOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showStepsList = false;
          });
        },
        child: Container(
          color: Colors.black54,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping content
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Text(
                            'All Steps',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _showStepsList = false;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    
                    // Steps list
                    Expanded(
                      child: Obx(() => ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _navigationService.navigationSteps.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final step =
                                  _navigationService.navigationSteps[index];
                              final isCurrentStep =
                                  index ==
                                      _navigationService.currentStepIndex.value;
                              final isPastStep =
                                  index <
                                      _navigationService.currentStepIndex.value;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                color: isCurrentStep
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1)
                                    : Colors.transparent,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Step indicator
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isPastStep
                                            ? Colors.green
                                            : isCurrentStep
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey[300],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: isPastStep
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 20,
                                              )
                                            : Text(
                                                '${index + 1}',
                                                style: TextStyle(
                                                  color: isCurrentStep
                                                      ? Colors.white
                                                      : Colors.grey[600],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Step details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            step.instruction,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isCurrentStep
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isPastStep
                                                  ? Colors.grey[600]
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(step.distance).toInt()} m',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Maneuver icon
                                    Icon(
                                      _getManeuverIcon(step.maneuver),
                                      size: 20,
                                      color: isCurrentStep
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[400],
                                    ),
                                  ],
                                ),
                              );
                            },
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Calculating route...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  void _updateCamera() {
    final currentPos = _navigationService.currentPosition.value;
    if (currentPos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(currentPos.latitude, currentPos.longitude),
            zoom: 18,
            tilt: 45,
          ),
        ),
      );
    }
  }

  double _getStepProgress() {
    final step = _navigationService.currentStep.value;
    if (step == null) return 0.0;
    
    final remaining = _navigationService.distanceToNextStep.value;
    final total = step.distance;
    
    if (total == 0) return 1.0;
    return ((total - remaining) / total).clamp(0.0, 1.0);
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'straight':
        return Icons.straight;
      case 'ramp-left':
      case 'ramp-right':
        return Icons.merge;
      case 'fork-left':
      case 'fork-right':
        return Icons.call_split;
      case 'roundabout-left':
      case 'roundabout-right':
        return Icons.roundabout_left;
      default:
        return Icons.navigation;
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Navigation?'),
        content: const Text(
          'Are you sure you want to stop navigation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close navigation screen
            },
            child: const Text(
              'End Navigation',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}