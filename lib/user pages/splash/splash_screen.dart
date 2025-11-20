import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _textColorAnimation;

  // Variables to store onboarding & login status
  bool _onboardingComplete = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();

    // Animation Controller for 6 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..forward();

    // Background color tween (black → white after 50%)
    _backgroundColorAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    // Text color tween (white → black after 50%)
    _textColorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.black,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    // Load onboarding & auth status
    _loadAppStatus();

    // Navigate after animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  // Load onboarding & login status from SharedPreferences and Firebase
  Future<void> _loadAppStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    _currentUser = FirebaseAuth.instance.currentUser;
    setState(() {}); // Update state just in case
  }

  // Navigate based on status
  Future<void> _navigateNext() async {
    if (!_onboardingComplete) {
      Navigator.pushReplacementNamed(context, '/OnboardingScreen1');
    } else if (_currentUser != null) {
      // Check if the user is an admin by querying Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      final isAdmin = userDoc.exists && (userDoc.data()?['isAdmin'] ?? false);
      if (isAdmin) {
        Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
      } else {
        Navigator.pushReplacementNamed(context, '/HomeScreen');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/SignInScreen');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: _backgroundColorAnimation.value ?? Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double screenWidth = constraints.maxWidth;
                  double screenHeight = constraints.maxHeight;

                  double rotationAngle = 35.62 * 3.14159 / 180;

                  return Stack(
                    children: [
                      // Logo and text at top (color animated)
                      Positioned(
                        top: screenHeight * 0.02,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/logo/logo.png',
                              width: screenWidth * 0.2,
                              height: screenHeight * 0.1,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'MUBS Locator',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: _textColorAnimation.value ?? Colors.white,
                                fontFamily: 'Poppins',
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 0),
                                    blurRadius: 3.0,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Rotated blue shape with image + texts
                      Positioned(
                        right: -screenWidth * 0.55,
                        top: screenHeight * 0.3,
                        child: Transform.rotate(
                          angle: rotationAngle,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(screenWidth * 0.5),
                              bottomLeft: Radius.circular(screenWidth * 0.5),
                            ),
                            child: Container(
                              width: screenWidth * 1.4,
                              height: screenHeight * 0.37,
                              color: const Color(0xFF007BFF),
                              child: Transform.rotate(
                                angle: -rotationAngle,
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: screenWidth * 0.3,
                                        ),
                                        child: Image.asset(
                                          'assets/images/ambasizejackline.png',
                                          width: screenWidth * 0.6,
                                          height: screenHeight * 0.6,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: screenWidth * 0.12,
                                      top: screenHeight * 0.15,
                                      child: Text(
                                        'AMBASIZE',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.1,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 0),
                                              blurRadius: 3.0,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: screenWidth * 0.42,
                                      top: screenHeight * 0.2,
                                      child: Text(
                                        'JACKLINE',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.09,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 0),
                                              blurRadius: 3.0,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: screenWidth * 0.40,
                                      top: screenHeight * 0.265,
                                      child: Text(
                                        'Bachelor of Leadership and\n Governance',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.030,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Abril Fatface',
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 0),
                                              blurRadius: 3.0,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: screenWidth * 0.69,
                                      top: screenHeight * 0.30,
                                      child: Text(
                                        'Year 2',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontFamily: 'Abril Fatface',
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 0),
                                              blurRadius: 9.0,
                                              color: Colors.white,
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
                        ),
                      ),

                      // Bottom-left message (color animated)
                      Positioned(
                        left: screenWidth * 0.05,
                        bottom: screenHeight * 0.12,
                        child: SizedBox(
                          width: screenWidth * 0.6,
                          child: Text(
                            "Best wishes during \nyour stay at campus. \nMay you find inspiration \nin your studies, build lasting\nconnections for a successful\nfuture.",
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: _textColorAnimation.value ?? Colors.white,
                              fontFamily: 'Poppins',
                              height: 1.4,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 0),
                                  blurRadius: 3.0,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Progress bar
                      Positioned(
                        bottom: screenHeight * 0.03,
                        left: screenWidth * 0.25,
                        right: screenWidth * 0.25,
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.05),
                          child: LinearProgressIndicator(
                            value: _controller.value,
                            minHeight: screenHeight * 0.015,
                            backgroundColor: Colors.black12,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}