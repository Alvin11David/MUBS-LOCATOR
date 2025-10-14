import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

class TermsAndPrivacyScreen extends StatefulWidget {
  const TermsAndPrivacyScreen({super.key});

  @override
  State<TermsAndPrivacyScreen> createState() => _TermsAndPrivacyScreenState();
}

class _TermsAndPrivacyScreenState extends State<TermsAndPrivacyScreen> {
  // Function to launch email client with preloaded email address
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email client')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaler = MediaQuery.textScalerOf(context);
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
              padding: EdgeInsets.all(screenWidth * 0.01),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(screenWidth * 0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: screenWidth * 0.002,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: screenWidth * 0.025,
                    spreadRadius: screenWidth * 0.005,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(screenWidth * 0.075),
                  bottomRight: Radius.circular(screenWidth * 0.075),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: screenWidth * 0.0125, sigmaY: screenWidth * 0.0125),
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
                        left: -screenWidth * 0.15,
                        right: screenWidth * 0.2,
                        child: Text(
                          'MUBS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: textScaler.scale(screenWidth * 0.055),
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
                                fontSize: textScaler.scale(screenWidth * 0.055),
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = screenWidth * 0.002
                                  ..color = Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              'Locator',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: textScaler.scale(screenWidth * 0.045),
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
            child: Text(
              'Terms & Conditions',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: textScaler.scale(screenWidth * 0.05),
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Bottom glass container with terms sections
          Positioned(
            top: screenHeight * 0.25,
            left: screenWidth * 0.01,
            right: screenWidth * 0.01,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(screenWidth * 0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: screenWidth * 0.002,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: screenWidth * 0.025,
                    spreadRadius: screenWidth * 0.005,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.1),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: screenWidth * 0.0125, sigmaY: screenWidth * 0.0125),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.02,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Introduction',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: textScaler.scale(screenWidth * 0.045),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'By using MUBS Locator, you agree to the following terms and conditions governing your use of the application and its services.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: textScaler.scale(screenWidth * 0.035),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Container(
                            height: screenHeight * 0.001,
                            width: screenWidth * 0.9,
                            color: const Color(0xFF000000),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Account & Data',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: textScaler.scale(screenWidth * 0.045),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Responsibility for account security.\nHandling of user data.\nHow the app uses location and content.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: textScaler.scale(screenWidth * 0.035),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Container(
                            height: screenHeight * 0.001,
                            width: screenWidth * 0.9,
                            color: const Color(0xFF000000),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Third-Party Services',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: textScaler.scale(screenWidth * 0.045),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Use of Maps, Firebase, or other tools',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: textScaler.scale(screenWidth * 0.035),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Container(
                            height: screenHeight * 0.001,
                            width: screenWidth * 0.9,
                            color: const Color(0xFF000000),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: textScaler.scale(screenWidth * 0.045),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: textScaler.scale(screenWidth * 0.035),
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: 'If you have any questions about these terms, contact us at: ',
                                ),
                                TextSpan(
                                  text: 'alvin69david@gmail.com',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 20, 111, 36),
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      _launchEmail('alvin69david@gmail.com');
                                    },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
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