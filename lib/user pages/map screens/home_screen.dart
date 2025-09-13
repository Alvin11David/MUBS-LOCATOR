import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng _mubsMaingate = LatLng(0.32626314488423924, 32.616607995731286);
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Good morning, User'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notification_important_rounded),
          ),
        ],
      ),
      drawer: Drawer(),

      body: Stack(
        children: [
          GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _mubsMaingate,
            zoom: 13,
          ),
          markers: {
            Marker(
              markerId: MarkerId('mubs_maingate'),
              position: _mubsMaingate,
              infoWindow: InfoWindow(
                title: 'MUBS Maingate',
                snippet: 'Makerere University Business School',
              ),
            ),
          },
            ),

            Positioned(
            top: MediaQuery.of(context).padding.top + 16, // Account for status bar
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search buildings, departments, etc.',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  // Add your search logic here
                },
                onSubmitted: (value) {
                  // Handle search submission
                  
                },
              ),
            ),
          )
        ]
      )
  );
  }
}
