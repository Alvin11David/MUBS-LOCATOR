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
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Matching search bar blur
            child: Container(
              height: screenHeight * 0.1, // 10% of screen height
              width: screenWidth, // Full width
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Matching search bar background
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3), // Matching search bar border
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
                  // Sliding watery glass rectangle (adjusted to match glassy effect)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300), // Smooth animation
                    left: padding + _selectedIndex * effectiveItemWidth, // Align precisely with each item's position
                    top: screenHeight * 0.010, // Slightly lower for better vertical centering over icon + label
                    width: effectiveItemWidth, // Matches the exact space for each item
                    height: screenHeight * 0.075, // Covers icon and label
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // Matching overall glassy effect
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
                  // Icons and labels
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
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Opacity(
        opacity: isSelected ? 1.0 : 0.6, // Active item is fully opaque, others dimmed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.black,
              size: isSelected ? screenWidth * 0.07 : screenWidth * 0.06, // Larger icon when selected
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: isSelected ? screenWidth * 0.04 : screenWidth * 0.035, // Larger text when selected
              ),
            ),
          ],
        ),
      ),
    );
  }
}