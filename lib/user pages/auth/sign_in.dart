import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Focus nodes for field navigation
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  // Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId:
        '700901312627-jajad1h1v8qia7k47toir97tlcrfjgeh.apps.googleusercontent.com',
  );

  bool isButtonEnabled = false;
  bool _isLoading = false;
  bool _isForgotPasswordTapped = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _checkLoginState();
    _loadLastCredentials();
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.email?.toLowerCase() == 'adminuser@gmail.com') {
          Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
        } else {
          Navigator.pushReplacementNamed(context, '/HomeScreen');
        }
      }
    }
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

  Future<void> _saveFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'fcmToken': token,
                'email': user.email?.toLowerCase(),
              }, SetOptions(merge: true));
        }
      }
    } catch (e) {}
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      // Query Firestore to get the stored password
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('No user found for that email.');
      }

      final userDoc = userQuery.docs.first;
      final storedPassword = userDoc.data()['password'] as String?;

      if (storedPassword == null) {
        throw Exception('No password found for this user.');
      }

      if (storedPassword != password) {
        throw Exception('Incorrect password.');
      }

      // Password matches in Firestore, proceed with Firebase Authentication
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Update lastActiveTimestamp in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
            'lastActiveTimestamp': Timestamp.now(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .catchError((e) async {
            // If document doesn't exist (edge case), create it
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
                  'uid': userCredential.user!.uid,
                  'email': email,
                  'displayName': userCredential.user!.displayName ?? 'User',
                  'lastActiveTimestamp': Timestamp.now(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                  'phone': '',
                  'location': '',
                  'profilePicUrl': null,
                  'isAdmin': email == 'adminuser@gmail.com',
                  'fcmToken': await FirebaseMessaging.instance.getToken(),
                }, SetOptions(merge: true));
          });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Save last email and password
      await prefs.setString('lastEmail', email);
      await prefs.setString('lastPassword', password);

      // Save FCM token and email after sign-in
      await _saveFcmToken();

      if (mounted) {
        if (email == 'adminuser@gmail.com') {
          Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
        } else {
          Navigator.pushReplacementNamed(context, '/HomeScreen');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign in failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please check your email and password.';
      }
      _showCustomSnackBar(context, message);
    } catch (e) {
      _showCustomSnackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      GoogleSignInAccount? googleUser;
      GoogleSignInAuthentication? googleAuth;

      if (kIsWeb) {
        final webGoogleSignIn = GoogleSignIn(
          clientId:
              '700901312627-jajad1h1v8qia7k47toir97tlcrfjgeh.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );
        googleUser = await webGoogleSignIn.signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        googleAuth = await googleUser.authentication;
      } else {
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        googleAuth = await googleUser.authentication;
      }

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception('No ID token or access token received');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': user.displayName ?? 'Google User',
          'email': user.email ?? '',
          'profilePicUrl': user.photoURL,
          'authProvider': 'google',
          'isAdmin': user.email?.toLowerCase() == 'adminuser@gmail.com',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'fcmToken': await FirebaseMessaging.instance.getToken(),
        }, SetOptions(merge: true));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        final email = userCredential.user?.email?.toLowerCase();
        if (email == 'adminuser@gmail.com') {
          Navigator.pushReplacementNamed(context, '/AdminDashboardScreen');
        } else {
          Navigator.pushReplacementNamed(context, '/HomeScreen');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Google sign-in failed';
      if (e.code == 'account-exists-with-different-credential') {
        message = 'An account already exists with the same email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credential. Please try again.';
      }
      _showCustomSnackBar(context, message);
    } catch (e) {
      _showCustomSnackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(BuildContext context, String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/logo/logo.png',
              width: screenWidth * 0.08,
              height: screenWidth * 0.08,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(width: 24),
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

  Future<void> _loadLastCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('lastEmail') ?? '';
    final lastPassword = prefs.getString('lastPassword') ?? '';
    setState(() {
      _emailController.text = lastEmail;
      _passwordController.text = lastPassword;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = constraints.maxWidth;
            double screenHeight = constraints.maxHeight;

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
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(),
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
                //Install App Button 
                  Positioned(
                    top: screenHeight * 0.01,
                    left: 0,
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
                                      fontSize: screenWidth * 0.045,
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
                      // keep the white container size fixed (resizeToAvoidBottomInset: false)
                      // but allow extra scrollable space so fields/buttons can be scrolled above the keyboard
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        // add the keyboard inset so content can be scrolled into view when keyboard is visible
                        bottom:
                            MediaQuery.of(context).viewInsets.bottom +
                            screenHeight * 0.8,
                      ),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                ),
                                child: EmailField(
                                  controller: _emailController,
                                  focusNode: _emailFocus,
                                  nextFocusNode: _passwordFocus,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                ),
                                child: PasswordField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  onFieldSubmitted: (_) {
                                    if (isButtonEnabled && !_isLoading) {
                                      _signIn();
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Padding(
                                padding: EdgeInsets.only(
                                  right: screenWidth * 0.06,
                                ),
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
                                      Navigator.pushNamed(
                                        context,
                                        '/ForgotPasswordScreen',
                                      );
                                    },
                                    onTapCancel: () {
                                      setState(() {
                                        _isForgotPasswordTapped = false;
                                      });
                                    },
                                    onTap: () {},
                                    child: Text(
                                      "",
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: screenHeight * 0.06,
                                  child: GestureDetector(
                                    onTap: isButtonEnabled && !_isLoading
                                        ? _signIn
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: isButtonEnabled
                                              ? const Color(0xFF3B82F6)
                                              : Colors.grey,
                                          width: 1,
                                        ),
                                        gradient: isButtonEnabled
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFFE0E7FF),
                                                  Color(0xFF93C5FD),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFFE5E7EB),
                                                  Color(0xFFD1D5DB),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                      ),
                                      alignment: Alignment.center,
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.black,
                                                  ),
                                            )
                                          : Text(
                                              "Sign In",
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.05,
                                                fontWeight: FontWeight.bold,
                                                color: isButtonEnabled
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
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.08,
                                ),
                                child: const OrDivider(),
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
                                          Navigator.pushNamed(
                                            context,
                                            '/SignUpScreen',
                                          );
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

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const EmailField({
    super.key,
    required this.controller,
    this.focusNode,
    this.nextFocusNode,
  });

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email address';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@gmail\.com$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a Gmail address (e.g., username@gmail.com)';
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
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: _validateEmail,
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            }
          },
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
              child: const Icon(
                Icons.mail,
                color: Color.fromARGB(255, 69, 141, 224),
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
      },
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onFieldSubmitted,
  });

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
          focusNode: widget.focusNode,
          obscureText: _isObscured,
          textInputAction: TextInputAction.done,
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter your password' : null,
          onFieldSubmitted: widget.onFieldSubmitted,
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
      },
    );
  }
}

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
                
              ),
              Expanded(child: Container(height: 1, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}
