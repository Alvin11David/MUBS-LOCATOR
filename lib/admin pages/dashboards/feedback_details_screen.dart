import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'dart:ui';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mubs_locator/user%20pages/other%20screens/edit_profile_screen.dart';

class FeedbackDetailsScreen extends StatefulWidget {
  final String feedbackId;

  const FeedbackDetailsScreen({super.key, required this.feedbackId});

  @override
  State<FeedbackDetailsScreen> createState() => _FeedbackDetailsScreenState();
}

class _FeedbackDetailsScreenState extends State<FeedbackDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isDropdownVisible = false;
  bool _isMenuVisible = false;
  bool _isMoreMenuVisible = false;
  String? _profilePicUrl;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  // Make _feedbackFuture nullable and initialize as null
  Future<DocumentSnapshot>? _feedbackFuture;

  @override
  void initState() {
    super.initState();
    // Initialize _feedbackFuture with the actual feedbackId
    _feedbackFuture = FirebaseFirestore.instance
        .collection('feedback')
        .doc(widget.feedbackId)
        .get();

    // Fetch profile image from Firebase Authentication
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.photoURL != null) {
      setState(() {
        _profilePicUrl = user.photoURL;
      });
    }

    // Ensure TextField is scrolled into view when focused
    _replyFocusNode.addListener(() {
      if (_replyFocusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Scrollable.ensureVisible(context, alignment: 0.5);
        });
      }
    });
  }

  void _navigateToEditProfile() async {
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

  void _showCustomSnackBar(String message, Color backgroundColor,
      {required Duration duration}) {
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
        top: MediaQuery.of(context).padding.top,
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
                borderRadius: BorderRadius.circular(20),
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
    Future.delayed(duration, () {
      if (mounted) {
        controller.reverse().then((_) {
          overlayEntry.remove();
          controller.dispose();
        });
      }
    });
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

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      _showCustomSnackBar('Please enter a reply', Colors.red,
          duration: const Duration(seconds: 2));
      return;
    }

    try {
      final feedbackDoc = await FirebaseFirestore.instance
          .collection('feedback')
          .doc(widget.feedbackId)
          .get();
      if (!feedbackDoc.exists) {
        _showCustomSnackBar('Feedback not found', Colors.red,
            duration: const Duration(seconds: 2));
        return;
      }
      final feedbackData = feedbackDoc.data()!;
      final userEmail = feedbackData['userEmail'] as String? ?? 'Unknown';
      final issueTitle = feedbackData['issueTitle'] as String? ?? 'No title';
      final buildingName = feedbackData['buildingName'] as String? ?? 'Unknown';

      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(widget.feedbackId)
          .update({
        'adminReply': _replyController.text.trim(),
        'replyTimestamp': Timestamp.now(),
        'read': true,
        'status': 'In Review',
        'userRead': false,
      });

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        _showCustomSnackBar('User not found', Colors.red,
            duration: const Duration(seconds: 2));
        return;
      }
      final userUid = userQuery.docs.first.id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('user_notifications')
          .add({
        'feedbackId': widget.feedbackId,
        'adminReply': _replyController.text.trim(),
        'issueTitle': issueTitle,
        'buildingName': buildingName,
        'timestamp': Timestamp.now(),
        'userRead': false,
      });

      try {
        await FirebaseFunctions.instance
            .httpsCallable('sendFeedbackReplyNotification')
            .call({
          'userEmail': userEmail,
          'title': 'New Feedback Reply',
          'body': 'You have a new reply to your feedback: ${issueTitle}',
        });
      } catch (e) {
        print('Error sending FCM notification: $e');
      }

      _showCustomSnackBar('Reply sent successfully', Colors.green,
          duration: const Duration(seconds: 3));
      _replyController.clear();
      _replyFocusNode.unfocus();
      // Refresh the Future to update the UI after sending reply
      setState(() {
        _feedbackFuture = FirebaseFirestore.instance
            .collection('feedback')
            .doc(widget.feedbackId)
            .get();
      });
    } catch (e) {
      _showCustomSnackBar('Error sending reply: $e', Colors.red,
          duration: const Duration(seconds: 2));
    }
  }

  Future<void> _deleteFeedback() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
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

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('feedback')
            .doc(widget.feedbackId)
            .delete();
        _showCustomSnackBar('Feedback deleted', Colors.green,
            duration: const Duration(seconds: 3));
        Navigator.pop(context);
      } catch (e) {
        _showCustomSnackBar('Error deleting feedback: $e', Colors.red,
            duration: const Duration(seconds: 2));
      }
    }
  }

  Future<void> _markAsRead() async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(widget.feedbackId)
          .update({
        'read': true,
        'status': 'Read',
      });
      _showCustomSnackBar('Feedback marked as read', Colors.black87,
          duration: const Duration(seconds: 2));
      setState(() {
        _isMoreMenuVisible = false;
        _feedbackFuture = FirebaseFirestore.instance
            .collection('feedback')
            .doc(widget.feedbackId)
            .get();
      });
    } catch (e) {
      _showCustomSnackBar('Error marking as read: $e', Colors.red,
          duration: const Duration(seconds: 2));
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF93C5FD),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (!_replyFocusNode.hasFocus) {
                setState(() {
                  _isDropdownVisible = false;
                  _isMenuVisible = false;
                  _isMoreMenuVisible = false;
                });
                _replyFocusNode.unfocus();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                // Glassy top bar
                Positioned(
                  top: MediaQuery.of(context).padding.top,
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
                                      _isMoreMenuVisible = false;
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: screenWidth * 0.00,
                                        ),
                                        child: Container(
                                          width: screenWidth * 0.1,
                                          height: screenWidth * 0.1,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
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
                                                    width: screenWidth * 0.1,
                                                    height: screenWidth * 0.1,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return const CircularProgressIndicator();
                                                    },
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        Icon(
                                                      Icons.person,
                                                      color: Colors.black,
                                                      size: screenWidth * 0.04,
                                                    ),
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
                                        padding: EdgeInsets.only(
                                          right: screenWidth * 0.01,
                                        ),
                                        child: GestureDetector(
                                          onTap: _navigateToEditProfile,
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
                // Dropdown container
                if (_isDropdownVisible)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + screenHeight * 0.09,
                    right: screenWidth * 0.04,
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
                                  Image.asset(
                                    'assets/images/edit.png',
                                    color: Colors.black,
                                    width: screenWidth * 0.04,
                                    height: screenWidth * 0.04,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Feedback Details, Status, chevrons, and more button
                Positioned(
                  top: MediaQuery.of(context).padding.top + screenHeight * 0.1,
                  left: screenWidth * 0.04,
                  right: screenWidth * 0.04,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feedback Details',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              FutureBuilder<DocumentSnapshot>(
                                future: _feedbackFuture,
                                builder: (context, snapshot) {
                                  // Handle null _feedbackFuture
                                  if (_feedbackFuture == null) {
                                    return Container(
                                      width: screenWidth * 0.2125,
                                      height: screenHeight * 0.03,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFCCD36),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      width: screenWidth * 0.2125,
                                      height: screenHeight * 0.03,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFCCD36),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Container(
                                      width: screenWidth * 0.2125,
                                      height: screenHeight * 0.03,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Error',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.038,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  if (!snapshot.hasData || !snapshot.data!.exists) {
                                    return Container(
                                      width: screenWidth * 0.2125,
                                      height: screenHeight * 0.03,
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Not Found',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.038,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final data = snapshot.data!.data() as Map<String, dynamic>;
                                  final status = data['status'] as String? ?? 'In Review';

                                  return Container(
                                    width: screenWidth * 0.2125,
                                    height: screenHeight * 0.03,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCCD36),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Center(
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: status == 'Read'
                                              ? const Color(0xFF00FF00)
                                              : Colors.black,
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                  );
                                },
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
                      SizedBox(height: screenHeight * 0.01),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isMoreMenuVisible = !_isMoreMenuVisible;
                              _isDropdownVisible = false;
                              _isMenuVisible = false;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.black,
                            size: screenWidth * 0.08,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // White container
                Positioned(
                  top: MediaQuery.of(context).padding.top + screenHeight * 0.22,
                  left: screenWidth * 0.04,
                  child: Container(
                    width: screenWidth * 0.92,
                    height: screenHeight * 0.78,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
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
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + screenHeight * 0.1,
                      ),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: _feedbackFuture,
                        builder: (context, snapshot) {
                          // Handle null _feedbackFuture
                          if (_feedbackFuture == null) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Center(child: Text('Feedback not found'));
                          }

                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          final feedbackId = widget.feedbackId;
                          final userEmail = data['userEmail'] as String? ?? 'Unknown';
                          final userName = data['userName'] as String? ?? 'Unknown';
                          final timestamp = data['timestamp'] as Timestamp?;
                          final feedbackText = data['feedbackText'] as String? ?? 'No description';
                          final formattedDate = timestamp != null
                              ? '${timestamp.toDate().toLocal().toString().split('.')[0]}'
                              : 'N/A';
                          final adminReply = data['adminReply'] as String? ?? '';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: screenHeight * 0.015),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.25,
                                      child: Text(
                                        'Feedback ID:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Container(
                                      width: screenWidth * 0.5575,
                                      height: screenHeight * 0.05,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFD59A00), width: 1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          feedbackId,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.035,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.25,
                                      child: Text(
                                        'Submitted By:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Container(
                                      width: screenWidth * 0.5575,
                                      height: screenHeight * 0.05,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFD59A00), width: 1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          userName,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.035,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.25,
                                      child: Text(
                                        'Email:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Container(
                                      width: screenWidth * 0.5575,
                                      height: screenHeight * 0.05,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFD59A00), width: 1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          userEmail,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.035,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.25,
                                      child: Text(
                                        'Date & Time:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Container(
                                      width: screenWidth * 0.5575,
                                      height: screenHeight * 0.05,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFD59A00), width: 1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          formattedDate,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.035,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.25,
                                      child: Text(
                                        'Description:',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Container(
                                      width: screenWidth * 0.5575,
                                      height: screenHeight * 0.15875,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFD59A00), width: 1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: SingleChildScrollView(
                                        padding: EdgeInsets.all(screenWidth * 0.02),
                                        child: Text(
                                          feedbackText,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.035,
                                            fontFamily: 'Poppins',
                                          ),
                                          maxLines: null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Divider(
                                color: Colors.grey,
                                thickness: 1,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                child: Text(
                                  'Admin Section',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              StatefulBuilder(
                                builder: (context, setTextFieldState) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: screenWidth * 0.25,
                                          child: Text(
                                            'Reply:',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: screenWidth * 0.035,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.01),
                                        GestureDetector(
                                          onTap: () {
                                            _replyFocusNode.requestFocus();
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            width: screenWidth * 0.5575,
                                            height: screenHeight * 0.15875,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: const Color(0xFFD59A00), width: 1),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: SingleChildScrollView(
                                              padding: EdgeInsets.all(screenWidth * 0.02),
                                              child: TextField(
                                                controller: _replyController,
                                                focusNode: _replyFocusNode,
                                                maxLines: null,
                                                minLines: 5,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: screenWidth * 0.035,
                                                  fontFamily: 'Poppins',
                                                ),
                                                decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: adminReply.isEmpty ? 'Enter reply here...' : '',
                                                  hintStyle: const TextStyle(color: Colors.grey),
                                                  contentPadding: EdgeInsets.symmetric(
                                                    horizontal: screenWidth * 0.02,
                                                    vertical: screenHeight * 0.01,
                                                  ),
                                                ),
                                                textAlign: TextAlign.start,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _sendReply,
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: screenWidth * 0.3625,
                                      height: screenHeight * 0.05625,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 26, 47, 241),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Send',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (adminReply.isNotEmpty) ...[
                                SizedBox(height: screenHeight * 0.015),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: screenWidth * 0.25,
                                        child: Text(
                                          'Admin Reply:',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.035,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      Container(
                                        width: screenWidth * 0.5575,
                                        height: screenHeight * 0.15875,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: const Color(0xFFD59A00), width: 1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: SingleChildScrollView(
                                          padding: EdgeInsets.all(screenWidth * 0.02),
                                          child: Text(
                                            adminReply,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: screenWidth * 0.035,
                                              fontFamily: 'Poppins',
                                            ),
                                            maxLines: null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              SizedBox(height: screenHeight * 0.015),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Sidebar menu
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
                                          errorBuilder: (context, error, stackTrace) => Icon(
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
                                MaterialPageRoute(builder: (context) => EditProfileScreen()),
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
                if (_isMoreMenuVisible)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + screenHeight * 0.18,
                    right: screenWidth * 0.06,
                    child: Container(
                      width: screenWidth * 0.3527,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _deleteFeedback,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenHeight * 0.005,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            color: Colors.grey,
                            thickness: 1,
                            height: screenHeight * 0.005,
                          ),
                          GestureDetector(
                            onTap: _markAsRead,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenHeight * 0.005,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Mark as read',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
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
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String text, String? route) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.only(
          left: screenWidth * 0.03, top: screenHeight * 0.02),
      child: GestureDetector(
        onTap: route != null
            ? () {
                Navigator.pushNamed(context, route);
                setState(() {
                  _isMenuVisible = false;
                });
              }
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