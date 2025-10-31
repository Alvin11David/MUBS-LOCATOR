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
    return snapshot.docs
        .map(
          (doc) => Building.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> getAllBuildingsWithCount() async {
    final snapshot = await _collection.get();
    final buildings = snapshot.docs
        .map(
          (doc) => Building.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
        )
        .toList();
    final count = snapshot.size;
    return {'count': count, 'buildings': buildings};
  }

  // READ (by ID)
  Future<Building?> getBuildingById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Building.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
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
