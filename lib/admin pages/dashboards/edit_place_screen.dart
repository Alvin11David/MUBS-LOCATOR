import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mubs_locator/user%20pages/other%20screens/edit_profile_screen.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditPlaceScreen extends StatefulWidget {
  final String buildingId; // Pass the document ID to this screen

  const EditPlaceScreen({super.key, required this.buildingId});

  @override
  State<EditPlaceScreen> createState() => _EditPlaceScreenState();
}

class _EditPlaceScreenState extends State<EditPlaceScreen>
    with SingleTickerProviderStateMixin {
  String? _profilePicUrl; // <-- Use this for the profile picture
  bool _isDropdownVisible = false;
  bool _isMenuVisible = false;

  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _otherNamesController = TextEditingController();
  final TextEditingController _mtnNumberController = TextEditingController();
  final TextEditingController _airtelNumberController = TextEditingController();
  // Latitude / Longitude controllers (new)
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final FocusNode _buildingNameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _mtnNumberFocus = FocusNode();
  final FocusNode _airtelNumberFocus = FocusNode();

  LatLng _selectedLocation = const LatLng(
    0.32848299678238435,
    32.61717974633408,
  );
  GoogleMapController? _mapController;
  bool _isLocationSelected = false;
  List<XFile?> _images = [null, null, null, null];
  List<String> _imageUrls = [];
  List<String> _selectedDays = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  static const CameraPosition _mubsCenter = CameraPosition(
    target: LatLng(0.32848299678238435, 32.61717974633408),
    zoom: 16.0,
  );

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _fetchBuildingDetails();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          _profilePicUrl = doc.data()?['profilePicUrl'] as String?;
        });
      } catch (e) {
        print('Error loading profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile picture: $e')),
        );
      }
    }
  }

  Future<void> _fetchBuildingDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.buildingId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _buildingNameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _otherNamesController.text = data['otherNames'] ?? '';
          _selectedLocation = LatLng(
            (data['latitude'] ?? 0.32848299678238435) as double,
            (data['longitude'] ?? 32.61717974633408) as double,
          );
          // set lat/lng controllers to current values
          _latitudeController.text = _selectedLocation.latitude.toString();
          _longitudeController.text = _selectedLocation.longitude.toString();
          _isLocationSelected = true;
          _imageUrls = List<String>.from(data['imageUrls'] ?? []);
          _mtnNumberController.text = data['mtnNumber'] ?? '';
          _airtelNumberController.text = data['airtelNumber'] ?? '';
          _selectedDays = List<String>.from(data['days'] ?? []);
          if (data['startTime'] != null) {
            _startTime = TimeOfDay(
              hour: data['startTime']['hour'],
              minute: data['startTime']['minute'],
            );
          }
          if (data['endTime'] != null) {
            _endTime = TimeOfDay(
              hour: data['endTime']['hour'],
              minute: data['endTime']['minute'],
            );
          }
        });
      }
    } catch (e) {
      print('Error fetching building details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load building details: $e')),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/SignInScreen');
      }
    } catch (e) {
      print('Logout error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to log out: $e')));
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _isLocationSelected = true;
    });
    // update lat/lng fields when user taps map
    _latitudeController.text = position.latitude.toString();
    _longitudeController.text = position.longitude.toString();
    _mapController?.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
    await _updateFirestoreField({
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
    });
  }

  Future<void> _updateFirestoreField(Map<String, dynamic> fieldData) async {
    try {
      await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.buildingId)
          .update(fieldData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Field updated successfully')),
      );
    } catch (e) {
      print('Error updating Firestore: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update field: $e')));
    }
  }

  Future<void> _deleteImage(int index) async {
    if (index < _imageUrls.length) {
      final url = _imageUrls[index];
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
        setState(() {
          _imageUrls.removeAt(index);
        });
        await _updateFirestoreField({'imageUrls': _imageUrls});
      } catch (e) {
        print('Error deleting image: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete image: $e')));
      }
    }
  }

  Future<void> _addImage(int index) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _images[index] = pickedFile;
        });
        final storageRef = FirebaseStorage.instance.ref().child(
          'buildings/${widget.buildingId}/images/image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await storageRef.putFile(File(pickedFile.path));
        final url = await storageRef.getDownloadURL();
        setState(() {
          _imageUrls.add(url);
        });
        await _updateFirestoreField({'imageUrls': _imageUrls});
      }
    } catch (e) {
      print('Error adding image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add image: $e')));
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the building name';
    }
    final nameRegex = RegExp(r'^[a-zA-Z0-9\s\-,.&()]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, numbers, spaces, and -,.&()';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the description';
    }
    final descriptionRegex = RegExp(r'^[a-zA-Z0-9\s\-,.&()]+$');
    if (!descriptionRegex.hasMatch(value.trim())) {
      return 'Description can only contain letters, numbers, spaces, and -,.&()';
    }
    if (value.trim().length < 2) {
      return 'Description must be at least 2 characters long';
    }
    if (value.trim().length > 500) {
      return 'Description cannot exceed 500 characters';
    }
    return null;
  }

  String? _validateMtnNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter MTN number';
    }
    final mtnRegex = RegExp(r'^\+256(77|78|39)\d{7}$');
    if (!mtnRegex.hasMatch(value.trim())) {
      return 'Enter a valid MTN number (e.g., +25677XXXXXXX)';
    }
    return null;
  }

  String? _validateAirtelNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter Airtel number';
    }
    final airtelRegex = RegExp(r'^\+256(70|75)\d{7}$');
    if (!airtelRegex.hasMatch(value.trim())) {
      return 'Enter a valid Airtel number (e.g., +25670XXXXXXX)';
    }
    return null;
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _descriptionController.dispose();
    _otherNamesController.dispose();
    _mtnNumberController.dispose();
    _airtelNumberController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _buildingNameFocus.dispose();
    _descriptionFocus.dispose();
    _locationFocus.dispose();
    _mtnNumberFocus.dispose();
    _airtelNumberFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_isMenuVisible || _isDropdownVisible) {
              setState(() {
                _isMenuVisible = false;
                _isDropdownVisible = false;
              });
            }
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * 0.09,
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isMenuVisible = !_isMenuVisible;
                                  _isDropdownVisible = false;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Icon(
                                Icons.menu,
                                color: Colors.black,
                                size: screenWidth * 0.08,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            Text(
                              '${_getGreeting()}, $fullName',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: screenWidth * 0.17,
                              height: screenHeight * 0.05,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: screenWidth * 0.0,
                                    ),
                                    child: Container(
                                      width: screenWidth * 0.1,
                                      height: screenWidth * 0.1,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child:
                                          (_profilePicUrl != null &&
                                              _profilePicUrl!.isNotEmpty)
                                          ? ClipOval(
                                              child: Image.network(
                                                _profilePicUrl!,
                                                fit: BoxFit.cover,
                                                width: screenWidth * 0.09,
                                                height: screenWidth * 0.09,
                                                loadingBuilder:
                                                    (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return const CircularProgressIndicator();
                                                    },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.person,
                                                      color: Colors.black,
                                                      size: screenWidth * 0.04,
                                                    ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              color: Colors.black,
                                              size: screenWidth * 0.04,
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: screenWidth * 0.01,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isDropdownVisible =
                                              !_isDropdownVisible;
                                          _isMenuVisible = false;
                                        });
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.black,
                                        size: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Title and Navigation Arrows
              Positioned(
                top: screenHeight * 0.1,
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit a Place',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'You can make changes to all the fields\nbelow.',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.black,
                            size: screenWidth * 0.08,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.0),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: screenWidth * 0.08,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Form Fields
              Positioned(
                top: screenHeight * 0.21,
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
                bottom: 0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.04,
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Form(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                  ),
                                  child: BuildingNameField(
                                    controller: _buildingNameController,
                                    label: 'Building Name',
                                    hint: 'Enter Building Name',
                                    icon: Icons.location_city,
                                    focusNode: _buildingNameFocus,
                                    nextFocusNode: _descriptionFocus,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (value) {
                                      final error = _validateName(value);
                                      if (error == null) {
                                        _updateFirestoreField({
                                          'name': value.trim(),
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                  ),
                                  child: DescriptionField(
                                    controller: _descriptionController,
                                    label: 'Building Description',
                                    hint: 'Enter Place Description',
                                    icon: Icons.description,
                                    focusNode: _descriptionFocus,
                                    textInputAction: TextInputAction.next,
                                    nextFocusNode: _locationFocus,
                                    onChanged: (value) {
                                      final error = _validateDescription(value);
                                      if (error == null) {
                                        _updateFirestoreField({
                                          'description': value.trim(),
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                  ),
                                  child: TextFormField(
                                    controller: _otherNamesController,
                                    decoration: InputDecoration(
                                      labelText: 'Other Names',
                                      labelStyle: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        fontSize: screenWidth * 0.035,
                                      ),
                                      hintText: 'Enter other names (optional)',
                                      hintStyle: TextStyle(
                                        color: Colors.black.withOpacity(0.6),
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w400,
                                        fontSize: screenWidth * 0.028,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.edit,
                                        color: const Color(0xFF93C5FD),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide(
                                          color: Color(0xFF93C5FD),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide(
                                          color: Color(0xFF93C5FD),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 20,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      _updateFirestoreField({
                                        'otherNames': value.trim().isEmpty
                                            ? null
                                            : value.trim(),
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.00,
                                  ),
                                  child: LocationSelectField(
                                    controller: TextEditingController(),
                                    label: 'Location Select',
                                    hint: 'Tap on the map to select location',
                                    icon: Icons.location_on,
                                    focusNode: _locationFocus,
                                    textInputAction: TextInputAction.next,
                                    nextFocusNode: _mtnNumberFocus,
                                    selectedLocation: _selectedLocation,
                                    isLocationSelected: _isLocationSelected,
                                    onMapCreated: _onMapCreated,
                                    onTap: _onTap,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                // Latitude & Longitude editable fields
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _latitudeController,
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                signed: true,
                                                decimal: true,
                                              ),
                                          decoration: InputDecoration(
                                            labelText: 'Latitude',
                                            hintText: 'e.g. 0.3284829',
                                            prefixIcon: Icon(
                                              Icons.place,
                                              color: const Color(0xFF93C5FD),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF93C5FD),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF93C5FD),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          onFieldSubmitted: (value) async {
                                            final lat = double.tryParse(value);
                                            final lng = double.tryParse(
                                              _longitudeController.text,
                                            );
                                            if (lat != null && lng != null) {
                                              setState(() {
                                                _selectedLocation = LatLng(
                                                  lat,
                                                  lng,
                                                );
                                                _isLocationSelected = true;
                                              });
                                              _mapController?.animateCamera(
                                                CameraUpdate.newLatLng(
                                                  _selectedLocation,
                                                ),
                                              );
                                              await _updateFirestoreField({
                                                'latitude': lat,
                                                'longitude': lng,
                                              });
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Enter valid coordinates',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _longitudeController,
                                          keyboardType:
                                              TextInputType.numberWithOptions(
                                                signed: true,
                                                decimal: true,
                                              ),
                                          decoration: InputDecoration(
                                            labelText: 'Longitude',
                                            hintText: 'e.g. 32.6171797',
                                            prefixIcon: Icon(
                                              Icons.place,
                                              color: const Color(0xFF93C5FD),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF93C5FD),
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF93C5FD),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          onFieldSubmitted: (value) async {
                                            final lng = double.tryParse(value);
                                            final lat = double.tryParse(
                                              _latitudeController.text,
                                            );
                                            if (lat != null && lng != null) {
                                              setState(() {
                                                _selectedLocation = LatLng(
                                                  lat,
                                                  lng,
                                                );
                                                _isLocationSelected = true;
                                              });
                                              _mapController?.animateCamera(
                                                CameraUpdate.newLatLng(
                                                  _selectedLocation,
                                                ),
                                              );
                                              await _updateFirestoreField({
                                                'latitude': lat,
                                                'longitude': lng,
                                              });
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Enter valid coordinates',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.00,
                                  ),
                                  child: PhotosMediaField(
                                    imageUrls: _imageUrls,
                                    onImagesChanged: (images) {
                                      setState(() {
                                        _images = images;
                                      });
                                    },
                                    onAddImage: _addImage,
                                    onDeleteImage: _deleteImage,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.00,
                                  ),
                                  child: OpeningClosingHoursField(
                                    mtnNumberController: _mtnNumberController,
                                    airtelNumberController:
                                        _airtelNumberController,
                                    selectedDays: _selectedDays,
                                    startTime: _startTime,
                                    endTime: _endTime,
                                    onDaysChanged: (days) {
                                      setState(() {
                                        _selectedDays = days;
                                      });
                                      _updateFirestoreField({
                                        'days': _selectedDays,
                                      });
                                    },
                                    onTimeChanged: (start, end) {
                                      setState(() {
                                        _startTime = start;
                                        _endTime = end;
                                      });
                                      _updateFirestoreField({
                                        'startTime': start != null
                                            ? {
                                                'hour': start.hour,
                                                'minute': start.minute,
                                              }
                                            : null,
                                        'endTime': end != null
                                            ? {
                                                'hour': end.hour,
                                                'minute': end.minute,
                                              }
                                            : null,
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.00,
                                  ),
                                  child: ContactInformationField(
                                    mtnNumberController: _mtnNumberController,
                                    airtelNumberController:
                                        _airtelNumberController,
                                    mtnNumberFocus: _mtnNumberFocus,
                                    airtelNumberFocus: _airtelNumberFocus,
                                    onMtnChanged: (value) {
                                      final error = _validateMtnNumber(value);
                                      if (error == null) {
                                        _updateFirestoreField({
                                          'mtnNumber': value.trim(),
                                        });
                                      }
                                    },
                                    onAirtelChanged: (value) {
                                      final error = _validateAirtelNumber(
                                        value,
                                      );
                                      if (error == null) {
                                        _updateFirestoreField({
                                          'airtelNumber': value.trim(),
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.04),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Profile Dropdown
              if (_isDropdownVisible)
                Positioned(
                  top: screenHeight * 0.09,
                  right: screenWidth * 0.04,
                  child: Container(
                    width: screenWidth * 0.25,
                    height: screenHeight * 0.06,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.01,
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                              if (result != null &&
                                  result is Map<String, dynamic>) {
                                setState(() {
                                  _profilePicUrl =
                                      result['imageUrl'] as String?;
                                  _isDropdownVisible = false;
                                });
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/edit.png',
                                  color: Colors.black,
                                  width: screenWidth * 0.04,
                                  height: screenWidth * 0.04,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Sidebar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _isMenuVisible ? 0 : -screenWidth * 0.6,
                top: MediaQuery.of(context).padding.top,
                child: Container(
                  width: screenWidth * 0.6,
                  height: screenHeight * 0.8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: Offset(2, 0),
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
                            left: screenWidth * 0.0,
                            top: screenHeight * 0.03,
                            child: Container(
                              width: screenWidth * 0.15,
                              height: screenWidth * 0.15,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                              child:
                                  (_profilePicUrl != null &&
                                      _profilePicUrl!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        _profilePicUrl!,
                                        fit: BoxFit.cover,
                                        width: screenWidth * 0.15,
                                        height: screenWidth * 0.15,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const CircularProgressIndicator();
                                            },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.person,
                                                  color: Colors.black,
                                                  size: screenWidth * 0.08,
                                                ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      color: Colors.black,
                                      size: screenWidth * 0.08,
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
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                          ),
                          Positioned(
                            left: screenWidth * 0.19,
                            top: screenHeight * 0.09,
                            child: Text(
                              fullName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Urbanist',
                              ),
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
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Dashboard row tapped');
                            Navigator.pushNamed(
                              context,
                              '/AdminDashboardScreen',
                            );
                            setState(() {
                              _isMenuVisible = false;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.dashboard,
                                color: Colors.black,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Dashboard',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
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
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Feedback & Reports row tapped');
                            Navigator.pushNamed(context, '/FeedbackListScreen');
                            setState(() {
                              _isMenuVisible = false;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat,
                                color: Colors.black,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Feedback & Reports',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
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
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            print('Profile Settings row tapped');
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                            if (result != null &&
                                result is Map<String, dynamic>) {
                              setState(() {
                                _profilePicUrl = result['imageUrl'] as String?;
                                _isMenuVisible = false;
                              });
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Colors.black,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Profile Settings',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
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
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Push Notifications row tapped');
                            Navigator.pushNamed(
                              context,
                              '/SendNotificationsScreen',
                            );
                            setState(() {
                              _isMenuVisible = false;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.notifications,
                                color: Colors.black,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Push Notifications',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
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
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Locations row tapped');
                            Navigator.pushNamed(
                              context,
                              '/LocationManagementScreen',
                            );
                            setState(() {
                              _isMenuVisible = false;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Locations',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
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
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Logout row tapped');
                            _logout();
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.exit_to_app,
                                color: Colors.black,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
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
        ),
      ),
    );
  }
}

class BuildingNameField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;
  final Function(String) onChanged;

  const BuildingNameField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focusNode,
    this.nextFocusNode,
    required this.textInputAction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.text,
          focusNode: focusNode,
          textInputAction: textInputAction,
          enabled: true,
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05,
            ),
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: screenWidth * 0.045,
            ),
            fillColor: const Color.fromARGB(255, 237, 236, 236),
            filled: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: Icon(
                icon,
                color: const Color.fromARGB(255, 69, 141, 224),
                size: screenWidth * 0.06,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.05,
              horizontal: screenWidth * 0.05,
            ),
          ),
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: screenWidth * 0.045,
          ),
          cursorColor: const Color(0xFF3B82F6),
        );
      },
    );
  }
}

class DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;
  final Function(String) onChanged;

  const DescriptionField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focusNode,
    this.nextFocusNode,
    required this.textInputAction,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          focusNode: focusNode,
          textInputAction: textInputAction,
          enabled: true,
          maxLines: 4,
          minLines: 3,
          maxLength: 500,
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05,
            ),
            floatingLabelAlignment: FloatingLabelAlignment.start,
            alignLabelWithHint: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: screenWidth * 0.045,
            ),
            fillColor: const Color.fromARGB(255, 237, 236, 236),
            filled: true,
            prefixIcon: Align(
              widthFactor: 1.0,
              heightFactor: 1.0,
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.08,
                  top: screenWidth * 0.005,
                ),
                child: Icon(
                  icon,
                  color: const Color.fromARGB(255, 69, 141, 224),
                  size: screenWidth * 0.06,
                ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.08,
              horizontal: screenWidth * 0.05,
            ),
            counterStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: screenWidth * 0.035,
              color: Colors.grey,
            ),
          ),
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: screenWidth * 0.045,
          ),
          cursorColor: const Color(0xFF3B82F6),
        );
      },
    );
  }
}

class LocationSelectField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final FocusNode? nextFocusNode;
  final LatLng selectedLocation;
  final bool isLocationSelected;
  final void Function(GoogleMapController) onMapCreated;
  final void Function(LatLng) onTap;

  const LocationSelectField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focusNode,
    required this.textInputAction,
    this.nextFocusNode,
    required this.selectedLocation,
    required this.isLocationSelected,
    required this.onMapCreated,
    required this.onTap,
  });

  @override
  State<LocationSelectField> createState() => _LocationSelectFieldState();
}

class _LocationSelectFieldState extends State<LocationSelectField> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = MediaQuery.of(context).size.height;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                bottom: screenHeight * 0.01,
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.88,
                maxHeight: screenHeight * 0.25,
                minHeight: screenHeight * 0.2,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 237, 236, 236),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: widget.selectedLocation,
                          zoom: 16.0,
                        ),
                        onMapCreated: widget.onMapCreated,
                        onTap: widget.onTap,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        markers: {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: widget.selectedLocation,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                            infoWindow: InfoWindow(
                              title: widget.isLocationSelected
                                  ? 'Selected Location'
                                  : 'Tap to select location',
                              snippet:
                                  '${widget.selectedLocation.latitude.toStringAsFixed(6)}, ${widget.selectedLocation.longitude.toStringAsFixed(6)}',
                            ),
                          ),
                        },
                        mapType: MapType.normal,
                        compassEnabled: true,
                        zoomControlsEnabled: true,
                        scrollGesturesEnabled: true,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                      ),
                      if (!widget.isLocationSelected)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.icon,
                                    color: Colors.white,
                                    size: screenWidth * 0.12,
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  Text(
                                    widget.hint,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.isLocationSelected)
              Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05,
                  top: screenHeight * 0.01,
                ),
                child: Text(
                  'Selected: ${widget.selectedLocation.latitude.toStringAsFixed(6)}, ${widget.selectedLocation.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PhotosMediaField extends StatefulWidget {
  final Function(List<XFile?>) onImagesChanged;
  final List<String> imageUrls;
  final Future<void> Function(int) onAddImage;
  final Future<void> Function(int) onDeleteImage;

  const PhotosMediaField({
    super.key,
    required this.onImagesChanged,
    required this.imageUrls,
    required this.onAddImage,
    required this.onDeleteImage,
  });

  @override
  State<PhotosMediaField> createState() => _PhotosMediaFieldState();
}

class _PhotosMediaFieldState extends State<PhotosMediaField> {
  final List<XFile?> _images = [null, null, null, null];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = MediaQuery.of(context).size.height;

        final totalImages =
            widget.imageUrls.length +
            _images.where((img) => img != null).length;
        final gridCount = totalImages < 4 ? 4 : totalImages;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                bottom: screenHeight * 0.01,
              ),
              child: Text(
                'Photos & Media',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.88,
                maxHeight: screenHeight * 0.25,
                minHeight: screenHeight * 0.2,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 237, 236, 236),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.03,
                      mainAxisSpacing: screenHeight * 0.015,
                      childAspectRatio: 1.5,
                      shrinkWrap: true,
                      children: List.generate(gridCount, (index) {
                        if (index < widget.imageUrls.length) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.imageUrls[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error);
                                  },
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => widget.onDeleteImage(index),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          final imgIndex = index - widget.imageUrls.length;
                          return GestureDetector(
                            onTap: () => widget.onAddImage(imgIndex),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF93C5FD),
                                  width: 1,
                                ),
                              ),
                              child: _images[imgIndex] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_images[imgIndex]!.path),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.add,
                                          color: const Color(0xFF93C5FD),
                                          size: screenWidth * 0.06,
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OpeningClosingHoursField extends StatefulWidget {
  final TextEditingController mtnNumberController;
  final TextEditingController airtelNumberController;
  final List<String> selectedDays;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Function(List<String>) onDaysChanged;
  final Function(TimeOfDay?, TimeOfDay?) onTimeChanged;

  const OpeningClosingHoursField({
    super.key,
    required this.mtnNumberController,
    required this.airtelNumberController,
    required this.selectedDays,
    required this.startTime,
    required this.endTime,
    required this.onDaysChanged,
    required this.onTimeChanged,
  });

  @override
  State<OpeningClosingHoursField> createState() =>
      _OpeningClosingHoursFieldState();
}

class _OpeningClosingHoursFieldState extends State<OpeningClosingHoursField> {
  late List<String> _selectedDays;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = List<String>.from(widget.selectedDays);
    _startTime = widget.startTime;
    _endTime = widget.endTime;
    _daysController.text = _getDaysText();
    _timeController.text = (_startTime != null && _endTime != null)
        ? '${_startTime!.format(context)}–${_endTime!.format(context)}'
        : '';
  }

  void _toggleDaySelection(String day, bool isSecondTap) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        if (isSecondTap && _selectedDays.isNotEmpty) {
          int startIndex = _daysOfWeek.indexOf(_selectedDays.last);
          int endIndex = _daysOfWeek.indexOf(day);
          if (startIndex > endIndex) {
            final temp = startIndex;
            startIndex = endIndex;
            endIndex = temp;
          }
          _selectedDays.clear();
          for (int i = startIndex; i <= endIndex; i++) {
            _selectedDays.add(_daysOfWeek[i]);
          }
        } else {
          _selectedDays.add(day);
        }
      }
      _daysController.text = _getDaysText();
      widget.onDaysChanged(_selectedDays);
    });
  }

  String _getDaysText() {
    if (_selectedDays.isEmpty) return 'Select days';
    if (_selectedDays.length == 2 &&
        _selectedDays.contains('Saturday') &&
        _selectedDays.contains('Sunday')) {
      return 'Weekends';
    }
    if (_selectedDays.length == 1) return _selectedDays.first;
    final indices =
        _selectedDays.map((day) => _daysOfWeek.indexOf(day)).toList()..sort();
    bool isConsecutive = true;
    for (int i = 1; i < indices.length; i++) {
      if (indices[i] != indices[i - 1] + 1) {
        isConsecutive = false;
        break;
      }
    }
    if (isConsecutive && indices.isNotEmpty) {
      return '${_selectedDays.first}–${_selectedDays.last}';
    }
    return _selectedDays.join(', ');
  }

  String _getWeekendsRowText() {
    String daysText = _getDaysText();
    String timeText = (_startTime != null && _endTime != null)
        ? '${_startTime!.format(context)}–${_endTime!.format(context)}'
        : 'Select time range';
    return '$daysText: $timeText';
  }

  Future<void> _showDaysPopup(BuildContext context) async {
    List<String> tempSelectedDays = List.from(_selectedDays);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF93C5FD), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Days of the Week',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Wrap(
                  spacing: MediaQuery.of(context).size.width * 0.02,
                  runSpacing: MediaQuery.of(context).size.height * 0.01,
                  children: _daysOfWeek.map((day) {
                    return ChoiceChip(
                      label: Text(
                        day.substring(0, 3),
                        style: TextStyle(
                          color: tempSelectedDays.contains(day)
                              ? Colors.white
                              : Colors.black,
                          fontSize: MediaQuery.of(context).size.width * 0.035,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      selected: tempSelectedDays.contains(day),
                      selectedColor: const Color(0xFF93C5FD),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: tempSelectedDays.contains(day)
                              ? const Color(0xFF93C5FD)
                              : Colors.black,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (tempSelectedDays.contains(day)) {
                            tempSelectedDays.remove(day);
                          } else {
                            if (tempSelectedDays.isNotEmpty) {
                              int startIndex = _daysOfWeek.indexOf(
                                tempSelectedDays.last,
                              );
                              int endIndex = _daysOfWeek.indexOf(day);
                              if (startIndex > endIndex) {
                                final temp = startIndex;
                                startIndex = endIndex;
                                endIndex = temp;
                              }
                              tempSelectedDays.clear();
                              for (int i = startIndex; i <= endIndex; i++) {
                                tempSelectedDays.add(_daysOfWeek[i]);
                              }
                            } else {
                              tempSelectedDays.add(day);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDays = List.from(tempSelectedDays);
                          _daysController.text = _getDaysText();
                          widget.onDaysChanged(_selectedDays);
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: const Color(0xFF93C5FD),
                          fontFamily: 'Poppins',
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickTimeRange(BuildContext context) async {
    final TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF93C5FD),
              onPrimary: Colors.black,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
          ),
          child: child!,
        );
      },
    );
    if (start != null && start != _startTime) {
      setState(() {
        _startTime = start;
      });
      final TimeOfDay? end = await showTimePicker(
        context: context,
        initialTime:
            _endTime ??
            TimeOfDay(hour: (start.hour + 9) % 24, minute: start.minute),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF93C5FD),
                onPrimary: Colors.black,
                surface: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
              ),
            ),
            child: child!,
          );
        },
      );
      if (end != null && end != _endTime) {
        final startMinutes = start.hour * 60 + start.minute;
        final endMinutes = end.hour * 60 + end.minute;
        if (endMinutes <= startMinutes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time')),
          );
          return;
        }
        setState(() {
          _endTime = end;
          _timeController.text =
              '${start.format(context)}–${end.format(context)}';
          widget.onTimeChanged(_startTime, _endTime);
        });
      }
    }
  }

  @override
  void dispose() {
    _daysController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = MediaQuery.of(context).size.height;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                bottom: screenHeight * 0.01,
              ),
              child: Text(
                'Opening & Closing Hours',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.88,
                maxHeight: screenHeight * 0.3,
                minHeight: screenHeight * 0.25,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 237, 236, 236),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: screenHeight * 0.02,
                      left: screenWidth * 0.02,
                      right: screenWidth * 0.02,
                      top: screenHeight * 0.02,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: screenWidth * 0.88 * 0.42,
                              child: TextFormField(
                                controller: _daysController,
                                readOnly: true,
                                onTap: () => _showDaysPopup(context),
                                decoration: InputDecoration(
                                  labelText: 'Days of the Week',
                                  labelStyle: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                  hintText: 'Select Days',
                                  hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.6),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                  fillColor: const Color.fromARGB(
                                    255,
                                    237,
                                    236,
                                    236,
                                  ),
                                  filled: true,
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: const Color(0xFF93C5FD),
                                    size: screenWidth * 0.05,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF93C5FD),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF93C5FD),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: screenWidth * 0.04,
                                    horizontal: screenWidth * 0.03,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            SizedBox(
                              width: screenWidth * 0.88 * 0.42,
                              child: TextFormField(
                                controller: _timeController,
                                readOnly: true,
                                onTap: () => _pickTimeRange(context),
                                decoration: InputDecoration(
                                  labelText: 'Time Range',
                                  labelStyle: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                  hintText: 'Select Time Range',
                                  hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.6),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                  fillColor: const Color.fromARGB(
                                    255,
                                    237,
                                    236,
                                    236,
                                  ),
                                  filled: true,
                                  prefixIcon: Icon(
                                    Icons.access_time,
                                    color: const Color(0xFF93C5FD),
                                    size: screenWidth * 0.05,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF93C5FD),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF93C5FD),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: screenWidth * 0.04,
                                    horizontal: screenWidth * 0.04,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        if (_selectedDays.isNotEmpty &&
                            _startTime != null &&
                            _endTime != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.01,
                              horizontal: screenWidth * 0.03,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF93C5FD),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getWeekendsRowText(),
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: screenWidth * 0.035,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ContactInformationField extends StatelessWidget {
  final TextEditingController mtnNumberController;
  final TextEditingController airtelNumberController;
  final FocusNode mtnNumberFocus;
  final FocusNode airtelNumberFocus;
  final Function(String) onMtnChanged;
  final Function(String) onAirtelChanged;

  const ContactInformationField({
    super.key,
    required this.mtnNumberController,
    required this.airtelNumberController,
    required this.mtnNumberFocus,
    required this.airtelNumberFocus,
    required this.onMtnChanged,
    required this.onAirtelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = MediaQuery.of(context).size.height;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                bottom: screenHeight * 0.01,
              ),
              child: Text(
                'Contact Information',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.88,
                maxHeight: screenHeight * 0.25,
                minHeight: screenHeight * 0.2,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 237, 236, 236),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF93C5FD), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                      horizontal: screenWidth * 0.02,
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: mtnNumberController,
                          keyboardType: TextInputType.phone,
                          focusNode: mtnNumberFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(
                              context,
                            ).requestFocus(airtelNumberFocus);
                          },
                          onChanged: onMtnChanged,
                          decoration: InputDecoration(
                            labelText: 'MTN Number',
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth * 0.035,
                            ),
                            hintText: '+25677XXXXXXX',
                            hintStyle: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: screenWidth * 0.035,
                            ),
                            fillColor: const Color.fromARGB(255, 237, 236, 236),
                            filled: true,
                            prefixIcon: Icon(
                              Icons.phone,
                              color: const Color(0xFF93C5FD),
                              size: screenWidth * 0.05,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF93C5FD),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF93C5FD),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.04,
                              horizontal: screenWidth * 0.03,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.009,
                            horizontal: screenWidth * 0.02,
                          ),
                          child: Divider(
                            color: const Color(0xFF93C5FD),
                            thickness: 1,
                          ),
                        ),
                        TextFormField(
                          controller: airtelNumberController,
                          keyboardType: TextInputType.phone,
                          focusNode: airtelNumberFocus,
                          textInputAction: TextInputAction.done,
                          onChanged: onAirtelChanged,
                          decoration: InputDecoration(
                            labelText: 'Airtel Number',
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth * 0.035,
                            ),
                            hintText: '+25670XXXXXXX',
                            hintStyle: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: screenWidth * 0.035,
                            ),
                            fillColor: const Color.fromARGB(255, 237, 236, 236),
                            filled: true,
                            prefixIcon: Icon(
                              Icons.phone,
                              color: const Color(0xFF93C5FD),
                              size: screenWidth * 0.05,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF93C5FD),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF93C5FD),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.04,
                              horizontal: screenWidth * 0.03,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
