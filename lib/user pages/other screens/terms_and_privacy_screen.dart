import 'package:flutter/material.dart';
import 'dart:ui';

class TermsAndPrivacyScreen extends StatefulWidget {
  const TermsAndPrivacyScreen({super.key});

  @override
  State<TermsAndPrivacyScreen> createState() => _TermsAndPrivacyScreenState();
}

class _TermsAndPrivacyScreenState extends State<TermsAndPrivacyScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double mubsVerticalOffset = screenHeight * 0.05;
    final double locatorVerticalOffset = screenHeight * 0.08;

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: Stack(
        children: [
          // Top glass container with logo, MUBS, and Locator
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.15,
              width: screenWidth,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logo/logo.png',
                          height: screenHeight * 0.08,
                          width: screenWidth * 0.3,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: mubsVerticalOffset,
                        left: screenWidth * -0.15,
                        right: screenWidth * 0.2,
                        child: const Text(
                          'MUBS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        top: locatorVerticalOffset,
                        left: screenWidth * 0.6,
                        child: Stack(
                          children: [
                            Text(
                              'Locator',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 25,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2
                                  ..color = Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Text(
                              'Locator',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 25,
                                color: Colors.transparent,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Back button for navigation
          Positioned(
            top: screenHeight * 0.04,
            left: screenWidth * 0.04,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: ClipOval(
                child: Container(
                  width: screenWidth * 0.13,
                  height: screenWidth * 0.13,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white,
                      width: screenWidth * 0.006,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: screenWidth * 0.08,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Main title: Terms & Conditions
          Positioned(
            top: screenHeight * 0.18,
            left: 0,
            right: 0,
            child: const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Bottom glass container with terms sections
          Positioned(
            top: screenHeight * 0.25,
            left: 4,
            right: 4,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Introduction',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'By using MUBS Locator, you agree to the following terms and conditions governing your use of the application and its services.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 1,
                          width: screenWidth - 32,
                          color: const Color(0xFF000000),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Account & Data',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Responsibility for account security.\nHandling of user data.\nHow the app uses location and content.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 1,
                          width: screenWidth - 32,
                          color: const Color(0xFF000000),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Third-Party Services',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use of Google Maps, Firebase, or other tools\nLinks to their own terms (optional)',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 1,
                          width: screenWidth - 32,
                          color: const Color(0xFF000000),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Contact Us',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: 24,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: 'If you have any questions about these terms, contact us at: ',
                              ),
                              TextSpan(
                                text: 'alvin69david@gmail.com',
                                style: TextStyle(
                                  color: Color(0xFF077501),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}