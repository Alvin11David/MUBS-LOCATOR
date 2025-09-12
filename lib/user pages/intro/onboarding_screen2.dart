import 'package:flutter/material.dart';

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
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
                            // Inactive
                            Container(
                              width: screenWidth * 0.04,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02), // Spacing between indicators
                            // Active (first one)
                            Container(
                              width: screenWidth * 0.06,
                              height: screenHeight * 0.01,
                              decoration: BoxDecoration(
                                color: Colors.white,
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