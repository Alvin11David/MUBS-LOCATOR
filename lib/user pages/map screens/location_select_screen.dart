import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mubs_locator/components/bottom_navbar.dart';

class LocationSelectScreen extends StatefulWidget {
  const LocationSelectScreen({super.key});

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  bool hasSearchHistory = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Split the search text into keywords (simplified logic, refine as needed)
    List<String> keywords = _searchController.text.isNotEmpty
        ? _searchController.text.split(' ').where((word) => word.isNotEmpty).toList()
        : [];

    return Scaffold(
      extendBody: true, // Allows body to extend under the bottom navigation bar
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFF93C5FD),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.02,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.08,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.05,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: MediaQuery.of(context).size.width * 0.06,
                            ),
                            SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search buildings, departments etc',
                                  hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontSize: MediaQuery.of(context).size.width * 0.04,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.7),
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                ),
                                onChanged: (value) {
                                  setState(() {}); // Trigger rebuild when text changes
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05,
                  vertical: MediaQuery.of(context).size.height * 0.01,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.1,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 1.2,
                              color: Colors.black,
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.02,
                            left: MediaQuery.of(context).size.width * 0.03,
                            child: Row(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.13,
                                  height: MediaQuery.of(context).size.width * 0.13,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF3E5891),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                      size: MediaQuery.of(context).size.width * 0.08,
                                    ),
                                  ),
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                                Text(
                                  'Your Location',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: MediaQuery.of(context).size.width * 0.04,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.12,
                            left: MediaQuery.of(context).size.width * 0.03,
                            child: Row(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.13,
                                  height: MediaQuery.of(context).size.width * 0.13,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF3E5891),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: MediaQuery.of(context).size.width * 0.08,
                                    ),
                                  ),
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                                Text(
                                  'Choose on map',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: MediaQuery.of(context).size.width * 0.04,
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
              Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.05,
                  right: MediaQuery.of(context).size.width * 0.05,
                  top: MediaQuery.of(context).size.height * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Search History',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    Text(
                      'Clear all',
                      style: TextStyle(
                        color: Colors.black.withOpacity(hasSearchHistory ? 1.0 : 0.5),
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                      ),
                    ),
                  ],
                ),
              ),
              if (keywords.isNotEmpty) // Show keywords only if there are any
                Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.05,
                    right: MediaQuery.of(context).size.width * 0.05,
                    top: MediaQuery.of(context).size.height * 0.01,
                  ),
                  child: Wrap(
                    spacing: MediaQuery.of(context).size.width * 0.02, // Space between rectangles
                    runSpacing: MediaQuery.of(context).size.height * 0.01, // Space between rows
                    children: keywords.map((keyword) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.03,
                              vertical: MediaQuery.of(context).size.height * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              keyword,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                                fontSize: MediaQuery.of(context).size.width * 0.04,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width * 0.05,
          right: MediaQuery.of(context).size.width * 0.05,
          bottom: MediaQuery.of(context).size.height * 0.015, // Lifted slightly up
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // Reduced width to 90% of screen
          child: const BottomNavBar(),
        ),
      ),
    );
  }
}