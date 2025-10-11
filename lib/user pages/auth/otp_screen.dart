import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class OTP_Screen extends StatefulWidget {
  final String email;

  const OTP_Screen({super.key, required this.email});

  @override
  State<OTP_Screen> createState() => _OTP_ScreenState();
}

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
    print('Received email: "${widget.email}"');
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
      _countdown = 30;
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
      final email = widget.email.trim().toLowerCase();
      print('Resending OTP for email: "$email"');
      final otp = _generateOTP();
      print('Generated OTP: $otp');

      // Call Firebase Function to send OTP email and update Firestore
      try {
        final result = await FirebaseFunctions.instance
            .httpsCallable('sendOTPEmail')
            .call({
          'email': email,
          'otp': otp,
        });
        print('Firebase Function response: ${result.data}');

        // Check if the response indicates success
        if (result.data['success'] != true) {
          print('Firebase Function failed: ${result.data}');
          if (mounted) {
            _showCustomSnackBar(context, 'Error sending OTP: ${result.data['message']}');
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Firebase Function error: $e');
        if (mounted) {
          _showCustomSnackBar(context, 'Error sending OTP email: $e');
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Clear OTP input fields
      for (var controller in _controllers) {
        controller.clear();
      }

      // Start countdown for resend button
      _startCountdown();

      if (mounted) {
        print('ACTIVE OTP CODE SENT: $otp');
        _showCustomSnackBar(context, 'A new 4 digit code has been sent to $email', isSuccess: true);
      }
    } catch (e, stackTrace) {
      print('Error resending OTP: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showCustomSnackBar(context, 'Error resending OTP: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Verify OTP
  Future<void> _checkOTPAndNavigate() async {
    bool isComplete = _controllers.every(
      (controller) => controller.text.trim().length == 1,
    );
    if (!isComplete) {
      print('OTP incomplete: Not all fields filled');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final enteredOTP = _controllers.map((c) => c.text.trim()).join();
      print('Raw controller values: ${_controllers.map((c) => '"${c.text}"').toList()}');
      print('Entered OTP: "$enteredOTP"');
      final email = widget.email.trim().toLowerCase();
      print('Checking OTP for email: "$email"');

      final doc = await FirebaseFirestore.instance
          .collection('password_reset_otp')
          .doc(email)
          .get();

      print('Firestore document exists: ${doc.exists}');
      if (!doc.exists) {
        if (mounted) {
          _showCustomSnackBar(context, 'No OTP found for this email');
        }
        return;
      }

      final data = doc.data()!;
      final storedOTP = data['otp'] as String?;
      final expiresAtMillis = data['expiresAt'] as int?;
      print('Stored OTP: "$storedOTP"');
      print('Expires At (ms): $expiresAtMillis');
      print('Current Time (ms): ${DateTime.now().millisecondsSinceEpoch}');

      if (storedOTP == null || expiresAtMillis == null) {
        print('Invalid OTP data: storedOTP=$storedOTP, expiresAtMillis=$expiresAtMillis');
        if (mounted) {
          _showCustomSnackBar(context, 'Invalid OTP data');
        }
        return;
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);
      print('Expires At (formatted): ${expiresAt.toIso8601String()}');
      print('Current Time (formatted): ${DateTime.now().toIso8601String()}');
      print('Is OTP valid (before expiration and matching)? ${DateTime.now().isBefore(expiresAt) && enteredOTP == storedOTP}');

      if (enteredOTP == storedOTP && DateTime.now().isBefore(expiresAt)) {
        print('OTP verification successful');
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/ResetPasswordScreen',
            arguments: email,
          );
        }
      } else {
        print('OTP verification failed:');
        print('  - OTP Mismatch: ${enteredOTP != storedOTP}');
        print('  - Expired: ${!DateTime.now().isBefore(expiresAt)}');
        if (mounted) {
          _showCustomSnackBar(context, 'Invalid or expired OTP');
        }
      }
    } catch (e, stackTrace) {
      print('Error verifying OTP: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        _showCustomSnackBar(context, 'Error verifying OTP: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final otpBoxWidth = screenWidth * 0.14;
    final otpBoxHeight = otpBoxWidth * 1.3;

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
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
                      SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.01,
                          horizontal: screenWidth * 0.05,
                        ),
                        child: Column(
                          children: [
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
                                      text: 'Please enter the 4 digit code we sent to\n',
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
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF3B578F),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                                      Positioned(
                                        bottom: otpBoxHeight * 0.15,
                                        child: Container(
                                          width: otpBoxWidth * 0.5,
                                          height: 2,
                                          color: const Color(0xFFD59A00),
                                        ),
                                      ),
                                      Center(
                                        child: TextFormField(
                                          controller: _controllers[index],
                                          focusNode: _focusNodes[index],
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          maxLength: 1,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(1),
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
                                            final trimmedValue = value.trim();
                                            if (trimmedValue.isNotEmpty && index < 3) {
                                              _controllers[index].text = trimmedValue;
                                              _focusNodes[index].unfocus();
                                              _focusNodes[index + 1].requestFocus();
                                            } else if (trimmedValue.isEmpty && index > 0) {
                                              _focusNodes[index].unfocus();
                                              _focusNodes[index - 1].requestFocus();
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
                            SizedBox(height: screenHeight * 0.05),
                            GestureDetector(
                              onTap: (_isButtonEnabled && !_isLoading) ? _resendOTP : null,
                              child: Container(
                                width: screenWidth * 0.5,
                                height: screenHeight * 0.06,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isButtonEnabled && !_isLoading
                                        ? [const Color(0xFFE0E7FF), const Color(0xFF93C5FD)]
                                        : [Colors.grey[300]!, Colors.grey[500]!],
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
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                                            Navigator.pushNamed(context, '/SignInScreen');
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