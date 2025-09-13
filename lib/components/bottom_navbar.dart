import 'dart:ui';
import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0; // Tracks the active icon (0: Home, 1: Search, 2: Feedback, 3: Profile)

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        double screenHeight = constraints.maxHeight;
        double padding = screenWidth * 0.059; // Horizontal padding value
        double effectiveItemWidth = (screenWidth - 2.6 * padding) / 4; // Adjusted width per item after padding

        return Positioned(
          bottom: screenHeight * 0.002, // Raised by 0.002 of screen height
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // Subtle blur for less shine
              child: Container(
                height: screenHeight * 0.1, // 10% of screen height
                width: screenWidth, // Full width
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 209, 209, 209).withOpacity(0.9),
                      Colors.white.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    width: 1,
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
                    // Sliding glassy rectangle
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300), // Smooth animation
                      left: padding + _selectedIndex * effectiveItemWidth, // Align precisely with each item's position
                      top: screenHeight * 0.015, // Slightly lower for better vertical centering over icon + label
                      width: effectiveItemWidth, // Matches the exact space for each item
                      height: screenHeight * 0.075, // Covers icon and label
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.7), // More transparent for glassy effect
                              Colors.white.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white, // White stroke
                            width: 1, // Stroke width
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 1,
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