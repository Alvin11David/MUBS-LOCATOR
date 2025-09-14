import 'dart:ui';
import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFF93C5FD), // Set background color to #93C5FD
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Positioned(
                top: screenHeight * 0.02, // 2% of screen height for top padding
                left: screenWidth * 0.04, // 4% of screen width for left padding
                child: ClipOval(
                  child: Container(
                    width: screenWidth * 0.15, // Circle size is 15% of screen width
                    height: screenWidth * 0.15, // Keep aspect ratio
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Semi-transparent for glassy effect
                      border: Border.all(
                        color: Colors.white, // White stroke
                        width: screenWidth * 0.002, // Stroke width scales with screen (approx 1px on average)
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.black, // Black icon color
                        size: screenWidth * 0.08, // Icon size is 8% of screen width for responsiveness
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.04, // Align with the top padding of the back icon
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'About The App',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.05,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.10, // Position below the text with some padding
                left: 0,
                right: 90,
                child: Center(
                  child: Image.asset(
                    'assets/images/ambasizejackline.png',
                    width: screenWidth * 1.5, // 50% of screen width for responsiveness
                    height: screenWidth * 1.5 * (9/16), // Maintain aspect ratio (assuming 16:9, adjust if different)
                    fit: BoxFit.contain, // Ensure the image scales properly
                  ),
                ),
              ),
              // Cloud-like rectangle with wavy top, gradient spread, and top shadow
              Positioned(
                top: screenHeight * 0.10 + (screenWidth * 1.5 * (9 / 16)) * 0.6,
                left: 0,
                right: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Shadow layer
                    Container(
                      height: screenHeight * 0.3,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF93C5FD).withOpacity(0.9),
                            offset: const Offset(0, -8), // Shift shadow up
                            blurRadius: 20,
                            spreadRadius: 7,
                          ),
                        ],
                      ),
                    ),
                    // Wavy rectangle with gradient
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 21.7, sigmaY: 21.7),
                        child: CustomPaint(
                          painter: WaveCloudPainter(),
                          child: Container(
                            height: screenHeight * 0.3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF93C5FD),
                                  const Color(0xFF93C5FD).withOpacity(0.7),
                                  const Color(0xFF93C5FD),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Text "Ambasize Jackline" below the image
                    Positioned(
                      top: -(screenHeight * 0.185 - (screenWidth * 1.5 * (9 / 16)) * 0.4), // Position just below the image
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Ambasize Jackline',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.06, // Responsive font size
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                    ),
                    // Text "I am a year 2 student pursuing a bachelor's degree in Leadership and Governance" below
                    Positioned(
                      top: (screenHeight * 0.099999 - (screenWidth * 1.5 * (9 / 16)) * 0.4) + screenHeight * 0.08, // Below the first text with padding
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'I am a year 2 student\n pursuing a bachelor\'s degree\n in Leadership and\n Governance.',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.05, // Responsive font size
                          ),
                          textAlign: TextAlign.center, // Ensure text wraps and centers
                        ),
                      ),
                    ),
                    // Glassy rectangle below the second text with reduced width
                    Positioned(
                      top: (screenHeight * 0.099999 - (screenWidth * 1.5 * (9 / 16)) * 0.15) + screenHeight * 0.14, // Below the second text with padding
                      left: 0,
                      right: 0,
                      child: Stack(
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  height: screenHeight * 0.25, // Responsive height
                                  width: screenWidth * 0.8, // Reduced to 80% of screen width
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Text quotation mark at the top of the glassy rectangle
                          Positioned(
                            top: 0, // Small padding from the top
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                '"',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.2, // Responsive font size
                                  fontFamily: 'Epunda Slab',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Text "Navigate MUBS with ease, your success is our guide" below the quotation mark
                          Positioned(
                            top: screenHeight * 0.09, // Padding below the quotation mark
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                'Navigate MUBS with ease,\n your success is our guide.',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.042, // Responsive font size
                                  fontFamily: 'Urbanist',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Text "Ambasize Jackline" below the quote
                          Positioned(
                            top: screenHeight * 0.19, // Padding below the quote
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                'Ambasize Jackline',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.05, // Responsive font size
                                  fontFamily: 'Epunda Slab',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for wavy cloud-like top
class WaveCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0); // Start at the top-left

    // Create a wavy pattern
    final waveHeight = size.height * 0.1; // 10% of container height for wave amplitude
    final waveCount = (size.width / (size.width * 0.1)).floor(); // Number of waves based on width
    for (int i = 0; i <= waveCount; i++) {
      final x = i * size.width * 0.1;
      path.quadraticBezierTo(
        x + size.width * 0.05, // Control point x
        i.isEven ? -waveHeight : waveHeight, // Vary y for wave effect
        x + size.width * 0.1, // End point x
        0, // Back to baseline y
      );
    }

    path.lineTo(size.width, size.height); // Draw down to bottom-right
    path.lineTo(0, size.height); // Draw to bottom-left
    path.close(); // Close the path to fill

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}