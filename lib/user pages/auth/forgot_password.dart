import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_functions/cloud_functions.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool isButtonEnabled = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w\.-]+@gmail\.com$');
    setState(() {
      isButtonEnabled = emailRegex.hasMatch(email);
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

  Future<void> _handleSubmit() async {
    setState(() {
      isLoading = true;
    });
    try {
      final email = _emailController.text.trim();
      final otp = (1000 + Random().nextInt(9000)).toString();

      // Call your deployed Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable('sendOTPEmail');
      await callable.call({'email': email, 'otp': otp});

      if (mounted) {
        _showCustomSnackBar(context, 'A 4 digit code has been sent to $email', isSuccess: true);
        Navigator.pushNamed(context, '/OTPScreen', arguments: email);
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
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
                        vertical: screenHeight * 0.00,
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
                              'Forgot Your Password?',
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
                            child: Text(
                              'Please enter your email address below to receive a 4 digit code.',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Container(
                            width: screenWidth * 0.9,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter your email address';
                                    }
                                    final emailRegex = RegExp(r'^[\w\.-]+@gmail\.com$');
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return 'Please enter a Gmail address (e.g., username@gmail.com)';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                    hintText: 'Enter Your Gmail',
                                    hintStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    fillColor: const Color.fromARGB(255, 237, 236, 236),
                                    filled: true,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(left: screenWidth * 0.02),
                                      child: Icon(
                                        Icons.mail,
                                        color: const Color.fromARGB(255, 69, 141, 224),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFD59A00),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF93C5FD),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: screenWidth * 0.05,
                                      horizontal: screenWidth * 0.05,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                  cursorColor: const Color(0xFF3B82F6),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.06,
                                  child: GestureDetector(
                                    onTap: (isButtonEnabled && !isLoading) ? _handleSubmit : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: const Color(0xFF3B82F6),
                                          width: 1,
                                        ),
                                        gradient: LinearGradient(
                                          colors: isButtonEnabled && !isLoading
                                              ? [const Color(0xFFE0E7FF), const Color(0xFF93C5FD)]
                                              : [Colors.grey[300]!, Colors.grey[500]!],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                strokeWidth: 3,
                                              ),
                                            )
                                          : Text(
                                              'Submit',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.05,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontFamily: 'Epunda Slab',
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),
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
    );
  }
}