import 'package:hallmaster_enterprise/src/core/database.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';

class ServiceRepository {
  final DatabaseService _databaseService;

  ServiceRepository(this._databaseService);

  Future<AddOnService?> getServiceById(String id) async {
    final db = await _databaseService.database;
    final result = await db.query('add_on_services', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return _mapRowToService(result.first);
  }

  Future<List<AddOnService>> getAllServices() async {
    final db = await _databaseService.database;
    final result = await db.query('add_on_services');
    return result.map(_mapRowToService).toList();
  }

  Future<void> createService({
    required String id,
    required String name,
    required double unitPrice,
  }) async {
    final db = await _databaseService.database;
    await db.insert('add_on_services', {
      'id': id,
      'name': name,
      'unit_price': unitPrice,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateService(String id, {String? name, double? unitPrice}) async {
    final db = await _databaseService.database;
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (unitPrice != null) 'unit_price': unitPrice,
    };

    if (updates.isNotEmpty) {
      await db.update('add_on_services', updates, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteService(String id) async {
    final db = await _databaseService.database;
    await db.delete('add_on_services', where: 'id = ?', whereArgs: [id]);
  }

  AddOnService _mapRowToService(Map<String, dynamic> row) {
    return AddOnService(
      id: row['id'] as String,
      name: row['name'] as String,
      unitPrice: row['unit_price'] as double,
    );
  }
}
