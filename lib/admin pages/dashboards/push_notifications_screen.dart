import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'dart:ui';

class EmptyNotificationsScreen extends StatefulWidget {
  const EmptyNotificationsScreen({super.key});

  @override
  State<EmptyNotificationsScreen> createState() => _EmptyNotificationsScreenState();
}

class _EmptyNotificationsScreenState extends State<EmptyNotificationsScreen> with SingleTickerProviderStateMixin {
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

  // State for menu visibility
  bool _isMenuVisible = false;
  bool _isRectangleVisible = true; // State for rectangle animation

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

  @override
  void initState() {
    super.initState();
    // Trigger animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isRectangleVisible = true;
      });
    });
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
            _isMenuVisible = false; // Close menu when tapping outside
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
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
                                Icons.notifications_outlined,
                                color: Colors.black,
                                size: screenWidth * 0.04,
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
            // Push Notifications text and subtitle
            Positioned(
              top: screenHeight * 0.1,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Manage all the app notifications.',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // White container
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              top: screenHeight * 0.19,
              left: _isRectangleVisible
                  ? screenWidth * 0.04
                  : -screenWidth * 0.9,
              child: Container(
                width: screenWidth * 0.92,
                height: screenHeight * 0.80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      // Add Notification button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: screenWidth * 0.04,
                            ),
                            child: Container(
                              width: screenWidth * 0.44,
                              height: screenHeight * 0.06,
                              decoration: BoxDecoration(
                                color: const Color(0xFF93C5FD),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: screenWidth * 0.02),
                                    child: Container(
                                      width: screenWidth * 0.06,
                                      height: screenWidth * 0.06,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.black,
                                          size: screenWidth * 0.04,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Add Notification',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.031,
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Empty state content
                      Container(
                        height: screenHeight * 0.72,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/mailbox.png',
                              width: screenWidth * 0.25,
                              height: screenWidth * 0.25,
                              color: const Color(0xFF93C5FD), // Blue color for mailbox
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.055, // ~22 pixels
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Your notifications will appear here once you’ve received them.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.05, // ~20 pixels
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
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
            // Menu rectangle
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isMenuVisible ? 0 : -screenWidth * 0.6,
              top: 0,
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
                    // Sidebar image with overlaid white circle and text
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
                    // Dashboard icon and text
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
                    // Chat icon and Feedback & Reports text
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
                    // Settings icon and Profile Settings text
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
                    // Notifications icon and Push Notifications text
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
                    // Locations icon and Locations text
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
                    // Exit icon and Logout text
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
    );
  }
}