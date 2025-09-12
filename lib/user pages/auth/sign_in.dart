import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
              Container(
                width: screenWidth,
                height: screenHeight,
                color: const Color(0xFF93C5FD), // Background color #93C5FD
                child: const Center(
                  child: Placeholder(),
                ),
              ),
              Positioned(
                top: screenHeight * 0.05, // 5% from the top for padding
                left: screenWidth * 0.5 - (screenWidth * 0.2) / 2, // Center horizontally for logo
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: screenWidth * 0.2, // 20% of screen width for responsiveness
                  height: screenHeight * 0.1, // 10% of screen height for responsiveness
                  fit: BoxFit.contain, // Ensures the image scales without distortion
                ),
              ),
              // "Ambasize" at top left
              Positioned(
                top: screenHeight * 0.02, // 2% from the top for padding
                left: screenWidth * 0.02, // 2% from the left for padding
                child: Text(
                  'Ambasize',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05, // 5% of screen width for responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Abril Fatface', // Ensure this font is defined in pubspec.yaml
                  ),
                ),
              ),
              // "Jackline" at top right
              Positioned(
                top: screenHeight * 0.09, // 9% from the top for padding
                right: screenWidth * 0.02, // 2% from the right for padding
                child: Text(
                  'Jackline',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05, // 5% of screen width for responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Abril Fatface', // Ensure this font is defined in pubspec.yaml
                  ),
                ),
              ),
              // "Let's get you\nsigned in" below the logo
              Positioned(
                top: screenHeight * 0.05 + screenHeight * 0.1 + screenHeight * 0.02, // Below logo (5% top + 10% logo height + 2% padding)
                left: screenWidth * 0.5 - (screenWidth * 0.3) / 2, // Center horizontally
                child: Text(
                  'Let\'s get you\nsigned in',
                  textAlign: TextAlign.center, // Center the text
                  style: TextStyle(
                    fontSize: screenWidth * 0.06, // 6% of screen width for responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Montserrat', // Assuming "Monstreal" was a typo for Montserrat
                  ),
                ),
              ),
              // White rectangle with 30 border radius below the text
              Positioned(
                top: screenHeight * 0.1 + screenHeight * 0.1 + screenHeight * 0.02 + screenHeight * 0.08, // Below text
                left: screenWidth * 0.02, // 2% left padding
                right: screenWidth * 0.02, // 2% right padding
                child: Container(
                  height: screenHeight * 0.69, // 69% of screen height for responsiveness
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30), // 30 border radius
                  ),
                  child: Stack(
                    children: [
                      // "Sign In" at top center of the rectangle
                      Positioned(
                        top: screenHeight * 0.01, // 1% padding from the top of the rectangle
                        left: screenWidth * 0.5 - (screenWidth * 0.3) / 2, // Center horizontally
                        child: Text(
                          'Sign In',
                          textAlign: TextAlign.center, // Center the text
                          style: TextStyle(
                            fontSize: screenWidth * 0.06, // 6% of screen width for responsive font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Epunda Slab', // Ensure this font is defined in pubspec.yaml
                          ),
                        ),
                      ),
                      // "Please enter the details to continue" below "Sign In"
                      Positioned(
                        top: screenHeight * 0.01 + screenHeight * 0.06, // Below "Sign In"
                        left: screenWidth * 0.35 - (screenWidth * 0.4) / 2, // Center horizontally
                        child: Text(
                          'Please enter the details to continue.',
                          textAlign: TextAlign.center, // Center the text
                          style: TextStyle(
                            fontSize: screenWidth * 0.04, // 4% of screen width for responsive font size
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                            fontFamily: 'Poppins', // Ensure this font is defined in pubspec.yaml
                          ),
                        ),
                      ),
                      // EmailField below the "Please enter the details to continue" text
                      Positioned(
                        top: screenHeight * 0.01 + screenHeight * 0.06 + screenHeight * 0.06, // Below "Please enter the details"
                        left: screenWidth * 0.5 - (screenWidth * 0.8) / 2, // Center horizontally (80% width)
                        child: SizedBox(
                          width: screenWidth * 0.8, // 80% of screen width for responsiveness
                          child: EmailField(controller: _emailController),
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
              color: const Color.fromARGB(255, 0, 0, 0), // Dark Gray
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: screenWidth * 0.05, // Responsive font size
            ),
            hintText: 'Enter Your Email',
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF), // Light Gray (hint)
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: screenWidth * 0.045, // Responsive font size
            ),
            fillColor: const Color(0xFFE5E7EB), // Light Gray background
            filled: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.02),
              child: Icon(Icons.mail, color: const Color(0xFF6B7280)), // Gray icon
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFFD59A00),
                width: 1,
              ), // Blue
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: Color(0xFF1E3A8A),
                width: 2,
              ), // Navy Blue
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.05,
              horizontal: screenWidth * 0.06,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
          style: TextStyle(
            color: const Color(0xFF374151), // Dark Gray
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: screenWidth * 0.045, // Responsive font size
          ),
          cursorColor: const Color(0xFF3B82F6), // Blue
        );
      },
    );
  }
}