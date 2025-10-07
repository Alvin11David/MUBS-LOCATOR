import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart'; // FIXED IMPORT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// ignore: camel_case_types
class OTP_Screen extends StatefulWidget {
  final String email;

  const OTP_Screen({super.key, required this.email});

  @override
  State<OTP_Screen> createState() => _OTP_ScreenState();
}

// ignore: camel_case_types
class _OTP_ScreenState extends State<OTP_Screen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  Timer? _timer;
  int _countdown = 0;
  bool _isButtonEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 10;
      _isButtonEnabled = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _isButtonEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  // Generate a new OTP
  String _generateOTP() {
    return (1000 + Random().nextInt(9000)).toString();
  }

  // Resend OTP
  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Generate a new 4-digit OTP
      final otp = _generateOTP();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: 10));

      // Save the new OTP to Firestore
      await FirebaseFirestore.instance
          .collection('password_reset_tokens')
          .doc(widget.email)
          .set({
            'email': widget.email,
            'otp': otp,
            'createdAt': now.millisecondsSinceEpoch,
            'expiresAt': expiresAt.millisecondsSinceEpoch,
          });
      // Print the active OTP code to the console
      print('ACTIVE OTP CODE SENT: $otp');

      // Call the Cloud Function to send the new OTP email
      await FirebaseFunctions.instance.httpsCallable('sendOTPEmail').call({
        'email': widget.email,
        'otp': otp,
      });

      // Optionally clear the input fields
      for (var controller in _controllers) {
        controller.clear();
      }

      // Restart the countdown
      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A new 4 digit code has been sent to ${widget.email}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error resending OTP: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verify OTP
  Future<void> _checkOTPAndNavigate() async {
    bool isComplete = _controllers.every(
      (controller) => controller.text.length == 1,
    );
    if (!isComplete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final enteredOTP = _controllers.map((c) => c.text).join();
      final doc = await FirebaseFirestore.instance
          .collection('password_reset_tokens')
          .doc(widget.email)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final storedOTP = data['otp'] as String?;
        final expiresAtMillis = data['expiresAt'] as int?;

        if (storedOTP == null || expiresAtMillis == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid OTP data')));
          return;
        }

        final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);

        if (DateTime.now().isBefore(expiresAt) && enteredOTP == storedOTP) {
          // OTP is valid, navigate to ResetPasswordScreen
          Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OTP_Screen(email: widget.email), // userEmail must not be empty!
  ),
);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Invalid or expired OTP')));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No OTP found for this email')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error verifying OTP: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Make box size responsive: slightly taller than wide
    final otpBoxWidth = screenWidth * 0.14;
    final otpBoxHeight = otpBoxWidth * 1.3;

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Logo
              Positioned(
                top: screenHeight * 0.05,
                left: screenWidth * 0.5 - (screenWidth * 0.2) / 2,
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: screenWidth * 0.2,
                  height: screenHeight * 0.1,
                  fit: BoxFit.contain,
                ),
              ),
              // Ambasize text
              Positioned(
                top: screenHeight * 0.04,
                left: screenWidth * 0.02,
                child: Text(
                  'Ambasize',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Abril Fatface',
                  ),
                ),
              ),
              // Jackline text
              Positioned(
                top: screenHeight * 0.09,
                right: screenWidth * 0.02,
                child: Text(
                  'Jackline',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Abril Fatface',
                  ),
                ),
              ),
              // "Let's get you sorted" text
              Positioned(
                top: screenHeight * 0.17,
                left: screenWidth * 0.5 - (screenWidth * 0.6) / 2,
                width: screenWidth * 0.6,
                child: Text(
                  "Let's get you\nsorted!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.31,
                left: screenWidth * 0.02,
                right: screenWidth * 0.02,
                child: Container(
                  height: screenHeight * 0.69,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      // Cone image at top right
                      Positioned(
                        top: 0,
                        right: -screenWidth * 0.1,
                        child: Image.asset(
                          'assets/vectors/circular.png',
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.error,
                            color: Colors.red,
                            size: screenWidth * 0.1,
                          ),
                        ),
                      ),
                      // Cone image at bottom left
                      Positioned(
                        bottom: 0,
                        left: -screenWidth * 0.15,
                        child: Image.asset(
                          'assets/vectors/circular.png',
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.error,
                            color: Colors.red,
                            size: screenWidth * 0.1,
                          ),
                        ),
                      ),
                      // Scrollable content
                      SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.01,
                          horizontal: screenWidth * 0.05,
                        ),
                        child: Column(
                          children: [
                            // Mailbox icon in a circle
                            Container(
                              margin: EdgeInsets.only(top: screenHeight * 0.01),
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B578F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mail,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                            // "Verify Your Email"
                            SizedBox(height: screenHeight * 0.02),
                            SizedBox(
                              width: screenWidth * 0.8,
                              child: Text(
                                'Verify Your Email',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  fontFamily: 'Epunda Slab',
                                ),
                              ),
                            ),
                            // "Please enter the code"
                            SizedBox(height: screenHeight * 0.02),
                            SizedBox(
                              width: screenWidth * 0.8,
                              child: RichText(
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          'Please enter the 4 digit code we sent to\n',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    TextSpan(
                                      text: widget.email,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF3B82F6),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // OTP input boxes
                            SizedBox(height: screenHeight * 0.03),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                return Container(
                                  width: otpBoxWidth,
                                  height: otpBoxHeight,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.02,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFD59A00),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      // Custom underline inside box
                                      Positioned(
                                        bottom: otpBoxHeight * 0.15,
                                        child: Container(
                                          width: otpBoxWidth * 0.5,
                                          height: 2,
                                          color: const Color(0xFFD59A00),
                                        ),
                                      ),
                                      // Text field
                                      Center(
                                        child: TextFormField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          maxLength: 1,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            counterText: '',
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.06,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontFamily: 'Poppins',
                                            height: 1.0,
                                          ),
                                          cursorColor: const Color(0xFF3B82F6),
                                          onChanged: (value) {
                                            if (value.isNotEmpty && index < 3) {
                                              _focusNodes[index].unfocus();
                                              _focusNodes[index + 1]
                                                  .requestFocus();
                                            } else if (value.isEmpty &&
                                                index > 0) {
                                              _focusNodes[index].unfocus();
                                              _focusNodes[index - 1]
                                                  .requestFocus();
                                            }
                                            _checkOTPAndNavigate();
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            // Resend button with countdown
                            SizedBox(height: screenHeight * 0.05),
                            GestureDetector(
                              onTap: (_isButtonEnabled && !_isLoading)
                                  ? _resendOTP
                                  : null,
                              child: Container(
                                width: screenWidth * 0.5,
                                height: screenHeight * 0.06,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isButtonEnabled && !_isLoading
                                        ? [
                                            const Color(0xFFE0E7FF),
                                            const Color(0xFF93C5FD),
                                          ]
                                        : [
                                            Colors.grey[300]!,
                                            Colors.grey[500]!,
                                          ],
                                    stops: [0.0, 0.47],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Color(0xFF235DE5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      color: Colors.white,
                                      size: screenWidth * 0.06,
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Text(
                                      _countdown > 0 ? '$_countdown' : 'Resend',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.1),
                            Container(
                              width: screenWidth * 0.9,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.08,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: screenWidth * 0.8,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Already have an account, ',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            fontFamily: 'Epunda Slab',
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/SignInScreen',
                                            );
                                          },
                                          child: Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF93C5FD),
                                              fontFamily: 'Epunda Slab',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
