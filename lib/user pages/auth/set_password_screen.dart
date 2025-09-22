import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool isButtonEnabled = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password strength state
  double _passwordStrengthProgress = 0.0; // Progress from 0.0 to 1.0
  Color _strengthColor = Colors.white; // Color based on strength

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    setState(() {
      isButtonEnabled = password.isNotEmpty && confirmPassword.isNotEmpty && password == confirmPassword && _passwordStrengthProgress == 1.0;
    });
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

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                child: Stack(
                  children: [
                    // Cone image at top right
                    Positioned(
                      top: 0,
                      right: -screenWidth * 0.1,
                      child: Image.asset(
                        'assets/vectors/zigzag.png',
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
                    // Cone image at bottom left
                    Positioned(
                      bottom: 0,
                      left: -screenWidth * 0.15,
                      child: Image.asset(
                        'assets/vectors/zigzag2.png',
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
                          // Lock icon in a circle
                          Container(
                            margin: EdgeInsets.only(top: screenHeight * 0.0),
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B578F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                          // "Reset Your Password" text
                          SizedBox(height: screenHeight * 0.02),
                          SizedBox(
                            width: screenWidth * 0.8,
                            child: Text(
                              'Reset Your Password',
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
                          // "Please enter a new password below." text
                          SizedBox(height: screenHeight * 0.02),
                          SizedBox(
                            width: screenWidth * 0.8,
                            child: Text(
                              'Create a new password for your\naccount below.',
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
                          // Password inputs and submit button
                          SizedBox(height: screenHeight * 0.04),
                          Container(
                            width: screenWidth * 0.9,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // New Password field
                                TextFormField(
                                  controller: _passwordController,
                                  keyboardType: TextInputType.text,
                                  obscureText: _obscurePassword,
                                  onChanged: _checkPasswordStrength,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter a new password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: screenWidth * 0.05,
                                    ),
                                    hintText: 'Enter new password',
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
                                        Icons.lock,
                                        color: const Color.fromARGB(255, 69, 141, 224),
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                        color: const Color.fromARGB(255, 69, 141, 224),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
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
                                      vertical: screenWidth * 0.04,
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
                                // Confirm Password field
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  keyboardType: TextInputType.text,
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Confirm your password';
                                    }
                                    if (value != _passwordController.text.trim()) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: screenWidth * 0.05,
                                    ),
                                    hintText: 'Confirm your password',
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
                                        Icons.lock,
                                        color: const Color.fromARGB(255, 69, 141, 224),
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                        color: const Color.fromARGB(255, 69, 141, 224),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
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
                                      vertical: screenWidth * 0.04,
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
                                            // Navigate to SignInScreen after password reset
                                            Navigator.pushNamed(context, '/SignInScreen');
                                          }
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
                                                  Color(0xFFE0E7FF),
                                                  Color(0xFF93C5FD),
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
                                      child: Text(
                                        'Change Password',
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