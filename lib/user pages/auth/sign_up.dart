import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Add your OAuth Web Client ID from Firebase Console
    clientId: '1:700901312627:web:c2dfd9dcd0d03865050206.apps.googleusercontent.com',
    scopes: ['email'],
  );
  bool _isLoading = false;
  // Password strength state
  double _passwordStrengthProgress = 0.0;
  Color _strengthColor = Colors.white;
  List<String> _passwordHints = [];
  // Email availability state
  String? _emailHint;
  Timer? _debounce;

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
    _debounce?.cancel();
    super.dispose();
  }

  // Password strength calculation with hints
  void _checkPasswordStrength(String password) {
    int strengthScore = 0;
    List<String> hints = [];
    bool hasMinLength = password.length >= 6;
    if (hasMinLength) {
      strengthScore++;
    } else {
      hints.add("Password must be at least 6 characters long");
    }
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    if (hasLowercase) {
      strengthScore++;
    } else {
      hints.add("Add at least one lowercase letter (a-z)");
    }
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    if (hasUppercase) {
      strengthScore++;
    } else {
      hints.add("Add at least one uppercase letter (A-Z)");
    }
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    if (hasNumber) {
      strengthScore++;
    } else {
      hints.add("Consider adding a number (0-9)");
    }
    bool hasSpecial = password.contains(RegExp(r'[!@#\$&*~]'));
    if (hasSpecial) {
      strengthScore++;
    } else {
      hints.add("Consider adding a special character (!@#\$&*~)");
    }
    setState(() {
      double progress = (strengthScore / 3.0).clamp(0.0, 1.0);
      if (hasMinLength && hasLowercase && hasUppercase) {
        _passwordStrengthProgress = 1.0;
        _strengthColor = Colors.green;
      } else {
        _passwordStrengthProgress = (strengthScore / 3.0).clamp(0.0, 0.6);
        _strengthColor = Colors.red;
      }
      if (_passwordStrengthProgress < 1.0) {
        _passwordHints = hints;
      } else {
        _passwordHints = [];
      }
    });
  }

  // Check email availability with debounce using Firestore
  void _checkEmailAvailability(String email) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (email.trim().isEmpty) {
        setState(() => _emailHint = null);
        return;
      }
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email.trim())) {
        setState(() => _emailHint = 'Invalid email format');
        return;
      }
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email.trim())
            .limit(1)
            .get();
        setState(() {
          _emailHint = query.docs.isNotEmpty ? 'Email already in use' : null;
        });
      } catch (e) {
        print('Error checking email availability: $e');
        setState(() => _emailHint = 'Error checking email');
      }
    });
  }

  // Save FCM token to Firestore
  Future<void> _saveFcmToken(String uid, String email) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set({
              'fcmToken': token,
              'email': email.toLowerCase(),
            }, SetOptions(merge: true));
        print('FCM token saved: $token');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
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
    if (_emailHint != null) {
      print('Validation failed: Email already in use');
      return _emailHint;
    }
    if (_passwordController.text.trim().isEmpty) {
      print('Validation failed: Password empty');
      return 'Please enter a password';
    }
    if (_passwordController.text.trim().length < 6) {
      print('Validation failed: Password too short');
      return 'Password must be at least 6 characters';
    }
    if (_confirmPasswordController.text.trim() != _passwordController.text.trim()) {
      print('Validation failed: Passwords do not match');
      return 'Passwords do not match';
    }
    print('Validation passed');
    return null;
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

  // Firebase signup function
  Future<void> _signUp() async {
    print('Sign up button pressed');
    final error = _validateForm();
    if (error != null) {
      print('Form error: $error');
      if (mounted) {
        _showCustomSnackBar(context, error);
      }
      return;
    }
    setState(() => _isLoading = true);
    print('Attempting Firebase sign up for email: ${_emailController.text.trim()}');
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('Firebase sign up successful: ${userCredential.user?.uid}');
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(_fullNameController.text.trim());
        print('Display name updated to: ${_fullNameController.text.trim()}');
        // Save user info and FCM token to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim().toLowerCase(),
          'password': _passwordController.text.trim(), // Note: Storing passwords in Firestore is not recommended
          'phone': '', // Initialize as empty, editable in EditProfileScreen
          'location': '', // Initialize as empty, editable in EditProfileScreen
          'profilePicUrl': null, // Initialize as null for default person icon
          'authProvider': 'email',
          'isAdmin': _emailController.text.trim().toLowerCase() == 'adminuser@gmail.com',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'fcmToken': await FirebaseMessaging.instance.getToken(), // Save FCM token
          'lastActiveTimestamp': Timestamp.now(), // Add lastActiveTimestamp
        }, SetOptions(merge: true));
        print('User info, FCM token, and lastActiveTimestamp saved to Firestore');
      }
      if (mounted) {
        print('Navigating based on email');
        _showCustomSnackBar(context, 'Account created successfully!', isSuccess: true);
        await Future.delayed(const Duration(seconds: 2)); // Wait for SnackBar to dismiss
        if (_emailController.text.trim().toLowerCase() == 'adminuser@gmail.com') {
          print('Admin email detected, navigating to AdminDashboardScreen');
          Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
        } else {
          print('Regular user, navigating to HomeScreen');
          Navigator.pushReplacementNamed(context, '/HomeScreen');
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
          message = 'Firebase error: ${e.code} - ${e.message ?? "Unknown error"}';
      }
      if (mounted) {
        _showCustomSnackBar(context, message);
      }
    } catch (e, stackTrace) {
      print('Signup error: $e\nStack trace: $stackTrace');
      if (mounted) {
        _showCustomSnackBar(context, 'Unexpected error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print('Sign up process finished');
    }
  }

  // Google Sign-In function
  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    print('Attempting Google Sign-In...');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      print('Google user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('Firebase sign-in successful: ${userCredential.user?.uid}');
      // Save user info to Firestore with all fields
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'fullName': userCredential.user!.displayName ?? 'Google User',
            'email': userCredential.user!.email ?? '',
            'phone': '',
            'location': '',
            'profilePicUrl': userCredential.user!.photoURL,
            'authProvider': 'google',
            'isAdmin': userCredential.user!.email?.toLowerCase() == 'adminuser@gmail.com',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'fcmToken': await FirebaseMessaging.instance.getToken(), // Save FCM token
          }, SetOptions(merge: true));
      print('User info saved to Firestore');
      if (mounted) {
        _showCustomSnackBar(context, 'Signed up with Google successfully!', isSuccess: true);
        await Future.delayed(const Duration(seconds: 2));
        if (userCredential.user!.email?.toLowerCase() == 'adminuser@gmail.com') {
          print('Admin email detected, navigating to AdminDashboardScreen');
          Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
        } else {
          print('Regular user, navigating to HomeScreen');
          Navigator.pushReplacementNamed(context, '/HomeScreen');
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          message = 'The credential is malformed or has expired.';
          break;
        case 'operation-not-allowed':
          message = 'Google sign-in is not enabled.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = 'Google sign-in failed: ${e.message ?? "Unknown error"}';
      }
      if (mounted) {
        _showCustomSnackBar(context, message);
      }
    } catch (e, stackTrace) {
      print('Google Sign-In error: $e\nStack trace: $stackTrace');
      if (mounted) {
        _showCustomSnackBar(context, 'Google sign-in failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      print('Google Sign-In process finished');
    }
  }

  // Check if passwords match for enabling Sign Up button
  bool _isSignUpEnabled() {
    bool hasMinLength = _passwordController.text.trim().length >= 6;
    bool hasLowercase = _passwordController.text.contains(RegExp(r'[a-z]'));
    bool hasUppercase = _passwordController.text.contains(RegExp(r'[A-Z]'));
    return _passwordController.text.trim() == _confirmPasswordController.text.trim() &&
        _passwordController.text.trim().isNotEmpty &&
        hasMinLength &&
        hasLowercase &&
        hasUppercase &&
        _emailHint == null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  width: screenWidth,
                  height: screenHeight,
                  color: const Color(0xFF93C5FD),
                ),
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
                Positioned(
                  top: screenHeight * 0.31,
                  left: screenWidth * 0.02,
                  right: screenWidth * 0.02,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: screenHeight * 0.69,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.04,
                            horizontal: screenWidth * 0.02,
                          ),
                          child: Column(
                            children: [
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
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                                child: _ResponsiveTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'Enter Your Email',
                                  icon: Icons.mail,
                                  focusNode: _emailFocus,
                                  nextFocusNode: _passwordFocus,
                                  textInputAction: TextInputAction.next,
                                  onChanged: _checkEmailAvailability,
                                ),
                              ),
                              if (_emailHint != null)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.06,
                                    vertical: screenHeight * 0.005,
                                  ),
                                  child: Text(
                                    '• $_emailHint',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: screenWidth * 0.035,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                                child: _ResponsivePasswordField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  focusNode: _passwordFocus,
                                  nextFocusNode: _confirmPasswordFocus,
                                  textInputAction: TextInputAction.next,
                                  onChanged: _checkPasswordStrength,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01,
                                  horizontal: screenWidth * 0.06,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: const Color.fromARGB(255, 255, 253, 253),
                                            width: 1,
                                          ),
                                        ),
                                      ),
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
                              Builder(
                                builder: (context) {
                                  final List<String> hints = _passwordHints;
                                  if (hints.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.06,
                                      vertical: screenHeight * 0.005,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: hints
                                          .map(
                                            (hint) => Padding(
                                              padding: const EdgeInsets.only(bottom: 2.0),
                                              child: Text(
                                                '• $hint',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: screenWidth * 0.035,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                                child: _ResponsivePasswordField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  focusNode: _confirmPasswordFocus,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.06,
                                  child: GestureDetector(
                                    onTap: _isLoading || !_isSignUpEnabled() ? null : _signUp,
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
                                                colors: [Color(0xFFE0E7FF), Color(0xFF93C5FD)],
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
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                              ),
                                            )
                                          : Text(
                                              "Sign Up",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.05,
                                                fontWeight: FontWeight.bold,
                                                color: _isSignUpEnabled() ? Colors.black : Colors.grey,
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
                                child: _OrDivider(
                                  fontSize: screenWidth * 0.04,
                                  horizontalPadding: screenWidth * 0.02,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.06,
                                  child: GestureDetector(
                                    onTap: _isLoading ? null : _signUpWithGoogle,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: _isLoading
                                              ? Colors.grey
                                              : const Color(0xFFD59A00),
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
                                          Navigator.pushNamed(context, '/SignInScreen');
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
                              SizedBox(height: screenHeight * 0.05),
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

class _ResponsiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;

  const _ResponsiveTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onChanged: onChanged,
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
          fontSize: screenWidth * 0.045,
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
          vertical: screenWidth * 0.03,
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
    );
  }
}

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
          fontSize: screenWidth * 0.045,
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
          vertical: screenWidth * 0.03,
          horizontal: screenWidth * 0.05,
        ),
      ),
      style: TextStyle(
        color: Colors.black,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        fontSize: screenWidth * 0.04,
      ),
      cursorColor: const Color(0xFFD59A00),
    );
  }
}

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