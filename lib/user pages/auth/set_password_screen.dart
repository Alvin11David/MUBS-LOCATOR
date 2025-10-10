import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  bool isButtonEnabled = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final bool _obscureCurrentPassword = true;
  bool _isLoading = false;
  double _passwordStrengthProgress = 0.0;
  Color _strengthColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
    _currentPasswordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    setState(() {
      isButtonEnabled = password.isNotEmpty &&
          confirmPassword.isNotEmpty &&
          currentPassword.isNotEmpty &&
          password == confirmPassword &&
          _passwordStrengthProgress == 1.0;
    });
  }

  void _checkPasswordStrength(String password) {
    int strengthScore = 0;
    if (password.isNotEmpty) strengthScore++;
    if (password.length >= 8) strengthScore++;
    if (password.contains(RegExp(r'[a-z]'))) strengthScore++;
    if (password.contains(RegExp(r'[A-Z]'))) strengthScore++;
    if (password.contains(RegExp(r'[0-9]'))) strengthScore++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strengthScore++;

    setState(() {
      _passwordStrengthProgress = strengthScore / 6.0;
      if (strengthScore <= 2) {
        _strengthColor = Colors.red;
      } else if (strengthScore <= 4) {
        _strengthColor = Colors.orange;
      } else {
        _strengthColor = Colors.green;
      }
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

  Future<void> _handleChangePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final auth = FirebaseAuth.instance;
      final email = widget.email;
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _passwordController.text.trim();

      // Re-authenticate the user
      final user = auth.currentUser;
      if (user == null) {
        await auth.signInWithEmailAndPassword(
          email: email,
          password: currentPassword,
        );
      } else if (user.email != email) {
        throw Exception('Current user does not match provided email');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await auth.currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await auth.currentUser!.updatePassword(newPassword);

      // Update password in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .update({'password': newPassword});

      // Delete OTP from Firestore
      await FirebaseFirestore.instance
          .collection('password_reset_tokens')
          .doc(email)
          .delete();

      if (mounted) {
        _currentPasswordController.text = _passwordController.text;
        _passwordController.clear();
        _confirmPasswordController.clear();

        _showCustomSnackBar(context, 'Password updated successfully!', isSuccess: true);
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/SignInScreen',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(context, 'Error updating password: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordController.dispose();
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
                "Reset Your\nPassword",
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
                        vertical: screenHeight * 0.04,
                        horizontal: screenWidth * 0.05,
                      ),
                      child: Column(
                        children: [
                          Container(
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
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Reset Your Password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              fontFamily: 'Epunda Slab',
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          Container(
                            width: screenWidth * 0.9,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  onChanged: _checkPasswordStrength,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                    hintText: 'Enter New Password',
                                    hintStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(255, 237, 236, 236),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: Color(0xFF458DE0),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                        color: Color(0xFF458DE0),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                        color: Color(0xFFD59A00),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
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
                                    fontSize: screenWidth * 0.04,
                                  ),
                                  cursorColor: const Color(0xFF3B82F6),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.01,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 6,
                                          color: Colors.white,
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: _passwordStrengthProgress,
                                          child: Container(
                                            height: 6,
                                            color: _strengthColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                    hintText: 'Confirm New Password',
                                    hintStyle: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(255, 237, 236, 236),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: Color(0xFF458DE0),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                        color: Color(0xFF458DE0),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                        color: Color(0xFFD59A00),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
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
                                    fontSize: screenWidth * 0.04,
                                  ),
                                  cursorColor: const Color(0xFF3B82F6),
                                ),
                                SizedBox(height: screenHeight * 0.03),
                                SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.06,
                                  child: GestureDetector(
                                    onTap: isButtonEnabled && !_isLoading ? _handleChangePassword : null,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: const Color(0xFF3B82F6),
                                          width: 1,
                                        ),
                                        gradient: LinearGradient(
                                          colors: isButtonEnabled && !_isLoading
                                              ? [Color(0xFFE0E7FF), Color(0xFF93C5FD)]
                                              : [Colors.grey[300]!, Colors.grey[500]!],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            )
                                          : Text(
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account, ',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.bold,
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
                                          color: Color(0xFF93C5FD),
                                          fontFamily: 'Epunda Slab',
                                        ),
                                      ),
                                    ),
                                  ],
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