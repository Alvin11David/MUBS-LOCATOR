import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'dart:ui';

import 'package:mubs_locator/user%20pages/other%20screens/edit_profile_screen.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  String? _selectedCategory;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _isDropdownVisible = false;
  bool _isMenuVisible = false;
  String? _profilePicUrl;

  final List<String> _categories = [
    'General Updates',
    'Emergency Alerts',
    'Event Reminders',
    'Promotions',
    'System Updates',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _profilePicUrl = doc.data()?['profilePicUrl'] as String?;
          });
        }
      }
    } catch (e) {
    }
  }

  Future<void> _sendNotification() async {
    if (_selectedCategory == null || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and enter a message.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to send notifications.')),
        );
        setState(() => _isSending = false);
        return;
      }
      await user.getIdToken(true);

      final idTokenResult = await user.getIdTokenResult();

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('sendGlobalNotification');
      final result = await callable.call({
        'title': 'MUBS Locator: $_selectedCategory',
        'body': _messageController.text.trim(),
        'category': _selectedCategory,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.data['message'])),
      );

      _messageController.clear();
      setState(() => _selectedCategory = null);
    } on FirebaseFunctionsException catch (e) {
      String errorMessage = 'Error sending notification: ${e.message}';
      if (e.code == 'permission-denied') {
        errorMessage = 'Admin access required to send notifications.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  void _navigateToScreen(String routeName) {
    setState(() {
      _isMenuVisible = false;
      _isDropdownVisible = false;
    });

    try {
      if (routeName == '/AdminDashboardScreen') {
        Navigator.pushReplacementNamed(context, routeName);
      } else {
        Navigator.pushNamed(context, routeName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation error: $e')),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'Admin';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (!FocusScope.of(context).hasFocus) {
                  setState(() {
                    _isMenuVisible = false;
                    _isDropdownVisible = false;
                  });
                }
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.translucent,
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
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
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
                                        _isDropdownVisible = false;
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
                                    '${_getGreeting()}, $fullName',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: screenWidth * 0.17,
                                    height: screenHeight * 0.05,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: screenWidth * 0.0),
                                          child: Container(
                                            width: screenWidth * 0.1,
                                            height: screenWidth * 0.1,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.black, width: 1),
                                            ),
                                            child: _profilePicUrl != null && _profilePicUrl!.isNotEmpty
                                                ? ClipOval(
                                                    child: Image.network(
                                                      _profilePicUrl!,
                                                      fit: BoxFit.cover,
                                                      width: screenWidth * 0.09,
                                                      height: screenWidth * 0.09,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return const CircularProgressIndicator();
                                                      },
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Icon(
                                                          Icons.person,
                                                          color: Colors.black,
                                                          size: screenWidth * 0.04,
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.person,
                                                    color: Colors.black,
                                                    size: screenWidth * 0.04,
                                                  ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(right: screenWidth * 0.01),
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isDropdownVisible = !_isDropdownVisible;
                                                _isMenuVisible = false;
                                              });
                                            },
                                            behavior: HitTestBehavior.opaque,
                                            child: Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.black,
                                              size: screenWidth * 0.04,
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
                        ),
                      ),
                    ),
                  ),
                  if (_isDropdownVisible)
                    Positioned(
                      top: screenHeight * 0.14,
                      right: screenWidth * 0.07,
                      child: Container(
                        width: screenWidth * 0.25,
                        height: screenHeight * 0.06,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
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
                            child: Container(
                              color: Colors.transparent,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: screenHeight * 0.01,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                    );
                                    if (result != null && result is Map<String, dynamic>) {
                                      setState(() {
                                        _profilePicUrl = result['imageUrl'] as String?;
                                        _isDropdownVisible = false;
                                      });
                                    }
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Profile',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.04,
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
                    ),
                  Positioned(
                    top: screenHeight * 0.1,
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Push Notifications',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Fill in the form below to send a\nnotification to all MUBS Locator users',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Icon(
                                Icons.chevron_left,
                                color: Colors.black,
                                size: screenWidth * 0.08,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: screenWidth * 0.08,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.23,
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                    child: Container(
                      height: screenHeight * 0.75,
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send Push Notification',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Category',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            GestureDetector(
                              onTap: () {},
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035, vertical: screenHeight * 0.00),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Color(0xFF93C5FD), width: 1),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    hint: const Text('Select Category'),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                                    isExpanded: true,
                                    items: _categories.map((category) {
                                      return DropdownMenuItem(
                                        value: category,
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: screenWidth * 0.04,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Text(
                              'Message',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            GestureDetector(
                              onTap: () {},
                              behavior: HitTestBehavior.opaque,
                              child: TextField(
                                controller: _messageController,
                                maxLines: 5,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type your message here...',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.05),
                            Center(
                              child: GestureDetector(
                                onTap: _isSending ? null : _sendNotification,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.2,
                                    vertical: screenHeight * 0.013,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF93C5FD),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.black, width: 1),
                                  ),
                                  child: _isSending
                                      ? const CircularProgressIndicator(color: Colors.black)
                                      : Text(
                                          'Send Notification',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _isMenuVisible ? 0 : -screenWidth * 0.6,
                    top: MediaQuery.of(context).padding.top,
                    child: Container(
                      width: screenWidth * 0.6,
                      height: screenHeight * 0.8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: Offset(2, 0),
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
                                left: screenWidth * 0.0,
                                top: screenHeight * 0.03,
                                child: Container(
                                  width: screenWidth * 0.15,
                                  height: screenWidth * 0.15,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1,
                                    ),
                                  ),
                                  child: (_profilePicUrl != null &&
                                          _profilePicUrl!.isNotEmpty)
                                      ? ClipOval(
                                          child: Image.network(
                                            _profilePicUrl!,
                                            fit: BoxFit.cover,
                                            width: screenWidth * 0.15,
                                            height: screenWidth * 0.15,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const CircularProgressIndicator();
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                              Icons.person,
                                              color: Colors.black,
                                              size: screenWidth * 0.08,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          color: Colors.black,
                                          size: screenWidth * 0.08,
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
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Urbanist',
                                  ),
                                ),
                              ),
                              Positioned(
                                left: screenWidth * 0.19,
                                top: screenHeight * 0.09,
                                child: Text(
                                  fullName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Urbanist',
                                  ),
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
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/AdminDashboardScreen',
                                );
                                setState(() {
                                  _isMenuVisible = false;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.dashboard,
                                    color: Colors.black,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Dashboard',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
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
                                Navigator.pushNamed(context, '/FeedbackListScreen');
                                setState(() {
                                  _isMenuVisible = false;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat,
                                    color: Colors.black,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Feedback & Reports',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
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
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                );
                                if (result != null && result is Map<String, dynamic>) {
                                  setState(() {
                                    _profilePicUrl = result['imageUrl'] as String?;
                                    _isMenuVisible = false;
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: Colors.black,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Profile Settings',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
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
                                Navigator.pushNamed(context, '/SendNotificationsScreen');
                                setState(() {
                                  _isMenuVisible = false;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    color: Colors.black,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Push Notifications',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
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
                                Navigator.pushNamed(context, '/LocationManagementScreen');
                                setState(() {
                                  _isMenuVisible = false;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.black,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Locations',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
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
                              onTap: _logout,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.exit_to_app,
                                    color: Colors.black,
                                    size: screenWidth * 0.06,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String text, String? route) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02),
      child: GestureDetector(
        onTap: route != null
            ? () => _navigateToScreen(route)
            : null,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: screenWidth * 0.06),
            SizedBox(width: screenWidth * 0.02),
            Text(
              text,
              style: TextStyle(
                color: Colors.black,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                fontFamily: 'Urbanist',
              ),
            ),
          ],
        ),
      ),
    );
  }
}