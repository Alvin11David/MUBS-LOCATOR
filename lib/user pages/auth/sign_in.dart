import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for storing login state

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isButtonEnabled = false;
  bool _isLoading = false;
  bool _isForgotPasswordTapped = false; // State for tap feedback

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _checkLoginState(); // Check if user is already logged in
  }

  void _updateButtonState() {
    setState(() {
      isButtonEnabled =
          _emailController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
    });
  }

  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (loggedIn && mounted) {
      // Check if the current user is admin
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.email?.toLowerCase() == 'adminuser@gmail.com') {
          print('Admin user detected, navigating to AdminDashboardScreen');
          Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
        } else {
          print('Regular user, navigating to HomeScreen');
          Navigator.pushReplacementNamed(context, '/HomeScreen');
        }
      }
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      // If sign-in succeeds, store login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        // Check if the email is adminuser@gmail.com
        if (_emailController.text.trim().toLowerCase() == 'adminuser@gmail.com') {
          print('Admin email detected, navigating to AdminDashboardScreen');
          Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
        } else {
          print('Regular user, navigating to HomeScreen');
          Navigator.pushReplacementNamed(context, '/HomeScreen');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign in failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard appears
      body: SafeArea(
        child: LayoutBuilder(
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
                // "Let's get you signed in"
                Positioned(
                  top: screenHeight * 0.17,
                  left: screenWidth * 0.36 - (screenWidth * 0.3) / 2,
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
                  top: screenHeight * 0.31,
                  left: screenWidth * 0.02,
                  right: screenWidth * 0.02,
                  bottom: 0, // Fixed to bottom of screen
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: screenHeight * 0.69, // Ensure minimum height
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.04,
                            horizontal: screenWidth * 0.02,
                          ),
                          child: Column(
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
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                                child: EmailField(controller: _emailController),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                                child: PasswordField(controller: _passwordController),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Padding(
                                padding: EdgeInsets.only(right: screenWidth * 0.06),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTapDown: (_) {
                                      setState(() {
                                        _isForgotPasswordTapped = true;
                                      });
                                    },
                                    onTapUp: (_) {
                                      setState(() {
                                        _isForgotPasswordTapped = false;
                                      });
                                      Navigator.pushNamed(context, '/ForgotPasswordScreen');
                                    },
                                    onTapCancel: () {
                                      setState(() {
                                        _isForgotPasswordTapped = false;
                                      });
                                    },
                                    onTap: () {},
                                    child: Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'Poppins',
                                        decoration: _isForgotPasswordTapped
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                        decorationColor: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.06,
                                  child: GestureDetector(
                                    onTap: isButtonEnabled && !_isLoading ? _signIn : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: isButtonEnabled ? const Color(0xFF3B82F6) : Colors.grey,
                                          width: 1,
                                        ),
                                        gradient: isButtonEnabled
                                            ? const LinearGradient(
                                                colors: [Color(0xFFE0E7FF), Color(0xFF93C5FD)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                            )
                                          : Text(
                                              "Sign In",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.05,
                                                fontWeight: FontWeight.bold,
                                                color: isButtonEnabled ? Colors.black : Colors.grey,
                                                fontFamily: 'Epunda Slab',
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                                child: const OrDivider(),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.06,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Add Google sign-in logic here
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: const Color(0xFFD59A00), width: 1),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color.fromARGB(255, 255, 255, 255),
                                            Color.fromARGB(255, 255, 255, 255),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
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
                                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                          ),
                                          const SizedBox(width: 5),
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
                              Center(
                                child: SizedBox(
                                  width: screenWidth * 0.8,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account, ",
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontFamily: 'Epunda Slab',
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(context, '/SignUpScreen');
                                        },
                                        child: Text(
                                          "Sign Up",
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
                              SizedBox(height: screenHeight * 0.05), // Fixed padding
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// EMAIL FIELD
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  const EmailField({super.key, required this.controller});

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email address';
    final emailRegex = RegExp(r'^[\w\.-]+@gmail\.com$');
    if (!emailRegex.hasMatch(value.trim())) return 'Please enter a Gmail address (e.g., username@gmail.com)';
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
              child: const Icon(Icons.mail, color: Color.fromARGB(255, 69, 141, 224)),
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
          validator: (value) => value == null || value.isEmpty ? 'Enter your password' : null,
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
              child: const Icon(Icons.lock, color: Color.fromARGB(255, 73, 122, 220)),
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
          width: screenWidth * 0.8,
          child: Row(
            children: [
              Expanded(child: Container(height: 1, color: Colors.grey)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                child: Text(
                  'Or Sign In With',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: screenWidth * 0.04,
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