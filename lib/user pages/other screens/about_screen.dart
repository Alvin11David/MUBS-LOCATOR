import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Auto-slide every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % 4; // 4 rectangles
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });

    // Initialize ripple animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut),
    )..addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: const Color(0xFF93C5FD),
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // ---- Back button ----
              Positioned(
                top: screenHeight * 0.02,
                left: screenWidth * 0.04,
                child: ClipOval(
                  child: Container(
                    width: screenWidth * 0.15,
                    height: screenWidth * 0.15,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white,
                        width: screenWidth * 0.002,
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
              // ---- Title ----
              Positioned(
                top: screenHeight * 0.04,
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
              // ---- Image ----
              Positioned(
                top: screenHeight * 0.10,
                left: 0,
                right: 90,
                child: Center(
                  child: Image.asset(
                    'assets/images/ambasizejackline.png',
                    width: screenWidth * 1.5,
                    height: screenWidth * 1.5 * (9 / 16),
                    fit: BoxFit.contain,
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
                      height: screenHeight * 0.6, // Extended to cover carousel area
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF93C5FD).withOpacity(0.9),
                            offset: const Offset(0, -8),
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
                            height: screenHeight * 0.6, // Extended to cover carousel area
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
                      top: -(screenHeight * 0.185 - (screenWidth * 1.5 * (9 / 16)) * 0.4),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Ambasize Jackline',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.06,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                    ),
                    // Text "I am a year 2 student pursuing a bachelor's degree in Leadership and Governance" below
                    Positioned(
                      top: (screenHeight * 0.099999 - (screenWidth * 1.5 * (9 / 16)) * 0.35) + screenHeight * 0.08,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'I am a year 2 student\n pursuing a bachelor\'s degree\n in Leadership and\n Governance.',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w200,
                            fontSize: screenWidth * 0.05,
                            fontFamily: 'Urbanist',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // ---- Carousel area ----
                    Positioned(
                      top: screenHeight * 0.14, // Adjusted to avoid overlap with text
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: screenHeight * 0.4, // Adjusted height for carousel
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return _buildGlassyRectangle(screenWidth, screenHeight, index);
                          },
                        ),
                      ),
                    ),
                    // ---- "Get In Touch" text below the carousel ----
                    Positioned(
                      top: screenHeight * 0.49, // Below the carousel (0.14 + 0.4)
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Get In Touch',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.05, // Responsive font size
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                    ),
                    // ---- Three white circles with icons below "Get In Touch" ----
                    Positioned(
                      top: screenHeight * 0.55, // Below "Get In Touch" text
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: screenWidth * 0.15,
                              height: screenWidth * 0.15,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.email,
                                  color: Colors.black,
                                  size: screenWidth * 0.08,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.15), // Responsive spacing
                            Container(
                              width: screenWidth * 0.15,
                              height: screenWidth * 0.15,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.phone,
                                  color: Colors.black,
                                  size: screenWidth * 0.08,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.15), // Responsive spacing
                            Container(
                              width: screenWidth * 0.15,
                              height: screenWidth * 0.15,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.forum,
                                  color: Colors.black,
                                  size: screenWidth * 0.08,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildGlassyRectangle(double screenWidth, double screenHeight, int index) {
    // Define different content for each rectangle
    final contents = [
      'Navigate MUBS with ease,\n your success is our guide.',
      'Explore new opportunities,\n grow with every step.',
      'Connect with peers,\n build your future today.',
      'Lead with confidence,\n inspire with action.',
    ];

    return Center(
      child: CustomPaint(
        painter: RipplePainter(_rippleAnimation.value),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: CustomPaint(
            painter: WaterWavePainter(_rippleAnimation.value),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: screenHeight * 0.25,
                width: screenWidth * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Quote symbol
                    Positioned(
                      top: 5,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          '"',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.2,
                            fontFamily: 'Epunda Slab',
                          ),
                        ),
                      ),
                    ),
                    // Quote text
                    Positioned(
                      top: screenHeight * 0.09,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          contents[index % contents.length], // Cycle through contents
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.042,
                            fontFamily: 'Urbanist',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Author name
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Ambasize Jackline',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.05,
                            fontFamily: 'Epunda Slab',
                          ),
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
    );
  }
}

// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final double animationValue;

  RipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4; // Maximum ripple radius
    final currentRadius = maxRadius * animationValue;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3 - (0.2 * animationValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for water wave effect inside the rectangle
class WaterWavePainter extends CustomPainter {
  final double animationValue;

  WaterWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.1;
    final waveCount = (size.width / (size.width * 0.2)).floor();
    final offset = animationValue * size.width * 0.5; // Move waves based on animation

    path.moveTo(0, size.height);
    for (int i = 0; i <= waveCount; i++) {
      final x = i * size.width * 0.2 - offset;
      path.quadraticBezierTo(
        x + size.width * 0.1,
        size.height - (i.isEven ? waveHeight : -waveHeight) * (1 - animationValue),
        x + size.width * 0.2,
        size.height,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter stays the same
class WaveCloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    final waveHeight = size.height * 0.1;
    final waveCount = (size.width / (size.width * 0.1)).floor();
    for (int i = 0; i <= waveCount; i++) {
      final x = i * size.width * 0.1;
      path.quadraticBezierTo(
        x + size.width * 0.05,
        i.isEven ? -waveHeight : waveHeight,
        x + size.width * 0.1,
        0,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}