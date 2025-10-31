import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mubs_locator/components/bottom_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  String _userFullName = 'User';
  bool _isMenuVisible = false;
  File? _profileImage;
  int _unreadNotifications = 0; // make mutable

  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isBottomNavVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchUserFullName();
    _loadProfileImage();
    _initFCM();
    _feedbackController.addListener(() {
      setState(() {});
    });
  }

  // Mark all notifications as read for current user (updates Firestore and UI)
  Future<void> _markNotificationsAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final query = await FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'read': true});
      }
      if (query.docs.isNotEmpty) await batch.commit();
      if (mounted) setState(() => _unreadNotifications = 0);
    } catch (e) {
      // ignore errors, keep UX stable
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _initFCM() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    } else {
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      String? fcmToken = await _firebaseMessaging.getToken();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': fcmToken,
        'email': user.email,
      }, SetOptions(merge: true));
    
      // load unread notifications count from Firestore
      try {
        final snap = await FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: user.uid)
            .where('read', isEqualTo: false)
            .get();
        if (mounted) setState(() => _unreadNotifications = snap.docs.length);
      } catch (e) {
        // ignore read-count fetch errors
      }
    }

    // Increment local badge/count when a message arrives while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Optionally show in-app notification
      if (message.notification != null) {
        _showCustomSnackBar(
          message.notification!.title ?? 'New notification',
          Colors.black87,
        );
      }
      if (mounted) {
        setState(() => _unreadNotifications = _unreadNotifications + 1);
      }
    });

    // When the user taps the notification and app opens, you may want to mark read
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // optionally navigate to notifications screen immediately
    });
  }

  Future<void> _fetchUserFullName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final userData = querySnapshot.docs.first.data();
          final fullName = userData['fullName'] as String?;
          if (fullName != null && fullName.isNotEmpty) {
            if (mounted) {
              setState(() {
                _userFullName = fullName;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _userFullName = 'User';
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _userFullName = 'User';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userFullName = 'User';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userFullName = 'User';
        });
        _showCustomSnackBar('Error fetching user data: $e', Colors.red);
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profileImagePath');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _showCustomSnackBar(String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    final animation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SlideTransition(
          position: animation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
                vertical: MediaQuery.of(context).size.height * 0.02,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/logo/logo.png',
                    width: MediaQuery.of(context).size.width * 0.06,
                    height: MediaQuery.of(context).size.width * 0.06,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        controller.reverse().then((_) {
          overlayEntry.remove();
          controller.dispose();
        });
      }
    });
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar('Error signing out: $e', Colors.red);
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectRating(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  Future<void> _submitFeedback() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Add feedback document
        await FirebaseFirestore.instance.collection('feedback').add({
          'userEmail': user.email,
          'userName': _userFullName,
          'feedbackText': _feedbackController.text.trim(),
          'rating': _selectedRating,
          'read': false,
          'status': 'Pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Add notification for admin
        await FirebaseFirestore.instance.collection('admin_notifications').add({
          'title': 'New Feedback Received',
          'message': '${user.email} submitted new feedback.',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        if (mounted) {
          _showCustomSnackBar(
            'Thank you! Your feedback has been sent successfully.',
            Colors.green,
          );
          setState(() {
            _feedbackController.clear();
            _selectedRating = 0;
          });
        }
      } else {
        if (mounted) {
          _showCustomSnackBar('Error: User not signed in.', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar('Error submitting feedback: $e', Colors.red);
      }
    }
  }

  bool _isFormValid() {
    return _selectedRating > 0 && _feedbackController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaler = MediaQuery.textScalerOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isMenuVisible = false;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: screenHeight * 0.09,
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.02,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isMenuVisible = !_isMenuVisible;
                                  });
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Icon(
                                  Icons.menu,
                                  color: Colors.black,
                                  size: screenWidth * 0.08,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.04),
                              Text(
                                '${_getGreeting()}, $_userFullName',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(13),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Padding(
                                padding: EdgeInsets.only(
                                  right: screenWidth * 0.04,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    // mark as read then navigate
                                    await _markNotificationsAsRead();
                                    Navigator.pushNamed(
                                      context,
                                      '/NotificationsScreen',
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: screenWidth * 0.09,
                                        height: screenWidth * 0.09,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.notifications,
                                          color: Colors.black,
                                          size: screenWidth * 0.05,
                                        ),
                                      ),
                                      if (_unreadNotifications > 0)
                                        Positioned(
                                          top: -screenWidth * 0.01,
                                          right: -screenWidth * 0.01,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: screenWidth * 0.03,
                                              minHeight: screenWidth * 0.03,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _unreadNotifications > 99
                                                    ? '99+'
                                                    : '$_unreadNotifications',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: textScaler.scale(
                                                    screenWidth * 0.025,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
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
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.09 + 16,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Provide Your Feedback',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: textScaler.scale(screenWidth * 0.05),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/HomeScreen',
                                  );
                                },
                                child: Icon(
                                  Icons.chevron_left,
                                  color: Colors.black,
                                  size: textScaler.scale(screenWidth * 0.08),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                                size: textScaler.scale(screenWidth * 0.08),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'We value your input!\nPlease share your thoughts.',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: textScaler.scale(screenWidth * 0.035),
                          fontWeight: FontWeight.w100,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top:
                    screenHeight * 0.09 +
                    75 +
                    textScaler.scale(screenWidth * 0.05) +
                    8 +
                    textScaler.scale(screenWidth * 0.04) +
                    16,
                left: 4,
                right: 4,
                child: Container(
                  height:
                      screenHeight * 0.73 -
                      textScaler.scale(screenWidth * 0.04) -
                      16,
                  width: screenWidth - 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.02,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How would you rate your experience?',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(
                                    screenWidth * 0.045,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: List.generate(5, (index) {
                                  final starIndex = index + 1;
                                  return GestureDetector(
                                    onTap: () => _selectRating(starIndex),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: screenWidth * 0.02,
                                      ),
                                      child: Icon(
                                        starIndex <= _selectedRating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: starIndex <= _selectedRating
                                            ? Colors.amber
                                            : Colors.grey,
                                        size: textScaler.scale(
                                          screenWidth * 0.07,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: screenHeight * 0.018),
                              Text(
                                'Please type below what you want us to improve',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(
                                    screenWidth * 0.045,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              TextField(
                                controller: _feedbackController,
                                maxLines: 5,
                                decoration: InputDecoration(
                                  hintText:
                                      'Tell us what you liked or what we can improve…',
                                  hintStyle: TextStyle(
                                    color: Colors.black54,
                                    fontSize: textScaler.scale(
                                      screenWidth * 0.035,
                                    ),
                                    fontFamily: 'Poppins',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFF93C5FD).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.black.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                ),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: textScaler.scale(
                                    screenWidth * 0.035,
                                  ),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _isFormValid()
                                      ? _submitFeedback
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFormValid()
                                        ? const Color(0xFF93C5FD)
                                        : Colors.grey.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.06,
                                      vertical: screenHeight * 0.015,
                                    ),
                                    elevation: _isFormValid() ? 2 : 0,
                                  ),
                                  child: Text(
                                    'Submit',
                                    style: TextStyle(
                                      color: _isFormValid()
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.7),
                                      fontSize: textScaler.scale(
                                        screenWidth * 0.04,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
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
              // Rectangle handle to show navbar
              if (!_isBottomNavVisible)
                Positioned(
                  bottom: screenHeight * 0.03,
                  left: screenWidth * 0.04,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBottomNavVisible = true;
                      });
                    },
                    child: Container(
                      width: screenWidth * 0.13,
                      height: screenHeight * 0.025,
                      decoration: BoxDecoration(
                        color: Colors.blue[300],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: textScaler.scale(18),
                        ),
                      ),
                    ),
                  ),
                ),

              // Animated BottomNavBar
              AnimatedPositioned(
                duration: Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                bottom: _isBottomNavVisible ? 0 : -screenHeight * 0.12,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 0) {
                      // Swipe down to hide navbar
                      setState(() {
                        _isBottomNavVisible = false;
                      });
                    }
                  },
                  child: BottomNavBar(
                    initialIndex: 2, // or your preferred index
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: _isMenuVisible ? 0 : -screenWidth * 0.6,
                top: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: screenWidth * 0.6,
                      height: screenHeight * 0.8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Image.asset(
                                'assets/images/sidebar.png',
                                width: screenWidth * 0.6,
                                height: screenHeight * 0.16,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                left: screenWidth * 0.03,
                                top: screenHeight * 0.03,
                                child: Container(
                                  width: screenWidth * 0.14,
                                  height: screenWidth * 0.14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.7),
                                    border: Border.all(
                                      color: Colors.white70,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _profileImage != null
                                        ? Image.file(
                                            _profileImage!,
                                            width: screenWidth * 0.14,
                                            height: screenWidth * 0.14,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: Colors.black.withOpacity(
                                              0.8,
                                            ),
                                            size: screenWidth * 0.07,
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.19,
                                top: screenHeight * 0.05,
                                child: Text(
                                  'MUBS Locator',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: textScaler.scale(15),
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Urbanist',
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.19,
                                top: screenHeight * 0.085,
                                child: Text(
                                  _userFullName,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: textScaler.scale(12),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Urbanist',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.03,
                              top: screenHeight * 0.02,
                            ),
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/HomeScreen'),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.home,
                                    color: Colors.black,
                                    size: textScaler.scale(20),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Home',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: textScaler.scale(14),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.03,
                              top: screenHeight * 0.02,
                            ),
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/ProfileScreen',
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: Colors.black,
                                    size: textScaler.scale(20),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Profile Settings',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: textScaler.scale(14),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.03,
                              top: screenHeight * 0.02,
                            ),
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/NotificationsScreen',
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    color: Colors.black,
                                    size: textScaler.scale(20),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Notifications',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: textScaler.scale(14),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.03,
                              top: screenHeight * 0.02,
                            ),
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/FeedbackScreen',
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_rounded,
                                    color: Colors.black,
                                    size: textScaler.scale(20),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Feedback & Reports',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: textScaler.scale(14),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Urbanist',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.03,
                              top: screenHeight * 0.02,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                _showLogoutDialog(context);
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.exit_to_app,
                                    color: Colors.black,
                                    size: textScaler.scale(20),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: textScaler.scale(14),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Urbanist',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
