import 'package:google_maps_flutter/google_maps_flutter.dart';

// To be deleted.. and is just for dummy data
class Place {
  final int id;
  final String name;
  final String department;
  final String description;
  final double latitude;
  final double longitude;

  Place({
    required this.id,
    required this.name,
    required this.department,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> map) {
    return Place(
      id: map['id'],
      name: map['name'],
      department: map['department'],
      description: map['description'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}

// Final Model for the Buildings
class Building {
  final String id;
  final String name;
  final String description;
  final String? coverImage;
  final List<String>? otherImages;
  final LatLng location;

  Building({
    required this.id,
    required this.name,
    required this.description,
    this.coverImage,
    this.otherImages,
    required this.location,
  });

  factory Building.fromFirestore(Map<String, dynamic> json, String docId) {
    return Building(
      id: docId,
      name: json['name'],
      description: json['description'],
      coverImage: json['coverImage'],
      otherImages: List<String>.from(json['otherImages'] ?? []),
      location: LatLng(
        json['location']['latitude'],
        json['location']['longitude'],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'otherImages': otherImages,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
    };
  }
}

final List<Building> mubsBuildings = [
  Building(id: "", name: "Administartion Office block", description: "dummy description", location: LatLng(0.32901956889177686, 32.61612989315701)),
  Building(id: "", name: "Mubs Main Building", description: "dummy description", location: LatLng(0.32689514423557686, 32.61657359573117)),
  Building(id: "", name: "Entrepreneurship Center", description: "dummy description", location: LatLng(0.32874047379750837, 32.61796834434454)),
  Building(id: "", name: "MUBS Resource Centre", description: "dummy description", location: LatLng(0.3277245860439169, 32.6175108582803)),
  Building(id: "", name: "MUBS Playground", description: "dummy description", location: LatLng(0.32708234423157934, 32.61862206689591)),
  Building(id: "", name: "Guild Office Block", description: "dummy description", location: LatLng(0.32836936277880574, 32.618437788834996)),
  Building(id:"", name: "MUBS Mosque", description: "dummy description", location: LatLng(0.3284409588418777, 32.61886143806034)),
  Building(id: "", name: "MUBS Digital Library", description: "dummy description", location: LatLng(0.3277212015391435, 32.616415297579685)),
  Building(id: "", name: "Block 7", description: "dummy description", location: LatLng(0.32739934172355317, 32.6160612460086)),
  Building(id: "", name: "Students Car Park", description: "dummy description", location: LatLng(0.3271096622585165, 32.61758467809421)),
  Building(id: "", name: "Amule Building", description: "dummy description", location: LatLng(0.32744089407066024, 32.61748008963137)),
  Building(id: "", name: "Block 5", description: "dummy description", location: LatLng(0.32791222503349843, 32.616269632584434)),
  Building(id: "", name: "WTO Block", description: "dummy description", location: LatLng(0.3280257074815346, 32.616274112227984)),
  Building(id: "", name: "Block G", description: "dummy description", location: LatLng(0.32813321716797, 32.6165772347752)),
  Building(id: "", name: "Health Service Centre", description: "dummy description", location: LatLng(0.32848299678238435, 32.61717974633408)),
  Building(id:"", name: "Dinning Hall", description: "dummy description", location: LatLng(0.3279592227828312, 32.61742510831791)),
  Building(id: "", name: "MUBS Police Post", description: "dummy description", location: LatLng(0.3290905874843335, 32.61832815340216)),
  Building(id: "", name: "Faculty of Marketting and Hospitality Management", description: "dummy description", location: LatLng(0.32943390456252664, 32.61800628833753)),
  Building(id: "", name: "Entrepreneurs Incubation Centre", description: "dummy description", location: LatLng(0.3291764111098889, 32.618220802493695)),
  Building(id: "", name: "Restaurants", description: "dummy description", location: LatLng(0.33031061182523513, 32.61651694656332)),
  Building(id: "", name: "St.Padre Pio Chapel of St.Charles Lwanga", description: "dummy description", location: LatLng(0.3301956520866588, 32.61670489813434)),
  Building(id: "", name: "St. James Chapel", description: "dummy description", location: LatLng(0.33051751181207406, 32.61698384785701)),
  Building(id: "", name: "Small Gate", description: "dummy description", location: LatLng(0.32996010761886335, 32.61655158920769)),
  Building(id: "", name: "Block 1", description: "dummy description", location: LatLng(0.3291795977079296, 32.61685199663113)),
  Building(id: "", name: "Micro Finance Centre", description: "dummy description", location: LatLng(0.3284332405207378, 32.61685764333607)),
  Building(id: "", name: "Deans Office", description: "dummy description", location: LatLng(0.3280372046852618, 32.61693892068294)),
  Building(id: "", name: "Block 3", description: "dummy description", location: LatLng(0.32749668295418577, 32.616635360802235)),
  Building(id: "", name: "Block 7", description: "dummy description", location: LatLng(0.3271541628077707, 32.61607938028798)),
  Building(id: "", name: "Block 8", description: "dummy description", location: LatLng(0.32719239680900036, 32.6157826703277)),
  Building(id: "", name: "Bursars Office", description: "dummy description", location: LatLng(0.32690808729394155, 32.616077713364994)),
  Building(id: "", name: "SICA MUBS", description: "dummy description", location: LatLng(0.32781197696080444, 32.61701380426127)),
  Building(id: "", name: "Block 10", description: "dummy description", location: LatLng(0.32792999223164837, 32.61575853048062)),
  Building(id: "", name: "Block 4", description: "dummy description", location: LatLng(0.32777442666018386, 32.616646341626506)),
  Building(id: "", name: "Berlin Girl's Hall", description: "dummy description", location: LatLng(0.3290538193456057, 32.61737858466613))
];




