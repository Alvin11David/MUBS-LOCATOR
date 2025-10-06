import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen>
    with SingleTickerProviderStateMixin {
  // Determine greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // State for dropdown and menu visibility
  bool _isDropdownVisible = false;
  bool _isMenuVisible = false;

  // Controllers and focus nodes for input fields
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _buildingNameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  // Location state
  LatLng _selectedLocation = const LatLng(0.32848299678238435, 32.61717974633408);
  GoogleMapController? _mapController;
  bool _isLocationSelected = false;

  // MUBS center coordinates
  static const CameraPosition _mubsCenter = CameraPosition(
    target: LatLng(0.32848299678238435, 32.61717974633408),
    zoom: 16.0,
  );

  // Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _isLocationSelected = true;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_selectedLocation),
    );
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _descriptionController.dispose();
    _buildingNameFocus.dispose();
    _descriptionFocus.dispose();
    _locationFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Get the user's full name from Firebase
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF93C5FD),
      body: Stack(
        children: [
          // Background GestureDetector to close sidebar, dropdown, and keyboard
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_isMenuVisible) {
                    _isMenuVisible = false; // Close sidebar when tapping outside
                  }
                  _isDropdownVisible = false; // Close dropdown
                });
                FocusScope.of(context).unfocus(); // Close keyboard
              },
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // Glassy rectangle at the top
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
                  bottom: Radius.circular(0),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.transparent,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Menu icon
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isMenuVisible = !_isMenuVisible;
                                _isDropdownVisible = false; // Ensure dropdown is closed
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
                          // Greeting text with full name
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
                          // Small rectangle with black stroke
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
                                // Circular container with person icon
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.00,
                                  ),
                                  child: Container(
                                    width: screenWidth * 0.09,
                                    height: screenWidth * 0.09,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.black,
                                      size: screenWidth * 0.04,
                                    ),
                                  ),
                                ),
                                // Dropdown arrow
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: screenWidth * 0.01,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isDropdownVisible =
                                            !_isDropdownVisible;
                                        _isMenuVisible = false; // Ensure sidebar is closed
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
          ),
          // Add a Place text, subtitle, and chevron icons
          Positioned(
            top: screenHeight * 0.1,
            left: screenWidth * 0.05,
            right: screenWidth * 0.04,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add a Place',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Fill in the form below to successfully\nadd a place',
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
                          Navigator.pop(context); // Navigate to previous screen
                        },
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.black,
                          size: screenWidth * 0.08,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
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
          ),
          // Dropdown rectangle
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
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.01,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile',
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
          // White rectangle with scrollable content
          Positioned(
            top: screenHeight * 0.21,
            left: screenWidth * 0.02,
            right: screenWidth * 0.02,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                // Prevent taps within the form from closing the sidebar
              },
              behavior: HitTestBehavior.opaque,
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
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.0,
                              ),
                              child: LocationSelectField(
                                controller: TextEditingController(),
                                label: 'Location Select',
                                hint: 'Tap on the map to select location',
                                icon: Icons.location_on,
                                focusNode: _locationFocus,
                                textInputAction: TextInputAction.done,
                                selectedLocation: _selectedLocation,
                                isLocationSelected: _isLocationSelected,
                                onMapCreated: _onMapCreated,
                                onTap: _onTap,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.0,
                              ),
                              child: PhotosMediaField(),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.00,
                              ),
                              child: OpeningClosingHoursField(),
                            ),
                            SizedBox(height: screenHeight * 0.04),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Content area with Empty Container
          Positioned(
            top: screenHeight * 0.09,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.transparent,
            ),
          ),
          // Sidebar (Menu rectangle)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _isMenuVisible ? 0 : -screenWidth * 0.6,
            top: 0,
            child: GestureDetector(
              onTap: () {
                // Prevent taps within the sidebar from closing it
              },
              behavior: HitTestBehavior.opaque,
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
                            child: Icon(
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
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.03,
                        top: screenHeight * 0.02,
                      ),
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
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.03,
                        top: screenHeight * 0.02,
                      ),
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
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.03,
                        top: screenHeight * 0.02,
                      ),
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
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.03,
                        top: screenHeight * 0.02,
                      ),
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
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.03,
                        top: screenHeight * 0.02,
                      ),
                      child: GestureDetector(
                        onTap: _logout,
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
          ),
        ],
      ),
    );
  }
}

