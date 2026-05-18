import 'package:hallmaster_enterprise/src/core/database.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';

class UserRepository {
  final DatabaseService _databaseService;

  UserRepository(this._databaseService);

  Future<AppUser?> getUserById(String id) async {
    final db = await _databaseService.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return _mapRowToUser(result.first);
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await _databaseService.database;
    final normalizedEmail = SecurityService.normalizeEmail(email);
    final result = await db.query('users', where: 'email = ?', whereArgs: [normalizedEmail]);
    if (result.isEmpty) return null;
    return _mapRowToUser(result.first);
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
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();
    final passwordHash = SecurityService.hashPassword(password);
    final normalizedEmail = SecurityService.normalizeEmail(email);
    final normalizedName = SecurityService.normalizeName(name);

    await db.insert('users', {
      'id': id,
      'name': normalizedName,
      'email': normalizedEmail,
      'password_hash': passwordHash,
      'phone': phone ?? '',
      'role': role.name,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<AppUser?> authenticate(String email, String password) async {
    final normalizedEmail = SecurityService.normalizeEmail(email);
    final user = await getUserByEmail(normalizedEmail);
    if (user == null) return null;

    final db = await _databaseService.database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [normalizedEmail]);
    if (result.isEmpty) return null;

    final passwordHash = result.first['password_hash'] as String;
    if (SecurityService.verifyPassword(password, passwordHash)) {
      return user;
    }
    return null;
  }

  Future<List<AppUser>> getAllUsers() async {
    final db = await _databaseService.database;
    final result = await db.query('users');
    return result.map(_mapRowToUser).toList();
  }

  Future<void> updateUser(String id, {String? name, String? phone}) async {
    final db = await _databaseService.database;
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await db.update('users', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteUser(String id) async {
    final db = await _databaseService.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  AppUser _mapRowToUser(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      name: row['name'] as String,
      email: row['email'] as String,
      role: UserRole.values.firstWhere((e) => e.name == row['role'] as String),
      phone: row['phone'] as String?,
    );
  }
}
