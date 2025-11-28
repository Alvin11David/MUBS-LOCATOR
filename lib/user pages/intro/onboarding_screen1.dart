import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _animationValue;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _animationValue = ValueNotifier(0.0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Animation cycle duration
    )..repeat(); // Repeat the animation indefinitely
    _controller.addListener(() {
      _animationValue.value = _controller.value;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationValue.dispose();
    super.dispose();
  }

  // ✅ Save onboarding as completed
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
  }

  static const String APK_URL =
      'https://mubs-locator.web.app/apk/MUBS_Locator.apk'; 

  Future<void> _downloadApk() async {
  final uri = Uri.parse(APK_URL);
    // Try platform default first (lets Android pick a browser)
    var ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok) {
      // Fallback to external app
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/onboarding_screen1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double screenHeight = constraints.maxHeight;

              return Stack(
                children: [
                  // Logo and MUBS Locator at top left
                  Positioned(
                    top: screenHeight * 0.02,
                    left: screenWidth * 0.02,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo/logo.png',
                          width: screenWidth * 0.1,
                          height: screenHeight * 0.1,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MUBS Locator',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              'lee9ine.',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.white,
                                fontFamily: 'Reem Kufi',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Skip button at top right
                  Positioned(
                    top: screenHeight * 0.02,
                    right: screenWidth * 0.02,
                    child: GestureDetector(
                      onTap: () async {
                        // Save onboarding completed when skipped
                        await _completeOnboarding();
                        Navigator.pushReplacementNamed(
                          context,
                          '/SignInScreen',
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                    ),
                  ),
                  //Install App Button 
                  Positioned(
                    top: screenHeight * 0.02,
                    left: screenWidth * 0.25,
                    right: 0,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: GestureDetector(
                            onTap: _downloadApk,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.01,
                                vertical: screenHeight * 0.012,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white, width: 1.5),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone_iphone,
                                    color: Colors.white,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Install App',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.039,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Urbanist',
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
                  // Locate any building fast text
                  Positioned(
                    top: screenHeight * 0.6,
                    left: screenWidth * 0.05,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Locate any\nbuilding fast.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: screenWidth * 0.08,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Abril Fatface',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Search for lecture blocks,\ndepartments or service in\nseconds.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: screenWidth * 0.06,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Container(
                              width: screenWidth * 0.04,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Container(
                              width: screenWidth * 0.04,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Next button
                  Positioned(
                    bottom: screenHeight * 0.02,
                    left: screenWidth * 0.20,
                    child: GestureDetector(
                      onTap: () async {
                        // Complete onboarding only after last screen (we can also save here to be safe)
                        // For now, navigating to Screen2
                        Navigator.pushReplacementNamed(
                          context,
                          '/OnboardingScreen2',
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: screenWidth * 0.76,
                            height: screenWidth * 0.15,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.3,
                                  ),
                                  child: Text(
                                    'Start',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    return Row(
                                      children: [
                                        for (int i = 0; i < 3; i++)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              right: screenWidth * 0.02,
                                            ),
                                            child: Transform.scale(
                                              scale: 1.5,
                                              child: Icon(
                                                Icons.chevron_right,
                                                size: screenWidth * 0.08,
                                                color: Color.lerp(
                                                  Colors.white,
                                                  Colors.orange,
                                                  math.sin(
                                                            _animationValue
                                                                        .value *
                                                                    math.pi *
                                                                    2 +
                                                                i * math.pi / 3,
                                                          ) *
                                                          0.5 +
                                                      0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