// BuildingNameField class
class BuildingNameField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;

  const BuildingNameField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focusNode,
    this.nextFocusNode,
    required this.textInputAction,
  });

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.text,
          validator: _validateName,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
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

// DescriptionField class
class DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;

  const DescriptionField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focusNode,
    this.nextFocusNode,
    required this.textInputAction,
  });

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          validator: _validateDescription,
          focusNode: focusNode,
          textInputAction: textInputAction,
          maxLines: 4,
          minLines: 3,
          maxLength: 500,
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
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
                padding: EdgeInsets.only(left: screenWidth * 0.08, top: screenWidth * 0.005),
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

// Location Select Field with Google Maps
class LocationSelectField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
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
                  border: Border.all(
                    color: const Color(0xFF93C5FD),
                    width: 1,
                  ),
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
                              title: widget.isLocationSelected ? 'Selected Location' : 'Tap to select location',
                              snippet: '${widget.selectedLocation.latitude.toStringAsFixed(6)}, ${widget.selectedLocation.longitude.toStringAsFixed(6)}',
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

// Photos & Media Field with 4 solid rectangles
class PhotosMediaField extends StatefulWidget {
  const PhotosMediaField({super.key});

  @override
  State<PhotosMediaField> createState() => _PhotosMediaFieldState();
}

class _PhotosMediaFieldState extends State<PhotosMediaField> {
  final List<XFile?> _images = [null, null, null, null];
  final ImagePicker _picker = ImagePicker();

  Future<void> _addImage(int index) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _images[index] = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
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
                  border: Border.all(
                    color: const Color(0xFF93C5FD),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.04,
                      mainAxisSpacing: screenHeight * 0.02,
                      childAspectRatio: 1.0,
                      shrinkWrap: true,
                      children: List.generate(4, (index) {
                        return GestureDetector(
                          onTap: () => _addImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFF93C5FD),
                                width: 1,
                              ),
                            ),
                            child: _images[index] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(
                                      File(_images[index]!.path),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.add,
                                        color: const Color(0xFF93C5FD),
                                        size: screenWidth * 0.08,
                                      ),
                                    ),
                                  ),
                          ),
                        );
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

// Opening & Closing Hours Field
class OpeningClosingHoursField extends StatefulWidget {
  const OpeningClosingHoursField({super.key});

  @override
  State<OpeningClosingHoursField> createState() => _OpeningClosingHoursFieldState();
}

class _OpeningClosingHoursFieldState extends State<OpeningClosingHoursField> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF93C5FD),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Color(0xFF93C5FD), width: 1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF93C5FD),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Color(0xFF93C5FD), width: 1),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
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
                maxHeight: screenHeight * 0.25,
                minHeight: screenHeight * 0.2,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 237, 236, 236),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF93C5FD),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.09, left: screenWidth * 0.02, right: screenWidth * 0.02),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.88 * 0.42,
                          child: TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () => _pickDate(context),
                            decoration: InputDecoration(
                              labelText: 'Dates',
                              labelStyle: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: screenWidth * 0.035,
                              ),
                              hintText: 'Select Date',
                              hintStyle: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: screenWidth * 0.035,
                              ),
                              fillColor: const Color.fromARGB(255, 237, 236, 236),
                              filled: true,
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: const Color(0xFF93C5FD),
                                size: screenWidth * 0.05,
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
                            onTap: () => _pickTime(context),
                            decoration: InputDecoration(
                              labelText: 'Time',
                              labelStyle: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: screenWidth * 0.035,
                              ),
                              hintText: 'Select Time',
                              hintStyle: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: screenWidth * 0.035,
                              ),
                              fillColor: const Color.fromARGB(255, 237, 236, 236),
                              filled: true,
                              prefixIcon: Icon(
                                Icons.access_time,
                                color: const Color(0xFF93C5FD),
                                size: screenWidth * 0.05,
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