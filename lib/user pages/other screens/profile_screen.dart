import 'package:flutter/material.dart';
// Remove the bottom navbar import for now to fix the path issue
// import '../components/bottom_navbar.dart'; 

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Main background container - full screen with main blue color
              Container(
                width: screenWidth,
                height: screenHeight,
                color: const Color(0xFF3B82F6),
                child: const SizedBox(),
              ),

              // Back button
              Positioned(
                top: screenHeight * 0.05,
                left: screenWidth * 0.04,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: screenWidth * 0.05,
                      ),
                    ),
                  ),
                ),
              ),

              // Profile section in outer container (main blue background)
              Positioned(
                top: screenHeight * 0.15,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Profile picture
                    Container(
                      width: screenWidth * 0.25,
                      height: screenWidth * 0.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: screenWidth * 0.12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.015),
                    
                    // Name
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      'example@gmail.com',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.black54,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              // Inner container that houses only the menu items (paler blue)
              Positioned(
                top: screenHeight * 0.4,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                child: Container(
                  height: screenHeight * 0.6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF93C5FD),
                        const Color(0xFF93C5FD).withOpacity(0.7), // Paler shade
                        const Color(0xFF93C5FD),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.03,
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Column(
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
                        
                        SizedBox(height: screenHeight * 0.02),
                        
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
                        
                        SizedBox(height: screenHeight * 0.02),
                        
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
                        
                        SizedBox(height: screenHeight * 0.02),
                        
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
                        
                        SizedBox(height: screenHeight * 0.02),
                        
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
                ),
              ),
            ],
          );
        },
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
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFFD59A00), // Gold border
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.black,
              size: screenWidth * 0.06,
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black.withOpacity(0.6),
              size: screenWidth * 0.04,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
