import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool isButtonEnabled = false;
  bool isLoading = false; // NEW: Track loading state

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

  Future<void> _handleSubmit() async {
    setState(() {
      isLoading = true;
    });

    // Simulate a network call (you can replace this with Firebase OTP logic)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
    });

    // Navigate to OTP verification screen after loading
    Navigator.pushNamed(context, '/OTPScreen');
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
                child: Stack(
                  children: [
                    // Cone image top right
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
                    // Cone image bottom left
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
                        vertical: screenHeight * 0.04,
                        horizontal: screenWidth * 0.05,
                      ),
                      child: Column(
                        children: [
                          // Mailbox icon in a circle
                          Container(
                            margin: EdgeInsets.only(top: screenHeight * 0.02),
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
                          SizedBox(height: screenHeight * 0.04),
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
                              'Please enter your email address below to receive an OTP code.',
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
                          SizedBox(height: screenHeight * 0.06),
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
                                    final emailRegex = RegExp(
                                      r'^[\w\.-]+@gmail\.com$',
                                    );
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
                                      fontSize: screenWidth * 0.045, // Reduced from 0.05
                                    ),
                                    hintText: 'Enter Your Gmail',
                                    hintStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: screenWidth * 0.04, // Reduced from 0.045
                                    ),
                                    fillColor: const Color.fromARGB(
                                      255,
                                      237,
                                      236,
                                      236,
                                    ),
                                    filled: true,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(
                                        left: screenWidth * 0.02,
                                      ),
                                      child: Icon(
                                        Icons.mail,
                                        color: const Color.fromARGB(
                                          255,
                                          69,
                                          141,
                                          224,
                                        ),
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
                                    fontSize: screenWidth * 0.04, // Reduced from 0.045
                                  ),
                                  cursorColor: const Color(0xFF3B82F6),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.06,
                                  child: GestureDetector(
                                    onTap: (isButtonEnabled && !isLoading)
                                        ? _handleSubmit
                                        : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: const Color(0xFF3B82F6),
                                          width: 1,
                                        ),
                                        gradient: LinearGradient(
                                          colors: isButtonEnabled
                                              ? [
                                                  const Color(0xFFE0E7FF),
                                                  const Color(0xFF93C5FD),
                                                ]
                                              : [
                                                  Colors.grey[300]!,
                                                  Colors.grey[500]!,
                                                ],
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
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.black),
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
    );
  }
}