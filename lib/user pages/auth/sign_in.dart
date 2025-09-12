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
              // "Ambasize" at top left
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
              // "Jackline" at top right
              Positioned(
                top: screenHeight * 0.09, // 9% from the top for padding
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
              // "Let's get you\nsigned in" below the logo
              Positioned(
                top: screenHeight * 0.05 + screenHeight * 0.1 + screenHeight * 0.02, // Below logo (5% top + 10% logo height + 2% padding)
                left: screenWidth * 0.5 - (screenWidth * 0.3) / 2, // Center horizontally (half screen width minus half text width approximation)
                child: Text(
                  'Let\'s get you\nsigned in',
                  textAlign: TextAlign.center, // Center the text
                  style: TextStyle(
                    fontSize: screenWidth * 0.06, // 6% of screen width for responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Montserrat', // Assuming "Monstreal" was a typo for Montserrat
                  ),
                ),
              ),
              // White rectangle with 30 border radius below the text
              Positioned(
                top: screenHeight * 0.1 + screenHeight * 0.1 + screenHeight * 0.02 + screenHeight * 0.08, // Below text (adjust based on text height)
                left: screenWidth * 0.02, // 2% left padding
                right: screenWidth * 0.02, // 2% right padding
                child: Container(
                  height: screenHeight * 0.69, // 69% of screen height for responsiveness (adjust as needed)
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30), // 30 border radius
                  ),
                  child: Stack(
                    children: [
                      // "Sign In" at top center of the rectangle
                      Positioned(
                        top: screenHeight * 0.01, // 1% padding from the top of the rectangle
                        left: screenWidth * 0.55 - (screenWidth * 0.3) / 2, // Center horizontally (approximate width of 30%)
                        child: Text(
                          'Sign In',
                          textAlign: TextAlign.center, // Center the text
                          style: TextStyle(
                            fontSize: screenWidth * 0.06, // 6% of screen width for responsive font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Epunda Slab',
                          ),
                        ),
                      ),
                    ],
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