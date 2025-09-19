import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _selectedImage; // Store the selected image
  final _fullNameController = TextEditingController(); // Controller for full name field
  final _emailController = TextEditingController(); // Controller for email field
  final _phoneController = TextEditingController(); // Controller for phone contact field
  final _locationController = TextEditingController(); // Controller for location field

  // Function to pick an image from gallery or camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // Use gallery for image selection

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Update state with selected image
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFF93C5FD), // Set background color to #93C5FD
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Glassy water rectangle (top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * 0.15, // 15% of screen height for rectangle
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Semi-transparent for glassy effect
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: Colors.white, // White stroke
                      width: 1, // Fixed stroke width
                    ),
                  ),
                ),
              ),
              // Profile picture circle with person icon or selected image
              Positioned(
                top: screenHeight * 0.015, // Centered vertically in the glassy rectangle
                left: (screenWidth - screenWidth * 0.25) / 2, // Center horizontally
                child: Stack(
                  children: [
                    Container(
                      width: screenWidth * 0.25, // Circle size is 25% of screen width
                      height: screenWidth * 0.25, // Keep aspect ratio
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2), // Glassy effect
                        border: Border.all(
                          color: Colors.white, // White stroke
                          width: screenWidth * 0.006, // Stroke width scales with screen
                        ),
                      ),
                      child: Center(
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  width: screenWidth * 0.25,
                                  height: screenWidth * 0.25,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.black, // Black icon color
                                size: screenWidth * 0.12, // Icon size is 12% of screen width
                              ),
                      ),
                    ),
                    // Camera icon on lower border
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage, // Trigger image picker on tap
                        child: Container(
                          width: screenWidth * 0.08, // Camera icon container size
                          height: screenWidth * 0.08,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white, // White background for camera icon
                            border: Border.all(
                              color: Colors.white, // White stroke
                              width: screenWidth * 0.003, // Stroke width scales
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: screenWidth * 0.05, // Camera icon size
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Back chevron button
              Positioned(
                top: screenHeight * 0.02, // 2% of screen height for top padding
                left: screenWidth * 0.04, // 4% of screen width for left padding
                child: ClipOval(
                  child: Container(
                    width: screenWidth * 0.15, // Circle size is 15% of screen width
                    height: screenWidth * 0.15, // Keep aspect ratio
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Semi-transparent for glassy effect
                      border: Border.all(
                        color: Colors.white, // White stroke
                        width: screenWidth * 0.006, // Stroke width scales with screen
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.black, // Black icon color
                        size: screenWidth * 0.08, // Icon size is 8% of screen width
                      ),
                    ),
                  ),
                ),
              ),
              // "Edit Profile" text
              Positioned(
                top: screenHeight * 0.19, // Below the glassy rectangle
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.06, // Font size is 6% of screen width for responsiveness
                      fontFamily: 'Epunda Slab',
                    ),
                  ),
                ),
              ),
              // "Feel in the fields below" text
              Positioned(
                top: screenHeight * 0.23, // Below the "Edit Profile" text
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Feel in the fields below',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth * 0.05, // Font size is 5% of screen width for responsiveness
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
              ),
              // Glassy water rectangle below "Feel in the fields below"
              Positioned(
                top: screenHeight * 0.31, // Below the "Feel in the fields below" text
                left: screenWidth * 0.02, // 2% of screen width for left padding
                right: screenWidth * 0.02, // 2% of screen width for right padding
                child: Container(
                  height: screenHeight * 0.69, // 69% of screen height for rectangle
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Semi-transparent for glassy effect
                    borderRadius: BorderRadius.circular(30), // Border radius of 30
                    border: Border.all(
                      color: Colors.white, // White stroke
                      width: 1, // Fixed stroke width
                    ),
                  ),
                  margin: EdgeInsets.only(bottom: screenHeight * 0.05), // Bottom padding
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05, // 5% of screen width for horizontal padding
                      vertical: screenHeight * 0.02, // 2% of screen height for vertical padding
                    ),
                    child: Column(
                      children: [
                        FullNameField(controller: _fullNameController),
                        SizedBox(height: screenHeight * 0.02), // Spacing between fields
                        EmailField(controller: _emailController),
                        SizedBox(height: screenHeight * 0.02), // Spacing between fields
                        PhoneContactField(controller: _phoneController),
                        SizedBox(height: screenHeight * 0.02), // Spacing between fields
                        LocationField(controller: _locationController),
                        SizedBox(height: screenHeight * 0.05), // Spacing before button
                        UpdateButton(),
                      ],
                    ),
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

