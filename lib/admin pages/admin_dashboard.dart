import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'dart:ui';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
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

  // Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()), // Navigate to SignInScreen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Get the user's full name from Firebase
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isDropdownVisible = false; // Close dropdown when tapping outside
            _isMenuVisible = false; // Close menu when tapping outside
          });
        },
        behavior: HitTestBehavior.opaque, // Capture taps across the entire screen
        child: Stack(
          children: [
            // Glassy rectangle at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: screenHeight * 0.09, // Small, responsive height (9% of screen height)
                width: screenWidth, // Full width from left to right margin
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // Semi-transparent white for glassy effect
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)), // Rounded bottom corners
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3), // Subtle border
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur for glassy effect
                    child: Container(
                      color: Colors.transparent, // Transparent to allow blur to show
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.02,
                        ), // Responsive padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Menu icon
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isMenuVisible = !_isMenuVisible; // Toggle menu visibility
                                });
                              },
                              behavior: HitTestBehavior.opaque, // Prevent tap from propagating
                              child: Icon(
                                Icons.menu,
                                color: Colors.black,
                                size: screenWidth * 0.08, // Responsive icon size
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.04), // Responsive separation
                            // Greeting text with full name
                            Text(
                              '${_getGreeting()}, $fullName',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.045, // Responsive font size
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins', // Consistent with SignUpScreen
                              ),
                            ),
                            Spacer(), // Pushes the rectangle to the right
                            // Small rectangle with black stroke
                            Container(
                              width: screenWidth * 0.17, // Small, responsive width (17% of screen width)
                              height: screenHeight * 0.05, // Small, responsive height
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30), // Border radius of 30
                                border: Border.all(
                                  color: Colors.black, // Black stroke
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Circular container with person icon
                                  Padding(
                                    padding: EdgeInsets.only(left: screenWidth * 0.00), // Responsive padding
                                    child: Container(
                                      width: screenWidth * 0.09, // Responsive circle size
                                      height: screenWidth * 0.09, // Keep it circular
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black, // Black stroke
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.black,
                                        size: screenWidth * 0.04, // Responsive icon size
                                      ),
                                    ),
                                  ),
                                  // Dropdown arrow
                                  Padding(
                                    padding: EdgeInsets.only(right: screenWidth * 0.01), // Responsive padding
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isDropdownVisible = !_isDropdownVisible; // Toggle dropdown visibility
                                        });
                                      },
                                      behavior: HitTestBehavior.opaque, // Prevent tap from propagating to outer GestureDetector
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.black,
                                        size: screenWidth * 0.04, // Responsive icon size
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
            // Scrollable content
            Positioned(
              top: screenHeight * 0.09,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: screenWidth,
                  height: screenHeight * 1.5, // Enough height to accommodate all content
                  child: Stack(
                    children: [
                      // Dropdown rectangle
                      if (_isDropdownVisible)
                        Positioned(
                          top: 0, // Adjusted from screenHeight * 0.09
                          right: screenWidth * 0.04, // Align with the right padding of the glassy rectangle
                          child: Container(
                            width: screenWidth * 0.25, // Responsive width for dropdown
                            height: screenHeight * 0.06, // Responsive height for dropdown
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2), // Glassy effect
                              borderRadius: BorderRadius.circular(16), // Rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2), // Black shadow
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur for glassy effect
                                child: Container(
                                  color: Colors.transparent,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.03,
                                      vertical: screenHeight * 0.01,
                                    ), // Responsive padding
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Profile text
                                        Text(
                                          'Profile',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.04, // Responsive font size
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins', // Consistent with SignUpScreen
                                          ),
                                        ),
                                        // Pen icon
                                        Image.asset(
                                          'assets/images/edit.png',
                                          color: Colors.black,
                                          width: screenWidth * 0.04, // Responsive icon size
                                          height: screenWidth * 0.04, // Responsive icon size
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Dashboard Overview text
                      Positioned(
                        top: screenHeight * 0.02, // Adjusted from screenHeight * 0.11
                        left: screenWidth * 0.04, // Align with left padding
                        child: Text(
                          'Dashboard Overview',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.05, // Responsive font size
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins', // Consistent with SignUpScreen
                          ),
                        ),
                      ),
                      // Card below Dashboard Overview (Total Locations)
                      Positioned(
                        top: screenHeight * 0.07, // Adjusted from screenHeight * 0.16
                        left: screenWidth * 0.04, // Align with left padding
                        child: Container(
                          width: screenWidth * 0.30, // Responsive width (30% of screen width)
                          height: screenHeight * 0.15, // Responsive height (15% of screen height)
                          decoration: BoxDecoration(
                            color: const Color(0xFF3FD317), // Green color
                            borderRadius: BorderRadius.circular(20), // Border radius of 20
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: screenHeight * 0.01, // Small top padding
                                left: screenWidth * 0.02, // Small left padding
                                child: Text(
                                  'Total\nLocations',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.035, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Urbanist', // Urbanist font
                                  ),
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.01, // Small top padding
                                right: screenWidth * 0.02, // Small right padding
                                child: Container(
                                  width: screenWidth * 0.08, // Responsive circle size
                                  height: screenWidth * 0.08, // Keep it circular
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                                    border: Border.all(
                                      color: Colors.white, // White stroke
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: screenWidth * 0.04, // Responsive icon size
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: screenHeight * 0.045, // Small bottom padding
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.06, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist', // Urbanist font
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: screenHeight * 0.01, // Small bottom padding
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    'Places',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.05, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist', // Urbanist font
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Card below Dashboard Overview (Pending Feedback)
                      Positioned(
                        top: screenHeight * 0.07, // Adjusted from screenHeight * 0.16
                        left: screenWidth * 0.36, // Align with left padding
                        child: Container(
                          width: screenWidth * 0.30, // Responsive width (30% of screen width)
                          height: screenHeight * 0.15, // Responsive height (15% of screen height)
                          decoration: BoxDecoration(
                            color: const Color(0xFFD31788), // Pink color
                            borderRadius: BorderRadius.circular(20), // Border radius of 20
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: screenHeight * 0.01, // Small top padding
                                left: screenWidth * 0.02, // Small left padding
                                child: Text(
                                  'Pending\nFeedback',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.035, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Urbanist', // Urbanist font
                                  ),
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.01, // Small top padding
                                right: screenWidth * 0.03, // Small right padding
                                child: Container(
                                  width: screenWidth * 0.08, // Responsive circle size
                                  height: screenWidth * 0.08, // Keep it circular
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                                    border: Border.all(
                                      color: Colors.white, // White stroke
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chat,
                                    color: Colors.white,
                                    size: screenWidth * 0.04, // Responsive icon size
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: screenHeight * 0.045, // Small bottom padding
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.05, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist', // Urbanist font
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: screenHeight * 0.01, // Small bottom padding
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.05, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist', // Urbanist font
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Card below Dashboard Overview (Active Users)
                      Positioned(
                        top: screenHeight * 0.07, // Adjusted from screenHeight * 0.16
                        left: screenWidth * 0.68, // Align with left padding
                        child: Container(
                          width: screenWidth * 0.30, // Responsive width (30% of screen width)
                          height: screenHeight * 0.15, // Responsive height (15% of screen height)
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C5AE4), // Blue color
                            borderRadius: BorderRadius.circular(20), // Border radius of 20
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: screenHeight * 0.01, // Small top padding
                                left: screenWidth * 0.02, // Small left padding
                                child: Text(
                                  'Active\nUsers',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.035, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Urbanist', // Urbanist font
                                  ),
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.01, // Small top padding
                                right: screenWidth * 0.02, // Small right padding
                                child: Container(
                                  width: screenWidth * 0.08, // Responsive circle size
                                  height: screenWidth * 0.08, // Keep it circular
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(8), // Slightly rounded corners
                                    border: Border.all(
                                      color: Colors.white, // White stroke
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.group,
                                    color: Colors.white,
                                    size: screenWidth * 0.048, // Responsive icon size
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: screenHeight * 0.045, // Small bottom padding
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.05, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist', // Urbanist font
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: screenHeight * 0.01, // Small bottom padding
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    'Users',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.05, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Urbanist', // Urbanist font
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Location Management text below cards
                      Positioned(
                        top: screenHeight * 0.23, // Adjusted from screenHeight * 0.32
                        left: screenWidth * 0.04, // Align with left padding
                        child: Row(
                          children: [
                            Text(
                              'Location Management',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.05, // Responsive font size
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins', // Consistent with Dashboard Overview
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.1), // Responsive separation
                            Text(
                              '(Click the card)',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.04, // Slightly smaller responsive font size
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins', // Consistent with Dashboard Overview
                              ),
                            ),
                          ],
                        ),
                      ),
                      // White rectangle below Location Management text
                      Positioned(
                        top: screenHeight * 0.28, // Adjusted from screenHeight * 0.37
                        left: screenWidth * 0.04, // Align with left padding
                        child: Container(
                          width: screenWidth * 0.92, // Responsive width (92% of screen width)
                          height: screenHeight * 0.23, // Responsive height (23% of screen height)
                          decoration: BoxDecoration(
                            color: Colors.white, // White background
                            borderRadius: BorderRadius.circular(30), // Border radius of 30
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: -screenWidth * 0.2, // Small left padding
                                bottom: -screenHeight * 0.05, // Small bottom padding
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8), // Slightly rounded corners for image
                                  child: Image.asset(
                                    'assets/images/location.png',
                                    width: screenWidth * 0.7, // Responsive image size
                                    height: screenWidth * 0.7, // Keep it square
                                    fit: BoxFit.contain, // Ensure image scales properly
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: screenWidth * 0.2, // Match image size for error icon
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Position to the right of the image
                                top: screenHeight * 0.022, // Align with image's bottom edge
                                child: Text(
                                  'Locations',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.045, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Align with Locations text
                                top: screenHeight * 0.070, // Below Locations text
                                child: Text(
                                  'Manage all the locations on the\nmap here.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04, // Slightly smaller responsive font size
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Align with Manage text
                                top: screenHeight * 0.152, // Below Manage text
                                child: Row(
                                  children: [
                                    Text(
                                      'Add/Edit/Delete places',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04, // Same responsive font size as Manage text
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02), // Responsive separation
                                    Icon(
                                      Icons.double_arrow,
                                      color: Colors.green,
                                      size: screenWidth * 0.08, // Responsive icon size
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.02, // Align near top edge
                                right: screenWidth * 0.02, // Align near right edge
                                child: Container(
                                  width: screenWidth * 0.08, // Responsive circle size
                                  height: screenWidth * 0.08, // Keep it circular
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black, // Black stroke
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.black,
                                    size: screenWidth * 0.04, // Responsive icon size
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Reports & Feedback text below cards
                      Positioned(
                        top: screenHeight * 0.52, // Adjusted from screenHeight * 0.61
                        left: screenWidth * 0.04, // Align with left padding
                        child: Row(
                          children: [
                            Text(
                              'Feedback & Reports',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.05, // Responsive font size
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins', // Consistent with Dashboard Overview
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.1), // Responsive separation
                            Text(
                              '(Click the card)',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.04, // Slightly smaller responsive font size
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins', // Consistent with Dashboard Overview
                              ),
                            ),
                          ],
                        ),
                      ),
                      // White rectangle below Location Management text
                      Positioned(
                        top: screenHeight * 0.57, // Adjusted from screenHeight * 0.66
                        left: screenWidth * 0.04, // Align with left padding
                        child: Container(
                          width: screenWidth * 0.92, // Responsive width (92% of screen width)
                          height: screenHeight * 0.23, // Responsive height (23% of screen height)
                          decoration: BoxDecoration(
                            color: Colors.white, // White background
                            borderRadius: BorderRadius.circular(30), // Border radius of 30
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: -screenWidth * 0.2, // Small left padding
                                bottom: -screenHeight * 0.05, // Small bottom padding
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8), // Slightly rounded corners for image
                                  child: Image.asset(
                                    'assets/images/feedback.png',
                                    width: screenWidth * 0.7, // Responsive image size
                                    height: screenWidth * 0.7, // Keep it square
                                    fit: BoxFit.contain, // Ensure image scales properly
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: screenWidth * 0.2, // Match image size for error icon
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Position to the right of the image
                                top: screenHeight * 0.022, // Align with image's bottom edge
                                child: Text(
                                  'User Feedback',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.045, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Align with Locations text
                                top: screenHeight * 0.070, // Below Locations text
                                child: Text(
                                  'Access all the user feedbacks from the\nMUBS Locator users.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04, // Slightly smaller responsive font size
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Align with Manage text
                                top: screenHeight * 0.152, // Below Manage text
                                child: Row(
                                  children: [
                                    Text(
                                      'View the replies',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04, // Same responsive font size as Manage text
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02), // Responsive separation
                                    Icon(
                                      Icons.double_arrow,
                                      color: Colors.green,
                                      size: screenWidth * 0.08, // Responsive icon size
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.02, // Align near top edge
                                right: screenWidth * 0.02, // Align near right edge
                                child: Container(
                                  width: screenWidth * 0.08, // Responsive circle size
                                  height: screenWidth * 0.08, // Keep it circular
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black, // Black stroke
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chat,
                                    color: Colors.black,
                                    size: screenWidth * 0.04, // Responsive icon size
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Push Notifications text below cards
                      Positioned(
                        top: screenHeight * 0.81, // Adjusted from screenHeight * 0.90
                        left: screenWidth * 0.04, // Align with left padding
                        child: Row(
                          children: [
                            Text(
                              'Push Notifications',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.05, // Responsive font size
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins', // Consistent with Dashboard Overview
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.1), // Responsive separation
                            Text(
                              '(Click the card)',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.04, // Slightly smaller responsive font size
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins', // Consistent with Dashboard Overview
                              ),
                            ),
                          ],
                        ),
                      ),
                      // White rectangle below Location Management text
                      Positioned(
                        top: screenHeight * 0.86, // Adjusted from screenHeight * 0.95
                        left: screenWidth * 0.04, // Align with left padding
                        child: Container(
                          width: screenWidth * 0.92, // Responsive width (92% of screen width)
                          height: screenHeight * 0.23, // Responsive height (23% of screen height)
                          decoration: BoxDecoration(
                            color: Colors.white, // White background
                            borderRadius: BorderRadius.circular(30), // Border radius of 30
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: -screenWidth * 0.2, // Small left padding
                                bottom: -screenHeight * 0.05, // Small bottom padding
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8), // Slightly rounded corners for image
                                  child: Image.asset(
                                    'assets/images/notifications.png',
                                    width: screenWidth * 0.7, // Responsive image size
                                    height: screenWidth * 0.7, // Keep it square
                                    fit: BoxFit.contain, // Ensure image scales properly
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: screenWidth * 0.2, // Match image size for error icon
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Position to the right of the image
                                top: screenHeight * 0.022, // Align with image's bottom edge
                                child: Text(
                                  'Notifications',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.045, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Align with Locations text
                                top: screenHeight * 0.070, // Below Locations text
                                child: Text(
                                  'Manage all the app notifications\nhere.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04, // Slightly smaller responsive font size
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.26, // Align with Manage text
                                top: screenHeight * 0.152, // Below Manage text
                                child: Row(
                                  children: [
                                    Text(
                                      'Add/Edit/ notifications here',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04, // Same responsive font size as Manage text
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins', // Consistent with Dashboard Overview
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02), // Responsive separation
                                    Icon(
                                      Icons.double_arrow,
                                      color: Colors.green,
                                      size: screenWidth * 0.08, // Responsive icon size
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.02, // Align near top edge
                                right: screenWidth * 0.02, // Align near right edge
                                child: Container(
                                  width: screenWidth * 0.08, // Responsive circle size
                                  height: screenWidth * 0.08, // Keep it circular
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black, // Black stroke
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.notifications,
                                    color: Colors.black,
                                    size: screenWidth * 0.04, // Responsive icon size
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Menu rectangle
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 300), // Animation duration
                        curve: Curves.easeInOut, // Smooth animation curve
                        left: _isMenuVisible ? 0 : -screenWidth * 0.6, // Slide in from left
                        top: 0, // Adjusted from top: 0
                        child: Container(
                          width: screenWidth * 0.6, // Small, responsive width (60% of screen width)
                          height: screenHeight * 0.8, // Good, responsive height (80% of screen height)
                          decoration: BoxDecoration(
                            color: Colors.white, // White background
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(30),
                              bottomRight: Radius.circular(30), // Added bottom-right border radius of 30
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: Offset(2, 0),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sidebar image with overlaid white circle and text
                              Stack(
                                children: [
                                  Image.asset(
                                    'assets/images/sidebar.png',
                                    width: screenWidth * 0.6, // Full width of the rectangle
                                    height: screenHeight * 0.16, // Responsive height (16% of screen height)
                                    fit: BoxFit.cover, // Stretch to fit width
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.03, // Responsive left padding
                                    top: screenHeight * 0.03, // Responsive top padding
                                    child: Container(
                                      width: screenWidth * 0.15, // Responsive circle size
                                      height: screenWidth * 0.15, // Keep it circular
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white, // White background
                                        border: Border.all(
                                          color: Colors.black, // Black stroke for consistency
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.black,
                                        size: screenWidth * 0.08, // Responsive icon size
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.19, // Position to the right of the circle with small separation
                                    top: screenHeight * 0.05, // Align vertically with the circle
                                    child: Text(
                                      'MUBS Locator',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.05, // Responsive font size
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist', // Urbanist font
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: screenWidth * 0.19, // Align with MUBS Locator horizontally
                                    top: screenHeight * 0.09, // Below MUBS Locator with small separation
                                    child: Text(
                                      fullName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.035, // Smaller responsive font size
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist', // Urbanist font
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Dashboard icon and text
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02), // Responsive padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.dashboard,
                                      color: Colors.black,
                                      size: screenWidth * 0.06, // Responsive icon size
                                    ),
                                    SizedBox(width: screenWidth * 0.02), // Small separation
                                    Text(
                                      'Dashboard',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04, // Responsive font size
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist', // Urbanist font
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02), // Increased vertical spacing
                              // Chat icon and Feedback & Reports text
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02), // Responsive padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat,
                                      color: Colors.black,
                                      size: screenWidth * 0.06, // Responsive icon size
                                    ),
                                    SizedBox(width: screenWidth * 0.02), // Small separation
                                    Text(
                                      'Feedback & Reports',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04, // Responsive font size
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist', // Urbanist font
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02), // Increased vertical spacing
                              // Settings icon and Profile Settings text
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02), // Responsive padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      color: Colors.black,
                                      size: screenWidth * 0.06, // Responsive icon size
                                    ),
                                    SizedBox(width: screenWidth * 0.02), // Small separation
                                    Text(
                                      'Profile Settings',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04, // Responsive font size
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist', // Urbanist font
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02), // Increased vertical spacing
                              // Notifications icon and Push Notifications text
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02), // Responsive padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications,
                                      color: Colors.black,
                                      size: screenWidth * 0.06, // Responsive icon size
                                    ),
                                    SizedBox(width: screenWidth * 0.02), // Small separation
                                    Text(
                                      'Push Notifications',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04, // Responsive font size
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist', // Urbanist font
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02), // Increased vertical spacing
                              // Locations icon and Locations text
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02), // Responsive padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.black,
                                      size: screenWidth * 0.06, // Responsive icon size
                                    ),
                                    SizedBox(width: screenWidth * 0.02), // Small separation
                                    Text(
                                      'Locations',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.04, // Responsive font size
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Urbanist', // Urbanist font
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02), // Increased vertical spacing
                              // Exit icon and Logout text
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02), // Responsive padding
                                child: GestureDetector(
                                  onTap: _logout, // Call logout function on tap
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.exit_to_app,
                                        color: Colors.black,
                                        size: screenWidth * 0.06, // Responsive icon size
                                      ),
                                      SizedBox(width: screenWidth * 0.02), // Small separation
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.04, // Responsive font size
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Urbanist', // Urbanist font
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
            ),
          ],
        ),
      ),
    );
  }
}