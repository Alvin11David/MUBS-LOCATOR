import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'dart:ui';
import 'package:mubs_locator/user%20pages/other%20screens/edit_profile_screen.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({super.key});

  @override

  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen>
    with SingleTickerProviderStateMixin {
  String? _profilePicUrl;
  bool _isDropdownVisible = false;
  bool _isMenuVisible = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          _profilePicUrl = doc.data()?['profilePicUrl'] as String?;
        });
      } catch (e) {
        print('Error loading profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile picture: $e')),
        );
      }
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

  void _logout() async {
    try {
      print('Signing out user: ${FirebaseAuth.instance.currentUser?.uid}');
      await FirebaseAuth.instance.signOut();
      print('Sign out successful');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/SignInScreen');
      }
    } catch (e) {
      print('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.pushNamed(context, '/ProfileSettingsScreen');
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _profilePicUrl = result['imageUrl'] as String?;
        _isDropdownVisible = false;
      });
    }
  }

  void _navigateToScreen(String routeName, {Object? arguments}) {
    try {
      print('Navigating to: $routeName from ${ModalRoute.of(context)?.settings.name}');
      Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
      setState(() {
        _isMenuVisible = false;
      });
    } catch (e) {
      print('Navigation error to $routeName: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to navigate to $routeName: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    final fullName = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD),
      body: SafeArea(
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
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: screenWidth * 0.0,
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
                                                width: screenWidth * 0.09,
                                                height: screenWidth * 0.09,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return const CircularProgressIndicator();
                                                },
                                                errorBuilder:
                                                    (context, error, stackTrace) =>
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
                                      onTap: () {
                                        setState(() {
                                          _isDropdownVisible =
                                              !_isDropdownVisible;
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
                        'Locations',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Manage campus locations',
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
              top: screenHeight * 0.19,
              left: screenWidth * 0.04,
              child: LocationTable(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                navigateToScreen: _navigateToScreen,
              ),
            ),
            if (_isDropdownVisible)
              Positioned(
                top: screenHeight * 0.09,
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
                          child: GestureDetector(
                            onTap: _navigateToEditProfile,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Edit Profile',
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
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _isMenuVisible ? 0 : -screenWidth * 0.6,
              top: 0,
              child: Container(
                width: screenWidth * 0.6,
                height: screenHeight * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(2, 0),
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
                            width: screenWidth * 0.15,
                            height: screenWidth * 0.15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: (_profilePicUrl != null &&
                                    _profilePicUrl!.isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      _profilePicUrl!,
                                      fit: BoxFit.cover,
                                      width: screenWidth * 0.15,
                                      height: screenWidth * 0.15,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const CircularProgressIndicator();
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
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
                          _navigateToScreen('/AdminDashboardScreen');
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
                          _navigateToScreen('/FeedbackListScreen');
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
                        onTap: () {
                          _navigateToScreen('/ProfileSettingsScreen');
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
                          _navigateToScreen('/SendNotificationsScreen');
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
                          _navigateToScreen('/LocationManagementScreen');
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
            if (_isMenuVisible || _isDropdownVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (_isMenuVisible || _isDropdownVisible) {
                      setState(() {
                        _isMenuVisible = false;
                        _isDropdownVisible = false;
                      });
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LocationTable extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final Function(String, {Object? arguments}) navigateToScreen;

  const LocationTable({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.navigateToScreen,
  });

  @override
  State<LocationTable> createState() => _LocationTableState();
}

class _LocationTableState extends State<LocationTable> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.screenWidth * 0.92,
      height: widget.screenHeight * 0.78,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: widget.screenHeight * 0.02),
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: widget.screenWidth * 0.04,
                    ),
                    child: Container(
                      width: widget.screenWidth * 0.1,
                      height: widget.screenWidth * 0.1,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        color: Colors.black,
                        size: widget.screenWidth * 0.06,
                      ),
                    ),
                  ),
                  SizedBox(width: widget.screenWidth * 0.04),
                  Text(
                    '(Add, edit or remove\nbuildings and rooms)',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: widget.screenWidth * 0.035,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(
                      right: widget.screenWidth * 0.04,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        widget.navigateToScreen('/AddPlaceScreen');
                      },
                      child: Container(
                        width: widget.screenWidth * 0.3,
                        height: widget.screenWidth * 0.1,
                        decoration: BoxDecoration(
                          color: const Color(0xFF93C5FD),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: Colors.black,
                              size: widget.screenWidth * 0.06,
                            ),
                            SizedBox(width: widget.screenWidth * 0.02),
                            Text(
                              'Add Location',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: widget.screenWidth * 0.031,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: widget.screenHeight * 0.02),
              Divider(
                color: Colors.grey,
                thickness: 1,
                indent: widget.screenWidth * 0.04,
                endIndent: widget.screenWidth * 0.04,
              ),
              SizedBox(height: widget.screenHeight * 0.01),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: Container(
                  alignment: Alignment.center,
                  width: widget.screenWidth * 0.88,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('buildings')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No buildings found'),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                        },
                        border: const TableBorder(
                          verticalInside: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                          horizontalInside: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                          top: BorderSide.none,
                        ),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Color(0xFF93C5FD),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(
                                  widget.screenWidth * 0.02,
                                ),
                                child: Text(
                                  'Building\nName',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: widget.screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(
                                  widget.screenWidth * 0.02,
                                ),
                                child: Text(
                                  'Building\nPurpose',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: widget.screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(
                                  widget.screenWidth * 0.02,
                                ),
                                child: Text(
                                  'Action\nButtons',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: widget.screenWidth * 0.035,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          ...docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name'] as String? ?? 'Unnamed';
                            final description =
                                data['description'] as String? ?? 'No description';
                            return TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(
                                    widget.screenWidth * 0.02,
                                  ),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: widget.screenWidth * 0.035,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(
                                    widget.screenWidth * 0.02,
                                  ),
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: widget.screenWidth * 0.035,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(
                                    widget.screenWidth * 0.02,
                                  ),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          widget.navigateToScreen(
                                            '/EditPlaceScreen',
                                            arguments: {
                                              'buildingId': doc.id,
                                            },
                                          );
                                        },
                                        child: Container(
                                          width: widget.screenWidth * 0.22,
                                          height: widget.screenWidth * 0.08,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: widget.screenWidth * 0.04,
                                              ),
                                              SizedBox(
                                                width: widget.screenWidth * 0.015,
                                              ),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      widget.screenWidth * 0.03,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: widget.screenWidth * 0.02,
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Delete Location',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this location?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await FirebaseFirestore.instance
                                                .collection('buildings')
                                                .doc(doc.id)
                                                .delete();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content:
                                                    Text('Location deleted'),
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: widget.screenWidth * 0.22,
                                          height: widget.screenWidth * 0.08,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                color: Colors.black,
                                                size: widget.screenWidth * 0.04,
                                              ),
                                              SizedBox(
                                                width: widget.screenWidth * 0.015,
                                              ),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize:
                                                      widget.screenWidth * 0.03,
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
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: widget.screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
