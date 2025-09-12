import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double screenHeight = constraints.maxHeight;

              double rotationAngle = 35.62 * 3.14159 / 180;

              return Stack(
                children: [
                  // ✅ Background (drawn first so everything stays visible)
                  Container(
                    width: screenWidth,
                    height: screenHeight,
                    color: Colors.black,
                  ),

                  // ✅ Logo and "MUBS Locator" text (on top of background)
                  Positioned(
                    top: screenHeight * 0.02, // Slight padding from top
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo/logo.png',
                          width: screenWidth * 0.2,
                          height: screenHeight * 0.1,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          'MUBS Locator',
                          style: TextStyle(
                            fontSize: screenWidth * 0.06,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            shadows: [
                              Shadow(
                                offset: Offset(0, 0),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ Rotated blue shape with image + texts
                  Positioned(
                    right: -screenWidth * 0.55,
                    top: screenHeight * 0.3,
                    child: Transform.rotate(
                      angle: rotationAngle,
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(screenWidth * 0.5),
                          bottomLeft: Radius.circular(screenWidth * 0.5),
                        ),
                        child: Container(
                          width: screenWidth * 1.4,
                          height: screenHeight * 0.37,
                          color: const Color(0xFF007BFF),

                          // Counter-rotate children so they appear straight
                          child: Transform.rotate(
                            angle: -rotationAngle,
                            child: Stack(
                              children: [
                                // Image
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: screenWidth * 0.3,
                                    ),
                                    child: Image.asset(
                                      'assets/images/ambasizejackline.png',
                                      width: screenWidth * 0.6,
                                      height: screenHeight * 0.6,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                // Texts over the image
                                Positioned(
                                  left: screenWidth * 0.12,
                                  top: screenHeight * 0.15,
                                  child: Text(
                                    'AMBASIZE',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.1,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 0),
                                          blurRadius: 3.0,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.42,
                                  top: screenHeight * 0.2,
                                  child: Text(
                                    'JACKLINE',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.09,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 0),
                                          blurRadius: 3.0,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.40,
                                  top: screenHeight * 0.265,
                                  child: Text(
                                    'Bachelor of Leadership and\n Governance',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.039,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Abril Fatface',
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 0),
                                          blurRadius: 3.0,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.69,
                                  top: screenHeight * 0.30,
                                  child: Text(
                                    'Year 2',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontFamily: 'Abril Fatface',
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 0),
                                          blurRadius: 9.0,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
