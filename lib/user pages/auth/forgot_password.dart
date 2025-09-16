import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      isButtonEnabled = _emailController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
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
            // Bottom container
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
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.04,
                    horizontal: screenWidth * 0.05,
                  ),
                  child: Column(
                    children: [
                      // Mailbox icon in a circle
                      Container(
                        margin: EdgeInsets.only(top: screenHeight * 0.02),
                        width: 100,
                        height: 100,
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
                      // "Forgot Your Password?" text
                      SizedBox(height: screenHeight * 0.04),
                      SizedBox(
                        width: screenWidth * 0.8,
                        child: Text(
                          'Forgot Your Password?',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            fontFamily: 'Epunda Slab',
                          ),
                        ),
                      ),
                      // "Please enter your email address below to receive an OTP code." text
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        width: screenWidth * 0.8,
                        child: Text(
                          'Please enter your email address below to receive an OTP code.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      // Email input, submit button, and sign-in text
                      SizedBox(height: screenHeight * 0.06), // Approximate top: 0.28
                      Container(
                        width: screenWidth * 0.9,
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
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
                                  fontSize: screenWidth * 0.05,
                                ),
                                hintText: 'Enter Your Gmail',
                                hintStyle: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  fontSize: screenWidth * 0.045,
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
                                  borderSide: const BorderSide(color: Color(0xFFD59A00), width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 2),
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
                                fontSize: screenWidth * 0.045,
                              ),
                              cursorColor: const Color(0xFF3B82F6),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            SizedBox(
                              width: double.infinity,
                              height: screenHeight * 0.06,
                              child: GestureDetector(
                                onTap: isButtonEnabled
                                    ? () {
                                        // Navigate to OTP verification screen
                                        print('Email submitted: ${_emailController.text}');
                                      }
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFF3B82F6),
                                      width: 1,
                                    ),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFE0E7FF),
                                        Color(0xFF93C5FD),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
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
                      SizedBox(height: screenHeight * 0.1), // Spacer for bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}