import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _selectedImage; // Store the selected image temporarily
  String? _profilePicUrl; // Store the Firestore profile pic URL
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isUploading = false; // Track upload state

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch data from Firestore on init
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userData = doc.data();
          setState(() {
            _fullNameController.text = userData?['fullName'] ?? '';
            _emailController.text = userData?['email'] ?? user.email ?? '';
            _phoneController.text = userData?['phone'] ?? '';
            _locationController.text = userData?['location'] ?? '';
            _profilePicUrl = userData?['profilePicUrl'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        _showSnackBar('Error loading data: $e');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() => _isUploading = true);

        String? downloadUrl = _profilePicUrl;
        if (_selectedImage != null) {
          // Upload image to Firebase Storage
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_pics/${user.uid}/profile.jpg');
          final uploadTask = ref.putFile(_selectedImage!);
          final snapshot = await uploadTask;
          downloadUrl = await snapshot.ref.getDownloadURL();
        }

        // Update Firestore with profile data
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'profilePicUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Clear SharedPreferences to prevent residual image paths
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('profileImagePath');

        if (mounted) {
          Navigator.pop(context, {
            'imageUrl': downloadUrl,
            'fullName': _fullNameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'location': _locationController.text,
          });
          _showSnackBar('Profile updated successfully!');
        }
      }
    } catch (e) {
      print('Error saving profile data: $e');
      if (mounted) {
        _showSnackBar('Error updating profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Image.asset(
              'assets/logo/logo.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFF93C5FD),
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.015,
                left: (screenWidth - screenWidth * 0.25) / 2,
                child: Stack(
                  children: [
                    Container(
                      width: screenWidth * 0.25,
                      height: screenWidth * 0.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white,
                          width: screenWidth * 0.006,
                        ),
                      ),
                      child: Center(
                        child: _isUploading
                            ? const CircularProgressIndicator()
                            : _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      width: screenWidth * 0.25,
                                      height: screenWidth * 0.25,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _profilePicUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _profilePicUrl!,
                                          width: screenWidth * 0.25,
                                          height: screenWidth * 0.25,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const CircularProgressIndicator();
                                          },
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            Icons.person,
                                            color: Colors.black,
                                            size: screenWidth * 0.12,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: Colors.black,
                                        size: screenWidth * 0.12,
                                      ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        child: Container(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white,
                              width: screenWidth * 0.003,
                            ),
                          ),
                          child: Center(
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: screenHeight * 0.02,
                left: screenWidth * 0.04,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: ClipOval(
                    child: Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white,
                          width: screenWidth * 0.006,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.black,
                          size: screenWidth * 0.08,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.19,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.06,
                      fontFamily: 'Epunda Slab',
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.23,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Fill in the fields below',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w200,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.31,
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
                child: Container(
                  height: screenHeight * 0.69,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.only(bottom: screenHeight * 0.05),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      children: [
                        FullNameField(controller: _fullNameController),
                        SizedBox(height: screenHeight * 0.02),
                        EmailField(controller: _emailController),
                        SizedBox(height: screenHeight * 0.02),
                        PhoneContactField(controller: _phoneController),
                        SizedBox(height: screenHeight * 0.02),
                        LocationField(controller: _locationController),
                        SizedBox(height: screenHeight * 0.05),
                        UpdateButton(onUpdate: _saveProfileData),
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
                Icons.edit,
                color: const Color.fromARGB(255, 69, 141, 224),
                size: screenWidth * 0.06,
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
                Icons.edit,
                color: const Color.fromARGB(255, 69, 141, 224),
                size: screenWidth * 0.06,
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
                Icons.edit,
                color: const Color.fromARGB(255, 69, 141, 224),
                size: screenWidth * 0.06,
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
                Icons.edit,
                color: const Color.fromARGB(255, 69, 141, 224),
                size: screenWidth * 0.06,
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
  final VoidCallback onUpdate;
  const UpdateButton({super.key, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = MediaQuery.of(context).size.height;
        return SizedBox(
          width: double.infinity,
          height: screenHeight * 0.06,
          child: GestureDetector(
            onTap: onUpdate,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE0E7FF),
                    Color(0xFF93C5FD),
                  ],
                  stops: [0.0, 0.47],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFF3B82F6),
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