import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> with SingleTickerProviderStateMixin {
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
                    top: screenHeight * 0.02, // 2% from top for padding
                    left: screenWidth * 0.02, // 2% from left for padding
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo/logo.png',
                          width: screenWidth * 0.1, // 10% of screen width
                          height: screenHeight * 0.1, // 10% of screen height
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 4), // Small width of 4 pixels
                        Text(
                          'MUBS Locator',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04, // Responsive font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Skip button at top right
                  Positioned(
                    top: screenHeight * 0.02, // 2% from top for padding
                    right: screenWidth * 0.02, // 2% from right for padding
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
                          fontSize: screenWidth * 0.04, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                    ),
                  ),
                  // Locate any building fast text at center left
                  Positioned(
                    top: screenHeight * 0.6, // Centered vertically, adjusted for alignment
                    left: screenWidth * 0.05, // 5% from left for padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Locate any\nbuilding fast.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: screenWidth * 0.08, // Responsive font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Abril Fatface',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02), // Small spacing between texts
                        Text(
                          'Search for lecture blocks,\ndepartments or service in\nseconds.',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05, // Responsive font size (smaller for subtitle)
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03), // Spacing for page indicator
                        // Page indicator: 3 rounded rectangles
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Active (first one)
                            Container(
                              width: screenWidth * 0.06,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02), // Spacing between indicators
                            // Inactive
                            Container(
                              width: screenWidth * 0.04,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            // Inactive
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
                  // Deactivated next button: black circle with white chevron, low opacity
                  Positioned(
                    bottom: screenHeight * 0.02, // 2% from bottom for padding
                    left: screenWidth * 0.05, // 5% from left for padding
                    child: Opacity(
                      opacity: 0.3, // Low opacity for deactivated state
                      child: Container(
                        width: screenWidth * 0.15, // Responsive size (13% of screen width)
                        height: screenWidth * 0.15, // Square for circle
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: screenWidth * 0.08, // Responsive icon size
                        ),
                      ),
                    ),
                  ),
                  // Glassy rectangle with 30 border radius and white stroke to the right of the circle
                  Positioned(
                    bottom: screenHeight * 0.02, // Same vertical position as circle
                    left: screenWidth * 0.20, // Adjusted to right of circle (0.05 + 0.13 + small gap)
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/OnboardingScreen2');
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30), // 30 border radius
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Strong blur for glassy effect
                          child: Container(
                            width: screenWidth * 0.76, // Responsive width
                            height: screenWidth * 0.15, // Same height as circle for responsiveness
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2), // Very glassy with low opacity
                              border: Border.all(
                                color: Colors.white, // White stroke
                                width: 1, // Stroke width (adjust as needed)
                              ),
                              borderRadius: BorderRadius.circular(30), // Ensure border radius matches
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Pushes "Start" left, chevrons right
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: screenWidth * 0.3), // Shift "Start" right
                                  child: Text(
                                    'Start',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06, // Responsive font size
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Animated chevrons on the right
                                AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) {
                                    return Row(
                                      children: [
                                        for (int i = 0; i < 3; i++)
                                          Padding(
                                            padding: EdgeInsets.only(right: screenWidth * 0.02),
                                            child: Transform.scale(
                                              scale: 1.5, // Slightly larger icons
                                              child: Icon(
                                                Icons.chevron_right,
                                                size: screenWidth * 0.08, // Responsive icon size
                                                color: Color.lerp(
                                                  Colors.white, // Start color
                                                  Colors.orange, // End color
                                                  math.sin(_animationValue.value * math.pi * 2 + i * math.pi / 3) * 0.5 + 0.5, // Wave effect
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
                  // White circle with black chevron_right icon on the left of the rectangle
                  Positioned(
                    bottom: screenHeight * 0.02, // Same vertical position as circle and rectangle
                    left: screenWidth * 0.20, // Aligned with the left edge of the rectangle
                    child: Container(
                      width: screenWidth * 0.15, // Same size as the black circle for consistency
                      height: screenWidth * 0.15, // Same height as circle and rectangle
                      decoration: BoxDecoration(
                        color: Colors.white, // White circle
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right, // Black chevron_right icon
                        color: Colors.black,
                        size: screenWidth * 0.08, // Responsive icon size
                      ),
                    ),
                  ),
                  Container(), // Placeholder for future content
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}