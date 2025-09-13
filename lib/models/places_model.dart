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
