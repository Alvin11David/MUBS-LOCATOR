import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/bottom_navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  String _fullName = 'Loading...';
  String _email = 'Loading...';
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadProfileImage();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _email = user.email ?? 'No email';
        });
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          setState(() {
            _fullName = userData['fullName'] as String? ?? 'No name';
            _profilePicUrl = userData['profilePicUrl'] as String?;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullName = 'Error loading name';
          _email = 'Error loading email';
        });
        _showCustomSnackBar('Error fetching user data: $e', Colors.red);
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _profilePicUrl = doc.data()?['profilePicUrl'] as String?;
          });
        }
      } catch (e) {
        //
      }
    }
  }

  Future<void> _onShareAppPressed() async {
    final androidUrl = 'https://play.google.com/store/apps/details?id=com.yourcompany.mubs_locator'; // <-- replace
    final iosUrl = 'https://apps.apple.com/app/idYOUR_APP_ID'; // <-- replace
    final link = Platform.isAndroid ? androidUrl : iosUrl;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Share.share('Check out MUBS Locator:\n$link');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open Store'),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse(link);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  _showCustomSnackBar('Cannot open store page', Colors.red);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy link'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: link));
                Navigator.pop(ctx);
                _showCustomSnackBar('Link copied to clipboard', Colors.green);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomSnackBar(String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    final animation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SlideTransition(
          position: animation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo/logo.png',
                    width: MediaQuery.of(context).size.width * 0.06,
                    height: MediaQuery.of(context).size.width * 0.06,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        controller.reverse().then((_) {
          overlayEntry.remove();
          controller.dispose();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        if (args['profilePicUrl'] != null) {
          _profilePicUrl = args['profilePicUrl'] as String?;
        }
        _fullName = args['fullName'] ?? _fullName;
        _email = args['email'] ?? _email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          color: const Color(0xFF93C5FD),
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
                child: Container(
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
                  child: ClipOval(
                    child: _profilePicUrl != null && _profilePicUrl!.isNotEmpty
                        ? Image.network(
                            _profilePicUrl!,
                            width: screenWidth * 0.25,
                            height: screenWidth * 0.25,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: screenWidth * 0.11,
                              color: Colors.black,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: screenWidth * 0.11,
                            color: Colors.black,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.02,
                left: screenWidth * 0.04,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/HomeScreen');
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
                child: Column(
                  children: [
                    Text(
                      _fullName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Epunda Slab',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      _email,
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
                  child: Padding(
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
                            Navigator.pushNamed(
                              context,
                              '/EditProfileScreen',
                              arguments: {
                                'fullName': _fullName,
                                'email': _email,
                                'profilePicUrl': _profilePicUrl,
                              },
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
                            Navigator.pushNamed(
                              context,
                              '/AboutScreen',
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
                            Navigator.pushNamed(
                              context,
                              '/Terms&PrivacyScreen',
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
                            _onShareAppPressed();
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
                        SizedBox(height: screenHeight * 0.020),
                        _buildMenuItem(
                          icon: Icons.delete_outline,
                          title: 'Delete Account',
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onTap: () {
                            _showDeleteAccountDialog(context);
                          },
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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.02,
          right: MediaQuery.of(context).size.width * 0.02,
          bottom: MediaQuery.of(context).size.height * 0.002,
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.96,
          child: Container(
            color: const Color(0xFF93C5FD),
            child: const BottomNavBar(initialIndex: 3),
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
            color: const Color(0xFF93C5FD),
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
              Icons.chevron_right,
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
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushNamed(context, '/SignInScreen');
                  }
                } catch (e) {
                  if (mounted) {
                    _showCustomSnackBar('Error signing out: $e', Colors.red);
                  }
                }
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
    void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            'Delete Account',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontFamily: 'Poppins',
            ),
          ),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
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
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                );

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final userEmail = user.email;
                    
                    // Delete user data from Firestore
                    final querySnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .where('email', isEqualTo: userEmail)
                        .get();
                    
                    for (var doc in querySnapshot.docs) {
                      await doc.reference.delete();
                    }
                    
                    // Delete the Firebase Auth user
                    await user.delete();
                    
                    // Remove loading dialog and navigate
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Remove loading dialog
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/SignInScreen',
                        (route) => false,
                      );
                    }
                  }
                } catch (e) {
                  // Remove loading dialog
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _showCustomSnackBar('Error deleting account: $e', Colors.red);
                  }
                }
              },
              child: const Text(
                'Delete',
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