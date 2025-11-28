import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amba_locator/user%20pages/intro/onboarding_screen1.dart';
import 'package:amba_locator/user%20pages/intro/onboarding_screen2.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreen3 extends StatefulWidget {
  const OnboardingScreen3({super.key});

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3>
    with TickerProviderStateMixin {
  late final ValueNotifier<double> _animationValue;
  late final AnimationController _controller;
  late final AnimationController _indicatorController;
  int currentPage = 3;

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

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationValue.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  // ✅ Mark onboarding as completed
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
  }

  static const String APK_URL =
      'https://mubs-locator.web.app/apk/MUBS_Locator.apk'; // TODO: replace

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
            image: AssetImage('assets/images/onboarding_screen3.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double screenHeight = constraints.maxHeight;

              final Animation<double> indicatorAnimation =
                  Tween<double>(
                      begin: screenWidth * 0.04,
                      end: screenWidth * 0.06,
                    ).animate(
                      CurvedAnimation(
                        parent: _indicatorController,
                        curve: Curves.easeInOut,
                      ),
                    )
                    ..addListener(() {
                      setState(() {});
                    });

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
                  Positioned(
                    top: screenHeight * 0.02,
                    left: 0,
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
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.012,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.download_rounded,
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
                          'Stay Updated.',
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
                          'Receive important updates\nand alerts directly in the\napp.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.076),
                        // Page indicators
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: currentPage == 1
                                  ? indicatorAnimation.value
                                  : screenWidth * 0.04,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: currentPage == 1
                                    ? Colors.white
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: currentPage == 2
                                  ? indicatorAnimation.value
                                  : screenWidth * 0.04,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: currentPage == 2
                                    ? Colors.white
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: currentPage == 3
                                  ? indicatorAnimation.value
                                  : screenWidth * 0.04,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: currentPage == 3
                                    ? Colors.white
                                    : Colors.grey,
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
                        if (currentPage > 1) {
                          currentPage--;
                          _indicatorController.reset();
                          _indicatorController.forward();
                          if (currentPage == 2) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen2(),
                                settings: const RouteSettings(
                                  name: '/OnboardingScreen2',
                                ),
                              ),
                            );
                          } else if (currentPage == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen1(),
                                settings: const RouteSettings(
                                  name: '/OnboardingScreen1',
                                ),
                              ),
                            );
                          }
                        }
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
                  // Start button (final)
                  Positioned(
                    bottom: screenHeight * 0.02,
                    left: screenWidth * 0.20,
                    child: GestureDetector(
                      onTap: () async {
                        await _completeOnboarding();
                        Navigator.pushReplacementNamed(
                          context,
                          '/SignInScreen',
                        );
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
                                              right: screenWidth * 0.01,
                                            ),
                                            child: Transform.scale(
                                              scale: 1.5,
                                              child: Icon(
                                                Icons.chevron_right,
                                                size: screenWidth * 0.08,
                                                color: Color.lerp(
                                                  Colors.white,
                                                  Colors.orangeAccent,
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
