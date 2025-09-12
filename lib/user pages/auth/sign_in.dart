import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              Container(
                width: screenWidth,
                height: screenHeight,
                color: const Color(0xFF93C5FD), // Background color #93C5FD
                child: const Center(
                  child: Placeholder(),
                ),
              ),
              Positioned(
                top: screenHeight * 0.05, // 5% from the top for padding
                left: screenWidth * 0.5 - (screenWidth * 0.2) / 2, // Center horizontally for logo
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: screenWidth * 0.2, // 20% of screen width for responsiveness
                  height: screenHeight * 0.1, // 10% of screen height for responsiveness
                  fit: BoxFit.contain, // Ensures the image scales without distortion
                ),
              ),
              // "Jackline" at top left
              Positioned(
                top: screenHeight * 0.02, // 2% from the top for padding
                left: screenWidth * 0.02, // 2% from the left for padding
                child: Text(
                  'Ambasize',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05, // 5% of screen width for responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Abril Fatface', // Ensure this font is defined in pubspec.yaml
                  ),
                ),
              ),
              // "Ambisize" at top right
              Positioned(
                top: screenHeight * 0.09, // 2% from the top for padding
                right: screenWidth * 0.02, // 2% from the right for padding
                child: Text(
                  'Jackline',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05, // 5% of screen width for responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Abril Fatface', // Ensure this font is defined in pubspec.yaml
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}