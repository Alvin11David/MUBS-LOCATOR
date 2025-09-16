import 'package:flutter/material.dart';
import 'sign_in.dart';



class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Focus nodes for field navigation
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background
              Container(
                width: screenWidth,
                height: screenHeight,
                color: const Color(0xFF93C5FD),
              ),

              // Logo at center top
              Positioned(
                top: screenHeight * 0.05,
                left: screenWidth * 0.5 - (screenWidth * 0.2) / 2,
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: screenWidth * 0.2,
                  height: screenHeight * 0.1,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
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

              // "Let's get you signed up"
              Positioned(
                top: screenHeight * 0.17,
                left: screenWidth * 0.36 - (screenWidth * 0.3) / 2,
                child: Text(
                  "Let's get you\nsigned up!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),

              // White container with inputs (fixed height, scrollable content)
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Subtitle
                        SizedBox(
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
                        SizedBox(height: screenHeight * 0.03),

                        // Full Names Field
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: _ResponsiveTextField(
                            controller: _fullNameController,
                            label: 'Full Names',
                            hint: 'Enter Your Full Names',
                            icon: Icons.person,
                            focusNode: _fullNameFocus,
                            nextFocusNode: _emailFocus,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Email Field
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: _ResponsiveTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Enter Your Email',
                            icon: Icons.mail,
                            focusNode: _emailFocus,
                            nextFocusNode: _passwordFocus,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Password Field
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: _ResponsivePasswordField(
                            controller: _passwordController,
                            label: 'Password',
                            focusNode: _passwordFocus,
                            nextFocusNode: _confirmPasswordFocus,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Confirm Password Field
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: _ResponsivePasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            focusNode: _confirmPasswordFocus,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Sign Up button
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.06,
                            child: GestureDetector(
                              onTap: () {
                                // Add your sign up logic here
                              },
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
                                  "Sign Up",
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
                        SizedBox(height: screenHeight * 0.03),

                        // Or Divider
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                          ),
                          child: _OrDivider(fontSize: screenWidth * 0.04, horizontalPadding: screenWidth * 0.02),
                        ),
                        SizedBox(height: screenHeight * 0.03),

                        // Sign Up with Google button
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: screenHeight * 0.06,
                            child: GestureDetector(
                              onTap: () {
                                // Add Google sign up logic here
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFFD59A00),
                                    width: 1,
                                  ),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      spreadRadius: 1,
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/logo/googleicon.png',
                                      width: screenWidth * 0.08,
                                      height: screenHeight * 0.03,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                    ),
                                    SizedBox(width: screenWidth * 0.025),
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
                        SizedBox(height: screenHeight * 0.03),

                        // Already have account? Sign In
                        Center(
                          child: SizedBox(
                            width: screenWidth * 0.8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'Epunda Slab',
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SignInScreen()),
                                    );
                                  },
                                  child: Text(
                                    "Sign In",
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
                        ),
                      ],
                    ),
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

// Responsive Text Field with focus logic
class _ResponsiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;

  const _ResponsiveTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: screenWidth * 0.05,
        ),
        hintText: hint,
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
            icon,
            color: icon == Icons.person
                ? const Color.fromARGB(255, 69, 141, 224)
                : const Color.fromARGB(255, 69, 141, 224),
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
    );
  }
}

// Responsive Password Field with focus logic
class _ResponsivePasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;
  const _ResponsivePasswordField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
  });

  @override
  State<_ResponsivePasswordField> createState() => _ResponsivePasswordFieldState();
}

class _ResponsivePasswordFieldState extends State<_ResponsivePasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      obscureText: _isObscured,
      onFieldSubmitted: (_) {
        if (widget.nextFocusNode != null) {
          FocusScope.of(context).requestFocus(widget.nextFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: screenWidth * 0.05,
        ),
        hintText: 'Enter Your ${widget.label}',
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
          child: const Icon(
            Icons.lock,
            color: Color.fromARGB(255, 73, 122, 220),
          ),
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
          borderSide: const BorderSide(color: Color(0xFFD59A00), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 2),
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
  }
}

// Responsive OR Divider
class _OrDivider extends StatelessWidget {
  final double fontSize;
  final double horizontalPadding;
  const _OrDivider({required this.fontSize, required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth * 0.8,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.grey)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              'Or Sign Up With',
              style: TextStyle(
                color: const Color(0xFF6B7280),
                fontSize: fontSize,
                fontFamily: 'Epunda Slab',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: Colors.grey)),
        ],
      ),
    );
  }
}