import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ADD THIS
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
// ADD THIS

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

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mobile Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  bool _isLoading = false;
  double _passwordStrengthProgress = 0.0;
  Color _strengthColor = Colors.white;
  List<String> _passwordHints = [];
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
      _passwordStrengthProgress = (strengthScore / 3.0).clamp(0.0, 1.0);
      _strengthColor = (hasMinLength && hasLowercase && hasUppercase)
          ? Colors.green
          : Colors.red;
      _passwordHints = _passwordStrengthProgress < 1.0 ? hints : [];
    });
  }

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
        setState(() => _emailHint = 'Error checking email');
      }
    });
  }

  static const String APK_URL =
      'https://drive.google.com/file/d/1BuzlGSBq8drL5JoTwCj5aUJ8mO4gq8-U/view?usp=sharing'; 

  Future<void> _downloadApk() async {
    await Permission.storage.request();
    await Permission.notification.request();

    const downloadsDir = '/storage/emulated/0/Download';

    final taskId = await FlutterDownloader.enqueue(
      url: APK_URL,
      savedDir: downloadsDir,
      showNotification: true,
      openFileFromNotification: true,
      fileName: 'MUBS_Locator.apk',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(taskId != null ? 'Downloading APK… Check notifications.' : 'Failed to start download.')),
    );
  }

  Future<void> _saveFcmToken(String uid, String email) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'email': email.toLowerCase(),
        }, SetOptions(merge: true));
      }
    } catch (e) {}
  }

  String? _validateForm() {
    if (_fullNameController.text.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (_emailController.text.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      return 'Please enter a valid email';
    }
    if (_emailHint != null) return _emailHint;
    if (_passwordController.text.trim().isEmpty) {
      return 'Please enter a password';
    }
    if (_passwordController.text.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (_confirmPasswordController.text.trim() !=
        _passwordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _showCustomSnackBar(
    BuildContext context,
    String message, {
    bool isSuccess = false,
  }) {
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
              errorBuilder: (_, __, ___) => const SizedBox(width: 24),
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

  Future<void> _signUp() async {
    final error = _validateForm();
    if (error != null) {
      _showCustomSnackBar(context, error);
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(
          _fullNameController.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'fullName': _fullNameController.text.trim(),
              'email': _emailController.text.trim().toLowerCase(),
              'password': _passwordController.text.trim(),
              'phone': '',
              'location': '',
              'profilePicUrl': null,
              'authProvider': 'email',
              'isAdmin':
                  _emailController.text.trim().toLowerCase() ==
                  'adminuser@gmail.com',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'fcmToken': await FirebaseMessaging.instance.getToken(),
              'lastActiveTimestamp': Timestamp.now(),
            }, SetOptions(merge: true));
      }
      _showCustomSnackBar(
        context,
        'Account created successfully!',
        isSuccess: true,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          _emailController.text.trim().toLowerCase() == 'adminuser@gmail.com'
              ? '/AdminDashboardScreen'
              : '/HomeScreen',
        );
      }
    } on FirebaseAuthException catch (e) {
      _showCustomSnackBar(context, e.message ?? 'Sign-up failed');
    } catch (e) {
      _showCustomSnackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // MOBILE: Google Sign-Up
  Future<void> _signUpWithGoogleMobile() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) throw Exception('No ID token');

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await _finishGoogleSignUp(credential);
    } catch (e) {
      _showCustomSnackBar(context, 'Google sign-up failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // WEB: Google Sign-Up
  Future<void> _signUpWithGoogleWeb() async {
    setState(() => _isLoading = true);
    try {
      // Use the existing GoogleSignIn instance (works on web & mobile)
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw Exception('Google Sign-In failed — no tokens returned.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      await _finishGoogleSignUp(credential);
    } catch (e) {
      // Handle/display error as appropriate in your app
      if (mounted) setState(() => _isLoading = false);
      rethrow;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Shared Google Sign-Up Logic
  Future<void> _finishGoogleSignUp(AuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': user.displayName ?? 'Google User',
        'email': user.email ?? '',
        'phone': '',
        'location': '',
        'profilePicUrl': user.photoURL,
        'authProvider': 'google',
        'isAdmin': user.email?.toLowerCase() == 'adminuser@gmail.com',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'fcmToken': await FirebaseMessaging.instance.getToken(),
      }, SetOptions(merge: true));
    }

    _showCustomSnackBar(context, 'Signed up with Google!', isSuccess: true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        user?.email?.toLowerCase() == 'adminuser@gmail.com'
            ? '/AdminDashboardScreen'
            : '/HomeScreen',
      );
    }
  }

  bool _isSignUpEnabled() {
    bool hasMinLength = _passwordController.text.trim().length >= 6;
    bool hasLowercase = _passwordController.text.contains(RegExp(r'[a-z]'));
    bool hasUppercase = _passwordController.text.contains(RegExp(r'[A-Z]'));
    return _passwordController.text.trim() ==
            _confirmPasswordController.text.trim() &&
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
                Container(color: const Color(0xFF93C5FD)),
                Positioned(
                  top: screenHeight * 0.05,
                  left: screenWidth * 0.5 - (screenWidth * 0.2) / 2,
                  child: Image.asset(
                    'assets/logo/logo.png',
                    width: screenWidth * 0.2,
                    height: screenHeight * 0.1,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(),
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
                //Install App Button 
                  Positioned(
                    top: screenHeight * 0.01,
                    left: screenWidth * 0.65,
                    right: 0,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: GestureDetector(
                            onTap: _downloadApk,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.0,
                                vertical: screenHeight * 0.009,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white, width: 1.5),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone_iphone,
                                    color: Colors.white,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Install App',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.043,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                      // keep the white container size fixed (no resizing of scaffold)
                      // but allow extra vertical scroll when keyboard is visible
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).viewInsets.bottom +
                            screenHeight * 0.06,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: screenHeight * 1.2,
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
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.black,
                                    fontFamily: 'Epunda Slab',
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
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
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                ),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
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
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          border: Border.all(
                                            color: const Color.fromARGB(
                                              255,
                                              255,
                                              253,
                                              253,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_passwordHints.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.06,
                                    vertical: screenHeight * 0.005,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _passwordHints
                                        .map(
                                          (h) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 2.0,
                                            ),
                                            child: Text(
                                              '• $h',
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
                                ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                ),
                                child: _ResponsivePasswordField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  focusNode: _confirmPasswordFocus,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
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
                                          color:
                                              _isLoading || !_isSignUpEnabled()
                                              ? Colors.grey
                                              : const Color(0xFF3B82F6),
                                          width: 1,
                                        ),
                                        gradient:
                                            _isLoading || !_isSignUpEnabled()
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
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.black),
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
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          '/SignInScreen',
                                        ),
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

// Keep your existing _ResponsiveTextField, _ResponsivePasswordField, _OrDivider
// (Copy-paste from your original code — unchanged)
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
          child: Icon(icon, color: const Color.fromARGB(255, 69, 141, 224)),
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
          onPressed: () => setState(() => _isObscured = !_isObscured),
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
