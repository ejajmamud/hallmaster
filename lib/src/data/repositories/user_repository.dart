import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallmaster_enterprise/src/core/firestore_service.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';

class UserRepository {
  UserRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<AppUser?> getUserById(String id) async {
    try {
      final doc = await _firestoreService.users
          .doc(id)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      if (!doc.exists) return null;
      return _mapDataToUser(doc.id, doc.data() ?? {});
    } catch (_) {
      final data = FirestoreService.fallbackUsers[id];
      return data == null ? null : _mapDataToUser(id, data);
    }
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final normalizedEmail = SecurityService.normalizeEmail(email);
    try {
      final result = await _firestoreService.users
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      if (result.docs.isEmpty) return null;
      return _mapDocToUser(result.docs.first);
    } catch (_) {
      for (final entry in FirestoreService.fallbackUsers.entries) {
        if (entry.value['email'] == normalizedEmail) {
          return _mapDataToUser(entry.key, entry.value);
        }
      }
      return null;
    }
  }

  Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }

  Future<void> createUser({
    required String id,
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    final now = DateTime.now().toIso8601String();
    final passwordHash = SecurityService.hashPassword(password);
    final normalizedEmail = SecurityService.normalizeEmail(email);
    final normalizedName = SecurityService.normalizeName(name);

    final data = {
      'name': normalizedName,
      'email': normalizedEmail,
      'passwordHash': passwordHash,
      'phone': phone ?? '',
      'role': role.name,
      'createdAt': now,
      'updatedAt': now,
    };

    try {
      await _firestoreService.users
          .doc(id)
          .set(data)
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackUsers[id] = data;
    }
  }

  Future<AppUser?> authenticate(String email, String password) async {
    final normalizedEmail = SecurityService.normalizeEmail(email);
    try {
      final result = await _firestoreService.users
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      if (result.docs.isEmpty) return null;

      final doc = result.docs.first;
      final passwordHash = doc.data()['passwordHash'] as String? ?? '';
      if (SecurityService.verifyPassword(password, passwordHash)) {
        return _mapDocToUser(doc);
      }
      return null;
    } catch (_) {
      for (final entry in FirestoreService.fallbackUsers.entries) {
        if (entry.value['email'] != normalizedEmail) continue;
        final passwordHash = entry.value['passwordHash'] as String? ?? '';
        if (SecurityService.verifyPassword(password, passwordHash)) {
          return _mapDataToUser(entry.key, entry.value);
        }
      }
    }
    return null;
  }

  Future<List<AppUser>> getAllUsers() async {
    try {
      final result = await _firestoreService.users
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      final users = result.docs.map(_mapDocToUser).toList();
      users.sort((a, b) => a.name.compareTo(b.name));
      return users.isEmpty ? _fallbackUsers() : users;
    } catch (_) {
      return _fallbackUsers();
    }
  }

  Future<void> updateUser(String id, {String? name, String? phone}) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': SecurityService.normalizeName(name),
      if (phone != null) 'phone': phone,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    try {
      await _firestoreService.users
          .doc(id)
          .update(updates)
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      final data = FirestoreService.fallbackUsers[id];
      if (data == null) return;
      data.addAll(updates);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _firestoreService.users
          .doc(id)
          .delete()
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackUsers.remove(id);
    }
  }

  List<AppUser> _fallbackUsers() {
    final users = FirestoreService.fallbackUsers.entries
        .map((entry) => _mapDataToUser(entry.key, entry.value))
        .toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  AppUser _mapDocToUser(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _mapDataToUser(doc.id, doc.data());
  }

  AppUser _mapDataToUser(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.user,
      ),
      phone: data['phone'] as String?,
    );
  }
}
