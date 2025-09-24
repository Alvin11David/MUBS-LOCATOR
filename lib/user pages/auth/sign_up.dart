import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes for field navigation
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Password strength state
  double _passwordStrengthProgress = 0.0; // Progress from 0.0 to 1.0
  Color _strengthColor = Colors.white; // Color based on strength

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

  // Password strength calculation
  void _checkPasswordStrength(String password) {
    int strengthScore = 0;
    if (password.isNotEmpty) strengthScore++; // Any input
    if (password.length >= 6) strengthScore++; // Length ≥ 6
    if (password.contains(RegExp(r'[a-z]'))) strengthScore++; // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) strengthScore++; // Numbers

    print('Password: "$password"');
    print(
      'Strength Score: $strengthScore (NotEmpty: ${password.isNotEmpty}, Length>=6: ${password.length >= 6}, Lowercase: ${password.contains(RegExp(r'[a-z]'))}, Numbers: ${password.contains(RegExp(r'[0-9]'))})',
    );
    print('Progress: ${_passwordStrengthProgress}, Color: ${_strengthColor}');

    setState(() {
      // Map strength score to progress (0.0 to 1.0)
      _passwordStrengthProgress = strengthScore / 4.0;
      // Set color based on strength
      if (strengthScore <= 1) {
        _strengthColor = Colors.red; // Weak
      } else if (strengthScore <= 3) {
        _strengthColor = Colors.orange; // Medium
      } else if (strengthScore == 4) {
        _strengthColor = Colors.green; // Strong
      }
    });
  }

  // Validation function
  String? _validateForm() {
    print('Validating form...');
    if (_fullNameController.text.trim().isEmpty) {
      print('Validation failed: Full name empty');
      return 'Please enter your full name';
    }
    if (_emailController.text.trim().isEmpty) {
      print('Validation failed: Email empty');
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      print('Validation failed: Invalid email');
      return 'Please enter a valid email';
    }
    if (_passwordController.text.trim().isEmpty) {
      print('Validation failed: Password empty');
      return 'Please enter a password';
    }
    if (_passwordController.text.trim().length < 6) {
      print('Validation failed: Password too short');
      return 'Password must be at least 6 characters';
    }
    if (_confirmPasswordController.text.trim() !=
        _passwordController.text.trim()) {
      print('Validation failed: Passwords do not match');
      return 'Passwords do not match';
    }
    print('Validation passed');
    return null;
  }

  // Firebase signup function
  Future<void> _signUp() async {
    print('Sign up button pressed');
    final error = _validateForm();
    if (error != null) {
      print('Form error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    print(
      'Attempting Firebase sign up for email: ${_emailController.text.trim()}',
    );

    try {
      // Create user with email/password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      print('Firebase sign up successful: ${userCredential.user?.uid}');

      // Update display name (optional)
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(
          _fullNameController.text.trim(),
        );
        print('Display name updated to: ${_fullNameController.text.trim()}');
      }

      if (mounted) {
        print('Navigating based on email');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Check if the email is adminuser@gmail.com
        if (_emailController.text.trim().toLowerCase() ==
            'adminuser@gmail.com') {
          print('Admin email detected, navigating to AdminDashboardScreen');
          Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
        } else {
          print('Regular user, navigating to SignInScreen');
          Navigator.pushReplacementNamed(context, '/SignInScreen');
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message =
              'Firebase error: ${e.code} - ${e.message ?? "Unknown error"}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e, stackTrace) {
      print('Signup error: $e\nStack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print('Sign up process finished');
    }
  }

  // Check if passwords match for enabling Sign Up button
  bool _isSignUpEnabled() {
    return _passwordController.text.trim() ==
            _confirmPasswordController.text.trim() &&
        _passwordController.text.trim().isNotEmpty &&
        _passwordStrengthProgress == 1.0;
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
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
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
                            onChanged: _checkPasswordStrength,
                          ),
                        ),

                        // Password Strength Indicator
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                            vertical: screenHeight * 0.01,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Stack(
                              children: [
                                // Background of the strength indicator
                                Container(
                                  width: double.infinity,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        253,
                                        253,
                                      )!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                // Progress bar with strength color
                                FractionallySizedBox(
                                  widthFactor: _passwordStrengthProgress,
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _strengthColor,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                              onTap: _isLoading || !_isSignUpEnabled()
                                  ? null
                                  : _signUp,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: _isLoading || !_isSignUpEnabled()
                                        ? Colors.grey
                                        : const Color(0xFF3B82F6),
                                    width: 1,
                                  ),
                                  gradient: _isLoading || !_isSignUpEnabled()
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFFE0E7FF),
                                            Color(0xFF93C5FD),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                ),
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                          color: _isSignUpEnabled()
                                              ? Colors.black
                                              : Colors.grey,
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
                          child: _OrDivider(
                            fontSize: screenWidth * 0.04,
                            horizontalPadding: screenWidth * 0.02,
                          ),
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const SizedBox(),
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
                                    Navigator.pushNamed(
                                      context,
                                      '/SignInScreen',
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
          fontSize: screenWidth * 0.045, // Reduced from 0.05
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: screenWidth * 0.045, // Reduced from 0.045
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
        fontSize: screenWidth * 0.04, // Reduced from 0.045
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
  final Function(String)? onChanged;

  const _ResponsivePasswordField({
    required this.controller,
    required this.label,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
    this.onChanged,
  });

  @override
  State<_ResponsivePasswordField> createState() =>
      _ResponsivePasswordFieldState();
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
      onChanged: widget.onChanged,
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
          fontSize: screenWidth * 0.045, // Reduced from 0.05
        ),
        hintText: 'Enter Your ${widget.label}',
        hintStyle: TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: screenWidth * 0.045, // Reduced from 0.045
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
        fontSize: screenWidth * 0.04, // Reduced from 0.045
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