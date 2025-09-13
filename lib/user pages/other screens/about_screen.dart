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
      backgroundColor: const Color(0xFF93C5FD), // Set entire Scaffold background to #93C5FD
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned(
              top: screenHeight * 0.05, // Adjusted to 5% for a more standard top position
              left: screenWidth * 0.04,
              child: ClipOval(
                child: Container(
                  width: screenWidth * 0.12, // Reduced size to 12% of screen width
                  height: screenWidth * 0.12, // Reduced size to 12% of screen width
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1E8FF), // Light blue background
                    border: Border.all(
                      color: Colors.white, // White outline
                      width: screenWidth * 0.002,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: screenWidth * 0.06, // Reduced icon size to 6% of screen width
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}