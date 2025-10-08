import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'dart:ui';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profileImagePath');
    });
  }

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

  bool _isDropdownVisible = false;
  bool _isMenuVisible = false;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isDropdownVisible = false;
              _isMenuVisible = false;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Column(
                children: [
                  // Glassy rectangle at the top
                  Container(
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
                                          left: screenWidth * 0.00,
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
                                              (_profileImagePath != null &&
                                                  _profileImagePath!.isNotEmpty)
                                              ? ClipOval(
                                                  child: Image.file(
                                                    File(_profileImagePath!),
                                                    fit: BoxFit.cover,
                                                    width: screenWidth * 0.1,
                                                    height: screenWidth * 0.1,
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
                  // Dashboard Overview text
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenHeight * 0.02,
                      left: screenWidth * 0.04,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Dashboard Overview',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Dropdown rectangle
              if (_isDropdownVisible)
                Positioned(
                  top: MediaQuery.of(context).padding.top + screenHeight * 0.09,
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
              // Scrollable content
              Positioned(
                top: screenHeight * 0.14,
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    width: screenWidth,
                    height: screenHeight * 1.5,
                    child: Stack(
                      children: [
                        // Card (Total Locations)
                        Positioned(
                          top: screenHeight * 0.02,
                          left: screenWidth * 0.04,
                          child: Container(
                            width: screenWidth * 0.30,
                            height: screenHeight * 0.15,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3FD317),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: screenHeight * 0.01,
                                  left: screenWidth * 0.02,
                                  child: Text(
                                    'Total\nLocations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: screenHeight * 0.01,
                                  right: screenWidth * 0.02,
                                  child: Container(
                                    width: screenWidth * 0.08,
                                    height: screenWidth * 0.08,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: screenWidth * 0.04,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: screenHeight * 0.045,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      '0',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.06,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist',
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: screenHeight * 0.01,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      'Places',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Card (Pending Feedback)
                        Positioned(
                          top: screenHeight * 0.02,
                          left: screenWidth * 0.36,
                          child: Container(
                            width: screenWidth * 0.30,
                            height: screenHeight * 0.15,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD31788),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: screenHeight * 0.01,
                                  left: screenWidth * 0.02,
                                  child: Text(
                                    'Pending\nFeedback',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: screenHeight * 0.01,
                                  right: screenWidth * 0.03,
                                  child: Container(
                                    width: screenWidth * 0.08,
                                    height: screenWidth * 0.08,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.chat,
                                      color: Colors.white,
                                      size: screenWidth * 0.04,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: screenHeight * 0.045,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      '0',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist',
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: screenHeight * 0.01,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      'Pending',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Card (Active Users)
                        Positioned(
                          top: screenHeight * 0.02,
                          left: screenWidth * 0.68,
                          child: Container(
                            width: screenWidth * 0.30,
                            height: screenHeight * 0.15,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C5AE4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: screenHeight * 0.01,
                                  left: screenWidth * 0.02,
                                  child: Text(
                                    'Active\nUsers',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: screenHeight * 0.01,
                                  right: screenWidth * 0.02,
                                  child: Container(
                                    width: screenWidth * 0.08,
                                    height: screenWidth * 0.08,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.group,
                                      color: Colors.white,
                                      size: screenWidth * 0.048,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: screenHeight * 0.045,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      '0',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist',
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: screenHeight * 0.01,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      'Users',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Location Management text
                        Positioned(
                          top: screenHeight * 0.18,
                          left: screenWidth * 0.04,
                          child: Row(
                            children: [
                              Text(
                                'Location Management',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.1),
                              Text(
                                '(Click the card)',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Location Management card
                        Positioned(
                          top: screenHeight * 0.23,
                          left: screenWidth * 0.04,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/LocationManagementScreen');
                            },
                            child: Container(
                              width: screenWidth * 0.92,
                              height: screenHeight * 0.23,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: -screenWidth * 0.2,
                                    bottom: -screenHeight * 0.05,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/images/location.png',
                                        width: screenWidth * 0.7,
                                        height: screenWidth * 0.7,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                  size: screenWidth * 0.2,
                                                ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.26,
                                    top: screenHeight * 0.022,
                                    child: Text(
                                      'Locations',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.26,
                                    top: screenHeight * 0.070,
                                    child: Text(
                                      'Manage all the locations on the\nmap here.',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.normal,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.26,
                                    top: screenHeight * 0.152,
                                    child: Row(
                                      children: [
                                        Text(
                                          'Add/Edit/Delete places',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Icon(
                                          Icons.double_arrow,
                                          color: Colors.green,
                                          size: screenWidth * 0.08,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: screenHeight * 0.02,
                                    right: screenWidth * 0.02,
                                    child: Container(
                                      width: screenWidth * 0.08,
                                      height: screenWidth * 0.08,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.black,
                                        size: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Feedback & Reports text
                        Positioned(
                          top: screenHeight * 0.47,
                          left: screenWidth * 0.04,
                          child: Row(
                            children: [
                              Text(
                                'Feedback & Reports',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.1),
                              Text(
                                '(Click the card)',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Feedback & Reports card
                        Positioned(
                          top: screenHeight * 0.52,
                          left: screenWidth * 0.04,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/FeedbackListScreen');
                            },
                            child: Container(
                              width: screenWidth * 0.92,
                              height: screenHeight * 0.23,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: -screenWidth * 0.2,
                                    bottom: -screenHeight * 0.05,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/images/feedback.png',
                                        width: screenWidth * 0.7,
                                        height: screenWidth * 0.7,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) => Icon(
                                              Icons.error,
                                              color: Colors.red,
                                              size: screenWidth * 0.2,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.26,
                                    top: screenHeight * 0.022,
                                    child: Text(
                                      'User Feedback',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.26,
                                    top: screenHeight * 0.070,
                                    child: Text(
                                      'Access all the user feedbacks from the\nMUBS Locator users.',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.normal,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.26,
                                    top: screenHeight * 0.152,
                                    child: Row(
                                      children: [
                                        Text(
                                          'View the replies',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Icon(
                                          Icons.double_arrow,
                                          color: Colors.green,
                                          size: screenWidth * 0.08,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: screenHeight * 0.02,
                                    right: screenWidth * 0.02,
                                    child: Container(
                                      width: screenWidth * 0.08,
                                      height: screenWidth * 0.08,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.chat,
                                        color: Colors.black,
                                        size: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Push Notifications text
                        Positioned(
                          top: screenHeight * 0.76,
                          left: screenWidth * 0.04,
                          child: Row(
                            children: [
                              Text(
                                'Push Notifications',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.1),
                              Text(
                                '(Click the card)',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Push Notifications card
                        Positioned(
                          top: screenHeight * 0.81,
                          left: screenWidth * 0.04,
                          child: Container(
                            width: screenWidth * 0.92,
                            height: screenHeight * 0.23,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: -screenWidth * 0.2,
                                  bottom: -screenHeight * 0.05,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/notifications.png',
                                      width: screenWidth * 0.7,
                                      height: screenWidth * 0.7,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.error,
                                            color: Colors.red,
                                            size: screenWidth * 0.2,
                                          ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.26,
                                  top: screenHeight * 0.022,
                                  child: Text(
                                    'Notifications',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.26,
                                  top: screenHeight * 0.070,
                                  child: Text(
                                    'Manage all the app notifications\nhere.',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.26,
                                  top: screenHeight * 0.152,
                                  child: Row(
                                    children: [
                                      Text(
                                        'Add/Edit/ notifications here',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Icon(
                                        Icons.double_arrow,
                                        color: Colors.green,
                                        size: screenWidth * 0.08,
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: screenHeight * 0.02,
                                  right: screenWidth * 0.02,
                                  child: Container(
                                    width: screenWidth * 0.08,
                                    height: screenWidth * 0.08,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.notifications,
                                      color: Colors.black,
                                      size: screenWidth * 0.04,
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
                                  (_profileImagePath != null &&
                                      _profileImagePath!.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_profileImagePath!),
                                        fit: BoxFit.cover,
                                        width: screenWidth * 0.15,
                                        height: screenWidth * 0.15,
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
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/AdminDashboardScreen',
                            );
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
                          onTap: () {
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
                          onTap: () {
                            Navigator.pushNamed(context, '/ProfileScreen');
                            setState(() {
                              _isMenuVisible = false;
                            });
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
                          onTap: () {
                            Navigator.pushNamed(context, '/SendNotificationsScreen');
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
                          onTap: () {
                            Navigator.pushNamed(context, '/LocationManagementScreen');
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
            ],
          ),
        ),
      ),
    );
  }
}
