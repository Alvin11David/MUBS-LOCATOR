import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
        _currentPage = (_currentPage + 1) % 4;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });

    // Ripple animation
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

  // Custom SnackBar method
  void _showCustomSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSuccess ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/logo/logo.png',
              width: screenWidth * 0.08,
              height: screenWidth * 0.08,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(width: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        top: 10,
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).size.height - 100,
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'leenine173@gmail.com',
    );

    if (kIsWeb) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showCustomSnackBar(context, 'Could not launch email app');
        }
      }
    }
  }

  Future<void> _launchPhoneDialer(String number) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: number,
    );

    if (kIsWeb) {
      if (mounted) {
        _showCustomSnackBar(context, 'Phone dialer not supported on web');
      }
    } else {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showCustomSnackBar(context, 'Could not launch phone dialer');
        }
      }
    }
  }

  void _showPhoneNumberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('0742195533'),
              onTap: () {
                Navigator.pop(context);
                _launchPhoneDialer('0742195533');
              },
            ),
            ListTile(
              title: const Text('0789908689'),
              onTap: () {
                Navigator.pop(context);
                _launchPhoneDialer('0789908689');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const String whatsappNumber = '0780439952';
    final String cleanNumber = '256${whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '')}';

    final Uri whatsappAppUri = Uri.parse("whatsapp://send?phone=$cleanNumber");
    final Uri whatsappWebUri = Uri.parse("https://wa.me/$cleanNumber");

    // Try app first
    if (!kIsWeb && await canLaunchUrl(whatsappAppUri)) {
      await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
    } 
    // Fallback to browser
    else if (await canLaunchUrl(whatsappWebUri)) {
      await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
    } 
    else {
      if (mounted) {
        _showCustomSnackBar(context, 'Could not launch WhatsApp. Make sure it is installed.');
      }
    }
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
              // Back button
              Positioned(
                top: screenHeight * 0.02,
                left: screenWidth * 0.04,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: ClipOval(
                    child: Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: screenWidth * 0.002),
                      ),
                      child: Center(
                        child: Icon(Icons.chevron_left, color: Colors.black, size: screenWidth * 0.08),
                      ),
                    ),
                  ),
                ),
              ),
              // Title
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
              // Image
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
              // Bottom Section
              Positioned(
                top: screenHeight * 0.10 + (screenWidth * 1.5 * (9 / 16)) * 0.6,
                left: 0,
                right: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: screenHeight * 0.6,
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
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 21.7, sigmaY: 21.7),
                        child: CustomPaint(
                          painter: WaveCloudPainter(),
                          child: Container(
                            height: screenHeight * 0.6,
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
                    // Name & Description
                    Positioned(
                      top: -(screenHeight * 0.186 - (screenWidth * 1.5 * (9 / 16)) * 0.4),
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
                    Positioned(
                      top: (screenHeight * 0.08888 - (screenWidth * 1.5 * (9 / 16)) * 0.35) + screenHeight * 0.08,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'I am a year 2 student\n pursuing a bachelor\'s degree\n in Leadership and\n Governance.',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w200,
                            fontSize: screenWidth * 0.04,
                            fontFamily: 'Urbanist',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Carousel
                    Positioned(
                      top: screenHeight * 0.11,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: screenHeight * 0.4,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return _buildGlassyRectangle(screenWidth, screenHeight, index);
                          },
                        ),
                      ),
                    ),
                    // Get In Touch
                    Positioned(
                      top: screenHeight * 0.46,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Get In Touch',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.05,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ),
                    ),
                    // Contact Buttons
                    Positioned(
                      top: screenHeight * 0.51,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildContactCircle(Icons.email, _launchEmail, screenWidth),
                            SizedBox(width: screenWidth * 0.15),
                            _buildContactCircle(Icons.phone, _showPhoneNumberDialog, screenWidth),
                            SizedBox(width: screenWidth * 0.15),
                            _buildContactCircle(Icons.forum, _launchWhatsApp, screenWidth),
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

  Widget _buildContactCircle(IconData icon, VoidCallback onTap, double screenWidth) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.15,
        height: screenWidth * 0.15,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(
          child: Icon(icon, color: Colors.black, size: screenWidth * 0.08),
        ),
      ),
    );
  }

  Widget _buildGlassyRectangle(double screenWidth, double screenHeight, int index) {
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
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Stack(
                  children: [
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
                    Positioned(
                      top: screenHeight * 0.09,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          contents[index % contents.length],
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.042,
                            fontFamily: 'Urbanist',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
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

class RipplePainter extends CustomPainter {
  final double animationValue;
  RipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.4;
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
    final offset = animationValue * size.width * 0.5;

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