import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          return Stack(
            children: [
              // Background
              Container(
                  width: screenWidth,
                  height: screenHeight,
                  color: const Color(0xFF93C5FD),
                  child: const SizedBox()),

              // Logo at center top
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

              // Ambasize top left
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

              // Jackline top right
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

              // "Let's get you signed in"
              Positioned(
                top: screenHeight * 0.17,
                left: screenWidth * 0.4 - (screenWidth * 0.3) / 2,
                child: Text(
                  "Let's get you\nsigned in",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),

              // White container with inputs
              Positioned(
                top: screenHeight * 0.29,
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
                      // Sign In title
                      Positioned(
                        top: screenHeight * 0.01,
                        left: screenWidth * 0.5 - (screenWidth * 0.5) / 2,
                        child: SizedBox(
                          width: screenWidth * 0.5,
                          child: Text(
                            'Sign In',
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: 'Epunda Slab',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      // Subtitle
                      Positioned(
                        top: screenHeight * 0.07,
                        left: screenWidth * 0.5 - (screenWidth * 0.8) / 2,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: Text(
                            'Please enter the details to\ncontinue.',
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w300,
                              color: Colors.black,
                              fontFamily: 'Epunda Slab',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      // Email Field
                      Positioned(
                        top: screenHeight * 0.16,
                        left: screenWidth * 0.1,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: EmailField(controller: _emailController),
                        ),
                      ),

                      // Password Field
                      Positioned(
                        top: screenHeight * 0.26,
                        left: screenWidth * 0.1,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: PasswordField(controller: _passwordController),
                        ),
                      ),

                      // Forgot Password text
                      Positioned(
                        top: screenHeight * 0.35,
                        right: screenWidth * 0.1,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/');
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),

                      // Sign In button
                      Positioned(
                        top: screenHeight * 0.42,
                        left: screenWidth * 0.1,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.06,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/HomeScreen');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6), // Blue border
                                  width: 1,
                                ),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE0E7FF), // Light shade at 0%
                                    Color(0xFF93C5FD), // Blue shade at 47%
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Sign In",
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
                      ),

                      // Or Divider
                      Positioned(
                        top: screenHeight * 0.50,
                        left: screenWidth * 0.1,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: OrDivider(),
                        ),
                      ),

                      // Sign In with Google button
                      Positioned(
                        top: screenHeight * 0.56,
                        left: screenWidth * 0.1,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.06,
                          child: GestureDetector(
                            onTap: () {
                              // Add navigation or action here
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFFD59A00), // Gold border
                                  width: 1,
                                ),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 255, 255, 255), // Light shade at 0%
                                    Color.fromARGB(255, 255, 255, 255), // White shade
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2), // Shadow color
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3), // Shadow offset (x, y)
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/logo/googleicon.png',
                                    width: screenWidth * 0.08,
                                    height: screenHeight * 0.03,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 5), // Spacing between icon and text
                                  Text(
                                    "Google",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontFamily: 'Epunda Slab',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// EMAIL FIELD
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  const EmailField({super.key, required this.controller});

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05,
            ),
            hintText: 'Enter Your Email',
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
              child: Icon(Icons.mail, color: const Color.fromARGB(255, 69, 141, 224)),
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
              vertical: screenWidth * 0.04,
              horizontal: screenWidth * 0.04,
            ),
          ),
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: screenWidth * 0.045,
          ),
          cursorColor: const Color(0xFF3B82F6),
        );
      },
    );
  }
}

// PASSWORD FIELD
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  const PasswordField({super.key, required this.controller});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        return TextFormField(
          controller: widget.controller,
          obscureText: _isObscured,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter your password';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(
              color: Colors.black,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05,
            ),
            hintText: 'Enter Your Password',
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
              child: Icon(Icons.lock, color: const Color.fromARGB(255, 73, 122, 220)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isObscured ? Icons.visibility_off : Icons.visibility,
                color: const Color.fromARGB(255, 86, 156, 235),
              ),
              onPressed: () {
                setState(() {
                  _isObscured = !_isObscured;
                });
              },
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
              horizontal: screenWidth * 0.06,
            ),
          ),
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: screenWidth * 0.045,
          ),
          cursorColor: const Color(0xFFD59A00),
        );
      },
    );
  }
}

// OR DIVIDER
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        return SizedBox(
          width: screenWidth * 0.8, // Responsive width (80% of container width)
          child: Row(
            children: [
              Expanded(child: Container(height: 1, color: Colors.grey)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                child: Text(
                  'Or Sign In With',
                  style: TextStyle(
                    color: const Color(0xFF6B7280), // Gray
                    fontSize: screenWidth * 0.04, // Responsive font size
                    fontFamily: 'Epunda Slab',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}