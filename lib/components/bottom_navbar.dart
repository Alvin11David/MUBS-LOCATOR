import 'package:flutter/material.dart';
import 'dart:ui';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;
  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigation logic for each item
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/HomeScreen');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/LocationSelectScreen');
        break;
      case 2:
        // Feedback item: No navigation defined yet
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/ProfileScreen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = MediaQuery.of(context).size.height;
        double padding = screenWidth * 0.059; // Horizontal padding value
        double effectiveItemWidth = (screenWidth - 2.6 * padding) / 4; // Adjusted width per item after padding

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: screenHeight * 0.1,
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    left: padding + _selectedIndex * effectiveItemWidth,
                    top: screenHeight * 0.010,
                    width: effectiveItemWidth,
                    height: screenHeight * 0.075,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            icon: Icons.home,
                            label: 'Home',
                            index: 0,
                            screenWidth: screenWidth,
                            isSelected: _selectedIndex == 0,
                          ),
                          _buildNavItem(
                            icon: Icons.search,
                            label: 'Search',
                            index: 1,
                            screenWidth: screenWidth,
                            isSelected: _selectedIndex == 1,
                          ),
                          _buildNavItem(
                            icon: Icons.feedback_rounded,
                            label: 'Feedback',
                            index: 2,
                            screenWidth: screenWidth,
                            isSelected: _selectedIndex == 2,
                          ),
                          _buildNavItem(
                            icon: Icons.person,
                            label: 'Profile',
                            index: 3,
                            screenWidth: screenWidth,
                            isSelected: _selectedIndex == 3,
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
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required double screenWidth,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index), // Call navigation handler
      child: Opacity(
        opacity: isSelected ? 1.0 : 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.black,
              size: isSelected ? screenWidth * 0.07 : screenWidth * 0.06,
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: isSelected ? screenWidth * 0.04 : screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }
}