class FullNameField extends StatelessWidget {
  final TextEditingController controller;
  const FullNameField({super.key, required this.controller});

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your full name';
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
          keyboardType: TextInputType.name,
          validator: _validateFullName,
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05,
            ),
            hintText: 'Enter Your Full Name',
            hintStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: screenWidth * 0.045,
            ),
            fillColor: Colors.white.withOpacity(0.2),
            filled: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: Icon(
                Icons.person,
                color: const Color.fromARGB(255, 69, 141, 224),
              ),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.02),
              child: Icon(
                Icons.edit, // Pen icon
                color: const Color.fromARGB(255, 69, 141, 224), // Matching color with prefix icon
                size: screenWidth * 0.06, // Responsive icon size
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 1),
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

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  const EmailField({super.key, required this.controller});

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
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
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05,
            ),
            hintText: 'Enter Your Email',
            hintStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: screenWidth * 0.045,
            ),
            fillColor: Colors.white.withOpacity(0.2),
            filled: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: Icon(
                Icons.mail,
                color: const Color.fromARGB(255, 69, 141, 224),
              ),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.02),
              child: Icon(
                Icons.edit, // Pen icon
                color: const Color.fromARGB(255, 69, 141, 224), // Matching color with prefix icon
                size: screenWidth * 0.06, // Responsive icon size
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 1),
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

class PhoneContactField extends StatelessWidget {
  final TextEditingController controller;
  const PhoneContactField({super.key, required this.controller});

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{9,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid phone number (9-15 digits)';
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
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            labelStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05,
            ),
            hintText: 'Enter Your Phone Number',
            hintStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: screenWidth * 0.045,
            ),
            fillColor: Colors.white.withOpacity(0.2),
            filled: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: Icon(
                Icons.phone,
                color: const Color.fromARGB(255, 69, 141, 224),
              ),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.02),
              child: Icon(
                Icons.edit, // Pen icon
                color: const Color.fromARGB(255, 69, 141, 224), // Matching color with prefix icon
                size: screenWidth * 0.06, // Responsive icon size
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 1),
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

class LocationField extends StatelessWidget {
  final TextEditingController controller;
  const LocationField({super.key, required this.controller});

  String? _validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your location';
    }
    if (value.trim().length < 3) {
      return 'Location must be at least 3 characters long';
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
          validator: _validateLocation,
          decoration: InputDecoration(
            labelText: 'Location',
            labelStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05,
            ),
            hintText: 'Enter Your Location',
            hintStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: screenWidth * 0.045,
            ),
            fillColor: Colors.white.withOpacity(0.2),
            filled: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: Icon(
                Icons.location_pin,
                color: const Color.fromARGB(255, 69, 141, 224),
              ),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.02),
              child: Icon(
                Icons.edit, // Pen icon
                color: const Color.fromARGB(255, 69, 141, 224), // Matching color with prefix icon
                size: screenWidth * 0.06, // Responsive icon size
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFFFFFFFF), width: 1),
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

class UpdateButton extends StatelessWidget {
  const UpdateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = MediaQuery.of(context).size.height;
        return SizedBox(
          width: double.infinity, // Full width like the fields
          height: screenHeight * 0.06, // Same height as typical field height
          child: GestureDetector(
            onTap: () {
              // Add update logic here
              print('Update profile tapped');
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30), // Same as fields
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE0E7FF), // E0E7FF at 0%
                    Color(0xFF93C5FD), // 93C5FD at 47%
                  ],
                  stops: [0.0, 0.47], // 0% to 47%
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFF3B82F6), // Blue border
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Update',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Epunda Slab',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}