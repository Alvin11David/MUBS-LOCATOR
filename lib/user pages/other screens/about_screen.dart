import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF93C5FD), // Set entire Scaffold background to #93C5FD
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Chevron left button
            Positioned(
              top: screenHeight * 0.05, // Adjusted to 5% for a standard top position
              left: screenWidth * 0.04,
              child: ClipOval(
                child: Container(
                  width: screenWidth * 0.12, // Reduced size to 12% of screen width
                  height: screenWidth * 0.12, // Reduced size to 12% of screen width
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1E8FF), // Light blue background
                    border: Border.all(
                      color: Colors.white, // White outline
                      width: screenWidth * 0.002,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: screenWidth * 0.06, // Reduced icon size to 6% of screen width
                    ),
                  ),
                ),
              ),
            ),
            // Centered "About The App" text, image, and new text below it
            Positioned(
              top: screenHeight * 0.05, // Align with top of chevron button
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // "About The App" text
                  Padding(
                    padding: EdgeInsets.only(top: screenWidth * 0.025), // Small padding for alignment
                    child: Text(
                      'About The App',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05, // Responsive font size (5% of screen width)
                        fontWeight: FontWeight.bold, // Bold font
                        color: Colors.black, // Black color
                      ),
                    ),
                  ),
                  // Image just below the text
                  SizedBox(height: screenHeight * 0.02), // Small gap below text
                  Image.asset(
                    'assets/images/Half_pic.jpg',
                    width: screenWidth * 0.8, // Image width is 80% of screen width for responsiveness
                    height: screenHeight * 0.4, // Image height is 40% of screen height for responsiveness
                    fit: BoxFit.contain, // Maintain aspect ratio without distortion
                  ),
                  // "Ambasize Jackline" text just below the image
                  SizedBox(height: screenHeight * 0.02), // Small gap below image
                  Text(
                    'Ambasize Jackline',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05, // Responsive font size
                      fontWeight: FontWeight.w600, // Slightly bolder than default
                      color: Colors.black, // Black color
                    ),
                  ),
                  // New text below "Ambasize Jackline" with constrained width
                  SizedBox(height: screenHeight * 0.02), // Small gap below text
                  Container(
                    width: screenWidth * 0.8, // Match image width for consistent margins
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: screenWidth * 0.04, // Smaller font size (80% of above)
                          color: Colors.black, // Default black color
                        ),
                        children: [
                          TextSpan(text: 'I am a '),
                          TextSpan(
                            text: 'year 2',
                            style: TextStyle(color: Colors.black87), // Darker color
                          ),
                          TextSpan(text: ' student pursuing a bachelors degree in '),
                          TextSpan(
                            text: 'Leadership and Governance.',
                            style: TextStyle(color: Colors.black87), // Darker color
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Card with quote below the previous text
                  SizedBox(height: screenHeight * 0.01), // Reduced gap for closer positioning
                  Container(
                    width: screenWidth * 0.8, // Match image width for consistent margins
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenHeight * 0.02), // Responsive margin
                    child: Card(
                      color: const Color(0xFFD1E8FF), // Light blue background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03), // Responsive rounded corners
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding inside card
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.format_quote,
                              size: screenWidth * 0.08, // Large quotation mark
                              color: Colors.black87, // Dark color
                            ),
                            SizedBox(height: screenHeight * 0.01), // Small gap
                            Text(
                              'Navigate MUBS with ease, your success is our guide.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04, // Medium font size
                                fontWeight: FontWeight.normal, // Not bold
                                color: Colors.grey[800], // Dark gray
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01), // Small gap
                            Text(
                              'Ambasize Jackline',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.045, // Slightly larger than quote
                                fontWeight: FontWeight.bold, // Bold
                                color: Colors.black87, // Dark color
                              ),
                            ),
                          ],
                        ),
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
}