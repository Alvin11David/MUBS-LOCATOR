import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mubs_locator/models/building_model.dart';

class BuildingRepository {
  // This class will handle data operations related to buildings
  // For example, fetching building data from a Firebase collection

  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'buildings',
  );

  // Create
  Future<void> addBuilding(Building building) async {
    await _collection.add(building.toFirestore());
  }

  // Read all
  Future<List<Building>> getAllBuildings() async {
    final snapshot = await _collection.get();
    print(
      "Number of buildings fetched: ${snapshot.size}😁😁😁😁😁😁😁😁😁😁😁😁😁😁😁",
    );

    final List<Building> buildings = [];

    for (final doc in snapshot.docs) {
      final raw = doc.data();
      if (raw == null) {
        print('Skipping doc ${doc.id}: data is null');
        continue;
      }

      final Map<String, dynamic> data = Map<String, dynamic>.from(raw as Map);

      // Normalize Firestore GeoPoint to a map with latitude/longitude
      final loc = data['location'];
      if (loc == null) {
        print('Skipping doc ${doc.id}: missing location field');
        continue;
      }
      if (loc is GeoPoint) {
        data['location'] = {
          'latitude': loc.latitude,
          'longitude': loc.longitude,
        };
      } else if (loc is Map) {
        // Ensure keys exist
        if (loc['latitude'] == null || loc['longitude'] == null) {
          print('Skipping doc ${doc.id}: invalid location map');
          continue;
        }
      } else {
        print(
          'Skipping doc ${doc.id}: unsupported location type ${loc.runtimeType}',
        );
        continue;
      }

      try {
        buildings.add(Building.fromFirestore(data, doc.id));
      } catch (e, st) {
        print('Failed to parse building ${doc.id}: $e\n$st');
        // skip malformed doc
      }
    }

    return buildings;
  }

  Future<Map<String, dynamic>> getAllBuildingsWithCount() async {
    final snapshot = await _collection.get();
    final buildings = await getAllBuildings(); // reuse normalization logic
    final count = snapshot.size;
    print("Number of buildings fetched: $count");
    return {'count': count, 'buildings': buildings};
  }

  // READ (by ID)
  Future<Building?> getBuildingById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;

    final raw = doc.data();
    if (raw == null) return null;

    final Map<String, dynamic> data = Map<String, dynamic>.from(raw as Map);

    final loc = data['location'];
    if (loc is GeoPoint) {
      data['location'] = {'latitude': loc.latitude, 'longitude': loc.longitude};
    }

    try {
      return Building.fromFirestore(data, doc.id);
    } catch (e) {
      print('Failed to parse building ${doc.id}: $e');
      return null;
    }
  }

  // Update
  Future<void> updateBuilding(String id, Building updated) async {
    await _collection.doc(id).update(updated.toFirestore());
  }

  // Delete
  Future<void> deleteBuilding(String id) async {
    await _collection.doc(id).delete();
  }
}
