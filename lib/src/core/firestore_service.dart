import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;
  static const fallbackTimeout = Duration(seconds: 5);

  static final List<Hall> fallbackHalls = [
    const Hall(
      id: 'h1',
      name: 'Prime Ballroom',
      location: 'Kuala Lumpur',
      capacity: 350,
      basePrice: 1200,
      amenities: ['Stage', 'Wi-Fi', 'Parking'],
    ),
    const Hall(
      id: 'h2',
      name: 'Orchid Conference Hall',
      location: 'Cyberjaya',
      capacity: 120,
      basePrice: 680,
      amenities: ['Projector', 'Coffee Bar'],
    ),
    const Hall(
      id: 'h3',
      name: 'Zenith Boardroom',
      location: 'Putrajaya',
      capacity: 40,
      basePrice: 320,
      amenities: ['Smart Display', 'Soundproof'],
    ),
  ];

  static final List<AddOnService> fallbackServices = [
    const AddOnService(id: 's1', name: 'AV Equipment', unitPrice: 180),
    const AddOnService(id: 's2', name: 'Catering Package', unitPrice: 350),
    const AddOnService(id: 's3', name: 'Decor Setup', unitPrice: 220),
  ];

  static final Map<String, Map<String, dynamic>> fallbackUsers = {
    'a1': {
      'name': 'Admin User',
      'email': 'admin@hallmaster.app',
      'passwordHash': SecurityService.hashPassword('Admin@123'),
      'phone': '',
      'role': UserRole.admin.name,
    },
    'u1': {
      'name': 'Standard User',
      'email': 'user@hallmaster.app',
      'passwordHash': SecurityService.hashPassword('User@123'),
      'phone': '',
      'role': UserRole.user.name,
    },
  };

  static final Map<String, Map<String, dynamic>> fallbackBookings = {};

  CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get halls =>
      firestore.collection('halls');

  CollectionReference<Map<String, dynamic>> get services =>
      firestore.collection('add_on_services');

  CollectionReference<Map<String, dynamic>> get bookings =>
      firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get auditLogs =>
      firestore.collection('audit_logs');

  CollectionReference<Map<String, dynamic>> get metadata =>
      firestore.collection('metadata');

  Future<void> ensureSeeded() async {
    final seedDoc = metadata.doc('bootstrap');
    final seedSnapshot = await seedDoc.get();
    if (seedSnapshot.exists) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    final batch = firestore.batch();

    batch.set(halls.doc('h1'), {
      'name': 'Prime Ballroom',
      'location': 'Kuala Lumpur',
      'capacity': 350,
      'basePrice': 1200.0,
      'amenities': ['Stage', 'Wi-Fi', 'Parking'],
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(halls.doc('h2'), {
      'name': 'Orchid Conference Hall',
      'location': 'Cyberjaya',
      'capacity': 120,
      'basePrice': 680.0,
      'amenities': ['Projector', 'Coffee Bar'],
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(halls.doc('h3'), {
      'name': 'Zenith Boardroom',
      'location': 'Putrajaya',
      'capacity': 40,
      'basePrice': 320.0,
      'amenities': ['Smart Display', 'Soundproof'],
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(services.doc('s1'), {
      'name': 'AV Equipment',
      'unitPrice': 180.0,
      'createdAt': now,
    });

    batch.set(services.doc('s2'), {
      'name': 'Catering Package',
      'unitPrice': 350.0,
      'createdAt': now,
    });

    batch.set(services.doc('s3'), {
      'name': 'Decor Setup',
      'unitPrice': 220.0,
      'createdAt': now,
    });

    batch.set(users.doc('a1'), {
      'name': 'Admin User',
      'email': 'admin@hallmaster.app',
      'passwordHash': SecurityService.hashPassword('Admin@123'),
      'phone': '',
      'role': UserRole.admin.name,
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(users.doc('u1'), {
      'name': 'Standard User',
      'email': 'user@hallmaster.app',
      'passwordHash': SecurityService.hashPassword('User@123'),
      'phone': '',
      'role': UserRole.user.name,
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(seedDoc, {'seededAt': now, 'version': 1});
    await batch.commit();
  }
}
