import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallmaster_enterprise/src/core/firestore_service.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';

class ServiceRepository {
  ServiceRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<AddOnService?> getServiceById(String id) async {
    try {
      final doc = await _firestoreService.services
          .doc(id)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      if (!doc.exists) return null;
      return _mapDataToService(doc.id, doc.data() ?? {});
    } catch (_) {
      for (final service in FirestoreService.fallbackServices) {
        if (service.id == id) return service;
      }
      return null;
    }
  }

  Future<List<AddOnService>> getAllServices() async {
    try {
      final result = await _firestoreService.services
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      final services = result.docs.map(_mapDocToService).toList();
      services.sort((a, b) => a.name.compareTo(b.name));
      return services.isEmpty ? FirestoreService.fallbackServices : services;
    } catch (_) {
      return FirestoreService.fallbackServices;
    }
  }

  Future<void> createService({
    required String id,
    required String name,
    required double unitPrice,
  }) async {
    try {
      await _firestoreService.services.doc(id).set({
        'name': name,
        'unitPrice': unitPrice,
        'createdAt': DateTime.now().toIso8601String(),
      }).timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackServices.add(
        AddOnService(id: id, name: name, unitPrice: unitPrice),
      );
    }
  }

  Future<void> updateService(String id,
      {String? name, double? unitPrice}) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (unitPrice != null) 'unitPrice': unitPrice,
    };

    if (updates.isNotEmpty) {
      try {
        await _firestoreService.services
            .doc(id)
            .update(updates)
            .timeout(FirestoreService.fallbackTimeout);
      } catch (_) {
        final index = FirestoreService.fallbackServices
            .indexWhere((service) => service.id == id);
        if (index < 0) return;
        final service = FirestoreService.fallbackServices[index];
        FirestoreService.fallbackServices[index] = AddOnService(
          id: id,
          name: name ?? service.name,
          unitPrice: unitPrice ?? service.unitPrice,
        );
      }
    }
  }

  Future<void> deleteService(String id) async {
    try {
      await _firestoreService.services
          .doc(id)
          .delete()
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackServices
          .removeWhere((service) => service.id == id);
    }
  }

  AddOnService _mapDocToService(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return _mapDataToService(doc.id, doc.data());
  }

  AddOnService _mapDataToService(String id, Map<String, dynamic> data) {
    return AddOnService(
      id: id,
      name: data['name'] as String? ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}
