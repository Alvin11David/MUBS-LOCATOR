import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'package:mubs_locator/admin%20pages/dashboards/feedback_details_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/edit_profile_screen.dart';
import 'dart:ui';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  String? _profilePicUrl;
  bool _isDropdownVisible = false;
  bool _isMenuVisible = false;
  bool _isFilterDropdownVisible = false;
  String? _selectedFilter;
  DateTime? _startDate;
  DateTime? _endDate;

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
      print('Error loading profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile image: $e')),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
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

  Query<Map<String, dynamic>> _applyFilter(Query<Map<String, dynamic>> query) {
    query = query.orderBy('timestamp', descending: true);

    if (_selectedFilter == 'Unread') {
      return query.where('read', whereIn: [false, null]);
    } else if (_selectedFilter == 'Last 7 Days') {
      final start = DateTime.now().subtract(const Duration(days: 7));
      return query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    } else if (_selectedFilter == 'Last 30 Days') {
      final start = DateTime.now().subtract(const Duration(days: 30));
      return query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    } else if (_selectedFilter == 'Last 90 Days') {
      final start = DateTime.now().subtract(const Duration(days: 90));
      return query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    } else if (_selectedFilter == 'Custom Range' && _startDate != null && _endDate != null) {
      return query
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endDate!));
    }
    return query;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF93C5FD),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'Custom Range';
        _isFilterDropdownVisible = false;
      });
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
        child: GestureDetector(
          onTap: () {
            if (_isMenuVisible || _isDropdownVisible || _isFilterDropdownVisible) {
              setState(() {
                _isMenuVisible = false;
                _isDropdownVisible = false;
                _isFilterDropdownVisible = false;
              });
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Header
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
                                  _isFilterDropdownVisible = false;
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
                                          _isFilterDropdownVisible = false;
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
              // Title and Navigation Arrows
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
                          'Feedback & Reports',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'View user feedback and reports',
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
              // Feedback Table
              Positioned(
                top: screenHeight * 0.22,
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                child: Container(
                  width: double.infinity,
                  height: screenHeight * 0.78,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      verticalDirection: VerticalDirection.down,
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: screenWidth * 0.04),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isFilterDropdownVisible = !_isFilterDropdownVisible;
                                    _isMenuVisible = false;
                                    _isDropdownVisible = false;
                                  });
                                },
                                child: Container(
                                  width: screenWidth * 0.1,
                                  height: screenWidth * 0.1,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: Colors.black, width: 1),
                                  ),
                                  child: Icon(
                                    Icons.tune,
                                    color: Colors.black,
                                    size: screenWidth * 0.06,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            Text(
                              _selectedFilter == null
                                  ? '(Filter and view user feedback)'
                                  : '($_selectedFilter)',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Divider(
                          color: Colors.grey,
                          thickness: 1,
                          indent: screenWidth * 0.04,
                          endIndent: screenWidth * 0.04,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          child: Container(
                            alignment: Alignment.center,
                            width: screenWidth * 0.88,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _applyFilter(FirebaseFirestore.instance.collection('feedback')).snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(child: Text('Error: ${snapshot.error}'));
                                }
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                  return const Center(child: Text('No feedback found'));
                                }

                                final docs = snapshot.data!.docs;

                                return Table(
                                  columnWidths: {
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(2),
                                    2: FlexColumnWidth(3),
                                    3: FlexColumnWidth(2),
                                  },
                                  border: const TableBorder(
                                    verticalInside: BorderSide(color: Colors.black, width: 1),
                                    horizontalInside: BorderSide(color: Colors.black, width: 1),
                                    top: BorderSide.none,
                                  ),
                                  children: [
                                    TableRow(
                                      decoration: const BoxDecoration(color: Color(0xFF93C5FD)),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(screenWidth * 0.02),
                                          child: Text(
                                            'Submitted by',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(screenWidth * 0.02),
                                          child: Text(
                                            'Submitted On',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(screenWidth * 0.02),
                                          child: Text(
                                            'Description',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poppins',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(screenWidth * 0.02),
                                          child: Text(
                                            'Action Button',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: screenWidth * 0.03,
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
                                      final userEmail = data['userEmail'] as String? ?? 'Unknown';
                                      final timestamp = data['timestamp'] as Timestamp?;
                                      final feedbackText = data['feedbackText'] as String? ?? 'No description';
                                      final formattedDate = timestamp != null
                                          ? '${timestamp.toDate().toLocal().toString().split(' ')[0]}'
                                          : 'N/A';

                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(screenWidth * 0.02),
                                            child: Text(
                                              userEmail,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: screenWidth * 0.026,
                                                fontFamily: 'Poppins',
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: null,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(screenWidth * 0.02),
                                            child: Text(
                                              formattedDate,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: screenWidth * 0.025,
                                                fontFamily: 'Poppins',
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(screenWidth * 0.02),
                                            child: Text(
                                              feedbackText,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: screenWidth * 0.03,
                                                fontFamily: 'Poppins',
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(screenWidth * 0.02),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => FeedbackDetailsScreen(
                                                          feedbackId: doc.id,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: screenWidth * 0.22,
                                                    height: screenWidth * 0.08,
                                                    decoration: BoxDecoration(
                                                      color: const Color.fromARGB(255, 248, 215, 28),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.reply,
                                                          color: Colors.black,
                                                          size: screenWidth * 0.04,
                                                        ),
                                                        SizedBox(width: screenWidth * 0.015),
                                                        Text(
                                                          'Reply',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: screenWidth * 0.025,
                                                            fontFamily: 'Poppins',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: screenWidth * 0.02),
                                                GestureDetector(
                                                  onTap: () async {
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
                                                            child: const Text(
                                                              'Delete',
                                                              style: TextStyle(color: Colors.red),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      await FirebaseFirestore.instance
                                                          .collection('feedback')
                                                          .doc(doc.id)
                                                          .delete();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Feedback deleted')),
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    width: screenWidth * 0.22,
                                                    height: screenWidth * 0.08,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.delete,
                                                          color: Colors.black,
                                                          size: screenWidth * 0.04,
                                                        ),
                                                        SizedBox(width: screenWidth * 0.015),
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: screenWidth * 0.025,
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
                                    }).toList(),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
              // Profile Dropdown
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
              // Filter Dropdown
              if (_isFilterDropdownVisible)
                Positioned(
                  top: screenHeight * 0.24,
                  left: screenWidth * 0.04,
                  child: Container(
                    width: screenWidth * 0.4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
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
                      children: [
                        _buildFilterItem(context, 'All Feedback', null),
                        _buildFilterItem(context, 'Unread', 'Unread'),
                        _buildFilterItem(context, 'Last 7 Days', 'Last 7 Days'),
                        _buildFilterItem(context, 'Last 30 Days', 'Last 30 Days'),
                        _buildFilterItem(context, 'Last 90 Days', 'Last 90 Days'),
                        _buildFilterItem(context, 'Custom Range', 'Custom Range'),
                      ],
                    ),
                  ),
                ),
              // Sidebar
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
                                border: Border.all(color: Colors.black, width: 1),
                              ),
                              child: _profilePicUrl != null && _profilePicUrl!.isNotEmpty
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
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            color: Colors.black,
                                            size: screenWidth * 0.08,
                                          );
                                        },
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
                        padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Dashboard row tapped');
                            Navigator.pushNamed(context, '/AdminDashboardScreen');
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
                        padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Feedback & Reports row tapped');
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
                        padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            print('Profile Settings row tapped');
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
                        padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Push Notifications row tapped');
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
                        padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Locations row tapped');
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
                        padding: EdgeInsets.only(left: screenWidth * 0.03, top: screenHeight * 0.02),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('Logout row tapped');
                            _logout();
                          },
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
      ),
    );
  }

  Widget _buildFilterItem(BuildContext context, String text, String? filter) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        if (filter == 'Custom Range') {
          _selectDateRange(context);
        } else {
          setState(() {
            _selectedFilter = filter;
            _isFilterDropdownVisible = false;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.02,
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.black,
                fontSize: screenWidth * 0.035,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}