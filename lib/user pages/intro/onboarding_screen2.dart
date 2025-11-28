import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amba_locator/user%20pages/intro/onboarding_screen1.dart';

class OnboardingScreen2 extends StatefulWidget {
  const OnboardingScreen2({super.key});

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _animationValue;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _animationValue = ValueNotifier(0.0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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

  // ✅ Mark onboarding as completed
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
  }

  static const String APK_URL = 'https://mubs-locator.web.app/apk/MUBS_Locator.apk'; // TODO: replace

  Future<void> _downloadApk() async {
    await Permission.storage.request();
    await Permission.notification.request();

    const downloadsDir = '/storage/emulated/0/Download';

    final taskId = await FlutterDownloader.enqueue(
      url: APK_URL,
      savedDir: downloadsDir,
      showNotification: true,
      openFileFromNotification: true,
      fileName: 'MUBS_Locator.apk',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(taskId != null ? 'Downloading APK… Check notifications.' : 'Failed to start download.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/onboarding_screen2.png'),
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
                  // Logo
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
                  // Skip button
                  Positioned(
                    top: screenHeight * 0.02,
                    right: screenWidth * 0.02,
                    child: GestureDetector(
                      onTap: () async {
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
                  // Text content
                  Positioned(
                    top: screenHeight * 0.6,
                    left: screenWidth * 0.05,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Navigate Campus\nEasily.',
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
                          'Never get lost. Find the\nquickest path to your\ndestination.',
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
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Container(
                              width: screenWidth * 0.04,
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Back button
                  Positioned(
                    bottom: screenHeight * 0.02,
                    left: screenWidth * 0.05,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen1(),
                            settings: const RouteSettings(
                              name: '/OnboardingScreen1',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: screenWidth * 0.15,
                        height: screenWidth * 0.15,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: screenWidth * 0.08,
                        ),
                      ),
                    ),
                  ),
                  // Next/Start button
                  Positioned(
                    bottom: screenHeight * 0.02,
                    left: screenWidth * 0.20,
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pushNamed(context, '/OnboardingScreen3');
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: screenWidth * 0.78,
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
                  // White circle left of the rectangle
                  Positioned(
                    bottom: screenHeight * 0.02,
                    left: screenWidth * 0.20,
                    child: Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.black,
                        size: screenWidth * 0.08,
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
