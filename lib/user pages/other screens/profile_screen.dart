import 'package:flutter/material.dart';
import '/components/bottom_navbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          color: const Color(0xFF93C5FD), // Background color
          child: Stack(
            children: [
              // Glassy water rectangle (top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Glassy effect
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
              // Profile picture circle
              Positioned(
                top: screenHeight * 0.015,
                left: (screenWidth - screenWidth * 0.25) / 2, // Center horizontally
                child: Container(
                  width: screenWidth * 0.25,
                  height: screenWidth * 0.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2), // Glassy effect
                    border: Border.all(
                      color: Colors.white, // White stroke
                      width: screenWidth * 0.006, // Stroke width scales
                    ),
                  ),
                  child: ClipOval(
                    child: Container(
                      child: Icon(
                        Icons.person,
                        size: screenWidth * 0.11,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              // Back button
              Positioned(
                top: screenHeight * 0.02,
                left: screenWidth * 0.04,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Navigate to previous screen
                  },
                  child: ClipOval(
                    child: Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // Glassy effect
                        border: Border.all(
                          color: Colors.white, // White stroke
                          width: screenWidth * 0.006, // Stroke width scales
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left, // Updated to chevron_left
                          color: Colors.black,
                          size: screenWidth * 0.08,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Profile name and email
              Positioned(
                top: screenHeight * 0.19,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Epunda Slab',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      'example@gmail.com',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                  ],
                ),
              ),
              // Glassy water rectangle for menu
              Positioned(
                top: screenHeight * 0.31,
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
                child: Container(
                  height: screenHeight * 0.69,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), // Glassy effect
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white, // White stroke
                      width: 1, // Fixed stroke width
                    ),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.02,
                        ),
                        child: ListView(
                          padding: EdgeInsets.only(bottom: screenHeight * 0.102),
                          physics: const ClampingScrollPhysics(),
                          children: [
                            _buildMenuItem(
                              icon: Icons.person_outline,
                              title: 'Edit Profile',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit Profile tapped')),
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.020),
                            _buildMenuItem(
                              icon: Icons.info_outline,
                              title: 'About the App',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('About the App tapped')),
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.020),
                            _buildMenuItem(
                              icon: Icons.description_outlined,
                              title: 'Terms & Privacy',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Terms & Privacy tapped')),
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.020),
                            _buildMenuItem(
                              icon: Icons.share_outlined,
                              title: 'Share App',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Share App tapped')),
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.020),
                            _buildMenuItem(
                              icon: Icons.logout_outlined,
                              title: 'Logout',
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              onTap: () {
                                _showLogoutDialog(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: screenHeight * 0.002,
                        left: 0,
                        right: 0,
                        child: BottomNavBar(initialIndex: 3),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required double screenWidth,
    required double screenHeight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.016,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFFD59A00),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              spreadRadius: 0.5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: screenWidth * 0.055),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Icon(
              Icons.chevron_right, // Corrected to chevron_right for menu items
              color: Colors.black.withOpacity(0.6),
              size: screenWidth * 0.035,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logout successful')),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}