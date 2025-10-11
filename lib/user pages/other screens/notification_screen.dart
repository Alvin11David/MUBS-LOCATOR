import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  String _userFullName = 'User';
  String? _profilePicUrl;
  bool _isMenuVisible = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _markNotificationsAsRead();
    _requestNotificationPermissions();
    _saveFcmToken();
    _listenForTokenRefresh();
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

  Future<void> _fetchUserData() async {
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
          final fullName = userData['fullName'] as String? ?? 'User';
          final profilePicUrl = userData['profilePicUrl'] as String?;
          if (mounted) {
            setState(() {
              _userFullName = fullName;
              _profilePicUrl = profilePicUrl;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userFullName = 'User';
              _profilePicUrl = null;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userFullName = 'User';
            _profilePicUrl = null;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _userFullName = 'User';
          _profilePicUrl = null;
        });
        _showCustomSnackBar('Error fetching user data: $e', Colors.red);
      }
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('Notification permissions not granted');
        if (mounted) {
          _showCustomSnackBar('Please enable notifications for updates', Colors.orange);
        }
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
      if (mounted) {
        _showCustomSnackBar('Error requesting notification permissions: $e', Colors.red);
      }
    }
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
              .set({'fcmToken': token}, SetOptions(merge: true));
          print('FCM Token saved: $token');
        } else {
          print('FCM Token is null');
          if (mounted) {
            _showCustomSnackBar('Failed to retrieve FCM token', Colors.red);
          }
        }
      } else {
        print('No user signed in');
        if (mounted) {
          _showCustomSnackBar('No user signed in', Colors.red);
        }
      }
    } catch (e) {
      print('Error saving FCM token: $e');
      if (mounted) {
        _showCustomSnackBar('Error saving FCM token: $e', Colors.red);
      }
    }
  }

  void _listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
          print('FCM Token refreshed: $token');
        }
      } catch (e) {
        print('Error refreshing FCM token: $e');
        if (mounted) {
          _showCustomSnackBar('Error refreshing FCM token: $e', Colors.red);
        }
      }
    });
  }

  Future<void> _markNotificationsAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final notificationDocs = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('user_notifications')
            .where('userRead', isEqualTo: false)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in notificationDocs.docs) {
          batch.update(doc.reference, {'userRead': true});
        }
        await batch.commit();
        print('Notifications marked as read');
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
      if (mounted) {
        _showCustomSnackBar('Error loading notifications: $e', Colors.red);
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('user_notifications')
            .doc(notificationId)
            .delete();
        if (mounted) {
          _showCustomSnackBar('Notification deleted', Colors.green);
        }
      }
    } catch (e) {
      print('Error deleting notification: $e');
      if (mounted) {
        _showCustomSnackBar('Error deleting notification: $e', Colors.red);
      }
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

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
        _showCustomSnackBar('Logout successful', Colors.green);
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
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
                                  fontSize: textScaler.scale(15),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
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
                top: screenHeight * 0.10,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: textScaler.scale(17),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.black,
                          size: textScaler.scale(24),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.14,
                left: 0,
                right: 0,
                bottom: 0,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseAuth.instance.currentUser != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('user_notifications')
                          .orderBy('timestamp', descending: true)
                          .snapshots()
                      : Stream.empty(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      String errorMessage = 'Error loading notifications';
                      if (snapshot.error.toString().contains('permission-denied')) {
                        errorMessage = 'Permission denied. Please sign in again.';
                      } else if (snapshot.error.toString().contains('network')) {
                        errorMessage = 'Network error. Please check your connection.';
                      }
                      return Center(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            fontSize: textScaler.scale(16),
                            fontFamily: 'Poppins',
                            color: Colors.red,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/vectors/nonotifications.png',
                            width: screenWidth * 0.4,
                            height: screenWidth * 0.4,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: textScaler.scale(18),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'Your notifications will appear here\nonce you’ve received them.',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: textScaler.scale(15),
                              fontFamily: 'Poppins',
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }

                    final notifications = snapshot.data!.docs;

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.02
                          ), // Removed horizontal padding
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final doc = notifications[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final adminReply = data['adminReply'] as String? ?? 'No reply';
                        final issueTitle = data['issueTitle'] as String? ?? 'No title';
                        final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                        final formattedTime = DateFormat('MMM d, yyyy h:mm a').format(timestamp);
                        final notificationId = doc.id;

                        return Dismissible(
                          key: Key(notificationId),
                          direction: DismissDirection.startToEnd, // Swipe left to delete
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 4), // Match notification padding
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Notification'),
                                content: const Text('Are you sure you want to delete this notification?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) {
                            _deleteNotification(notificationId);
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16), // 4px horizontal padding
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
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
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      'Admin Reply: $adminReply',
                                      style: TextStyle(
                                        fontSize: textScaler.scale(14),
                                        fontFamily: 'Poppins',
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      'Replied on: $formattedTime',
                                      style: TextStyle(
                                        fontSize: textScaler.scale(12),
                                        fontFamily: 'Poppins',
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
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
                                    child: _profilePicUrl != null
                                        ? Image.network(
                                            _profilePicUrl!,
                                            width: screenWidth * 0.14,
                                            height: screenWidth * 0.14,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.person,
                                              color: Colors.black.withOpacity(0.8),
                                              size: screenWidth * 0.07,
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: Colors.black.withOpacity(0.8),
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
                              onTap: () => Navigator.pushNamed(context, '/HomeScreen'),
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
                              onTap: () => Navigator.pushNamed(context, '/ProfileScreen'),
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
                              onTap: () => Navigator.pushNamed(context, '/NotificationsScreen'),
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
                              onTap: () => Navigator.pushNamed(context, '/LocationSelectScreen'),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.black,
                                    size: textScaler.scale(20),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Search Locations',
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