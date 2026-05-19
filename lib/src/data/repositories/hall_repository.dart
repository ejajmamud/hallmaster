import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallmaster_enterprise/src/core/firestore_service.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';

class HallRepository {
  HallRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<Hall?> getHallById(String id) async {
    try {
      final doc = await _firestoreService.halls
          .doc(id)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      if (!doc.exists) return null;
      return _mapDataToHall(doc.id, doc.data() ?? {});
    } catch (_) {
      for (final hall in FirestoreService.fallbackHalls) {
        if (hall.id == id) return hall;
      }
      return null;
    }
  }

  Future<List<Hall>> getAllHalls() async {
    try {
      final result = await _firestoreService.halls
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      final halls = result.docs.map(_mapDocToHall).toList();
      halls.sort((a, b) => a.name.compareTo(b.name));
      return halls.isEmpty ? FirestoreService.fallbackHalls : halls;
    } catch (_) {
      return FirestoreService.fallbackHalls;
    }
  }

  Future<List<Hall>> searchHalls({
    String? query,
    int? minCapacity,
    double? maxPrice,
  }) async {
    final allHalls = await getAllHalls();
    final normalizedQuery = query?.toLowerCase().trim();

    return allHalls.where((hall) {
      final matchesQuery = normalizedQuery == null || normalizedQuery.isEmpty
          ? true
          : hall.name.toLowerCase().contains(normalizedQuery) ||
              hall.location.toLowerCase().contains(normalizedQuery);
      final matchesCapacity =
          minCapacity == null ? true : hall.capacity >= minCapacity;
      final matchesPrice = maxPrice == null ? true : hall.basePrice <= maxPrice;
      return matchesQuery && matchesCapacity && matchesPrice;
    }).toList();
  }

  Future<void> createHall({
    required String id,
    required String name,
    required String location,
    required int capacity,
    required double basePrice,
    required List<String> amenities,
  }) async {
    final now = DateTime.now().toIso8601String();
    final data = {
      'name': name,
      'location': location,
      'capacity': capacity,
      'basePrice': basePrice,
      'amenities': amenities,
      'createdAt': now,
      'updatedAt': now,
    };

    try {
      await _firestoreService.halls
          .doc(id)
          .set(data)
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackHalls.add(Hall(
        id: id,
        name: name,
        location: location,
        capacity: capacity,
        basePrice: basePrice,
        amenities: amenities,
      ));
    }
  }

  Future<void> updateHall(
    String id, {
    String? name,
    String? location,
    int? capacity,
    double? basePrice,
    List<String>? amenities,
  }) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (capacity != null) 'capacity': capacity,
      if (basePrice != null) 'basePrice': basePrice,
      if (amenities != null) 'amenities': amenities,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _firestoreService.halls
          .doc(id)
          .update(updates)
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      final index =
          FirestoreService.fallbackHalls.indexWhere((hall) => hall.id == id);
      if (index < 0) return;
      final hall = FirestoreService.fallbackHalls[index];
      FirestoreService.fallbackHalls[index] = Hall(
        id: hall.id,
        name: name ?? hall.name,
        location: location ?? hall.location,
        capacity: capacity ?? hall.capacity,
        basePrice: basePrice ?? hall.basePrice,
        amenities: amenities ?? hall.amenities,
      );
    }
  }

  Future<void> deleteHall(String id) async {
    try {
      await _firestoreService.halls
          .doc(id)
          .delete()
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackHalls.removeWhere((hall) => hall.id == id);
    }
  }

  Future<bool> hasActiveBookings(String hallId) async {
    try {
      final result = await _firestoreService.bookings
          .where('hallId', isEqualTo: hallId)
          .limit(20)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      return result.docs.any(
        (doc) => doc.data()['status'] != BookingStatus.cancelled.name,
      );
    } catch (_) {
      return FirestoreService.fallbackBookings.values.any(
        (booking) =>
            booking['hallId'] == hallId &&
            booking['status'] != BookingStatus.cancelled.name,
      );
    }
  }

  Hall _mapDocToHall(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _mapDataToHall(doc.id, doc.data());
  }

  Hall _mapDataToHall(String id, Map<String, dynamic> data) {
    return Hall(
      id: id,
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? 0,
      amenities:
          (data['amenities'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
    );
  }
}
