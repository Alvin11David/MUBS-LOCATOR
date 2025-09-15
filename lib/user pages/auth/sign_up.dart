import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF93C5FD),
          ),

          // Logo at center top (comment out if asset missing)
          Positioned(
            top: 40,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: Image.asset(
              'assets/logo/logo.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),

          // Ambasize top left
          const Positioned(
            top: 30,
            left: 16,
            child: Text(
              'Ambasize',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Abril Fatface',
              ),
            ),
          ),

          // Jackline top right
          const Positioned(
            top: 70,
            right: 16,
            child: Text(
              'Jackline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Abril Fatface',
              ),
            ),
          ),

          // "Let's get you signed up"
          const Positioned(
            top: 120,
            left: 40,
            child: SizedBox(
              width: 300,
              child: Text(
                "Let's get you\nsigned up!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),

          // White container with inputs
          Positioned(
            top: 210,
            left: 4,
            right: 4,
            bottom: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  // Subtitle
                  const Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Please enter the details to\ncontinue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                          fontFamily: 'Epunda Slab',
                        ),
                      ),
                    ),
                  ),

                  // Full Names Field
                  Positioned(
                    top: 120,
                    left: 24,
                    right: 24,
                    child: SizedBox(
                      height: 60,
                      child: TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Names',
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          hintText: 'Enter Your Full Names',
                          hintStyle: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          fillColor: Color.fromARGB(255, 237, 236, 236),
                          filled: true,
                          prefixIcon: const Icon(Icons.person, color: Color.fromARGB(255, 69, 141, 224)),
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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 18,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                        ),
                        cursorColor: Color(0xFF3B82F6),
                      ),
                    ),
                  ),

                  // Email Field
                  Positioned(
                    top: 190,
                    left: 24,
                    right: 24,
                    child: SizedBox(
                      height: 60,
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                          hintText: 'Enter Your Email',
                          hintStyle: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          fillColor: Color.fromARGB(255, 237, 236, 236),
                          filled: true,
                          prefixIcon: const Icon(Icons.mail, color: Color.fromARGB(255, 69, 141, 224)),
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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 18,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          fontSize: 15,
                        ),
                        cursorColor: Color(0xFF3B82F6),
                      ),
                    ),
                  ),

                  // Password Field
                  Positioned(
                    top: 260,
                    left: 24,
                    right: 24,
                    child: SizedBox(
                      height: 60,
                      child: _PasswordField(controller: _passwordController, label: 'Password'),
                    ),
                  ),

                  // Confirm Password Field
                  Positioned(
                    top: 330,
                    left: 24,
                    right: 24,
                    child: SizedBox(
                      height: 60,
                      child: _PasswordField(controller: _confirmPasswordController, label: 'Confirm Password'),
                    ),
                  ),

                  // Sign Up button
                  Positioned(
                    top: 400,
                    left: 24,
                    right: 24,
                    child: SizedBox(
                      height: 48,
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
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
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
                  const Positioned(
                    top: 460,
                    left: 24,
                    right: 24,
                    child: _OrDivider(),
                  ),

                  // Sign Up with Google button (icon on the left of the text)
                  Positioned(
                    top: 500,
                    left: 24,
                    right: 24,
                    child: SizedBox(
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          // Add Google sign up logic here
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Color(0xFFD59A00), // Orange border
                              width: 1,
                            ),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 2),
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
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const SizedBox(),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Google",
                                style: TextStyle(
                                  fontSize: 18,
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

                  // Already have account? Sign In (bottom of container)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Or navigate to your sign in screen
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PASSWORD FIELD (non-responsive, reusable for both password and confirm password)
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PasswordField({required this.controller, required this.label});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        hintText: 'Enter Your ${widget.label}',
        hintStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        fillColor: Color.fromARGB(255, 237, 236, 236),
        filled: true,
        prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 73, 122, 220)),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility_off : Icons.visibility,
            color: Color.fromARGB(255, 86, 156, 235),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 18,
        ),
      ),
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        fontSize: 15,
      ),
      cursorColor: Color(0xFFD59A00),
    );
  }
}

// OR DIVIDER (non-responsive)
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Or Sign Up With',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontFamily: 'Epunda Slab',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );
  }
}