import 'package:hallmaster_enterprise/src/core/database.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';

class HallRepository {
  final DatabaseService _databaseService;

  HallRepository(this._databaseService);

  Future<Hall?> getHallById(String id) async {
    final db = await _databaseService.database;
    final result = await db.query('halls', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return _mapRowToHall(result.first);
  }

  Future<List<Hall>> getAllHalls() async {
    final db = await _databaseService.database;
    final result = await db.query('halls');
    return result.map(_mapRowToHall).toList();
  }

  Future<List<Hall>> searchHalls({String? query, int? minCapacity, double? maxPrice}) async {
    final db = await _databaseService.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (query != null && query.isNotEmpty) {
      whereClause += " AND (name LIKE ? OR location LIKE ?)";
      final searchTerm = '%$query%';
      whereArgs.addAll([searchTerm, searchTerm]);
    }

    if (minCapacity != null) {
      whereClause += ' AND capacity >= ?';
      whereArgs.add(minCapacity);
    }

    if (maxPrice != null) {
      whereClause += ' AND base_price <= ?';
      whereArgs.add(maxPrice);
    }

    final result = await db.query('halls', where: whereClause, whereArgs: whereArgs);
    return result.map(_mapRowToHall).toList();
  }

  Future<void> createHall({
    required String id,
    required String name,
    required String location,
    required int capacity,
    required double basePrice,
    required List<String> amenities,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('halls', {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity,
      'base_price': basePrice,
      'amenities': amenities.join(','),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateHall(
    String id, {
    String? name,
    String? location,
    int? capacity,
    double? basePrice,
    List<String>? amenities,
  }) async {
    final db = await _databaseService.database;
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (capacity != null) 'capacity': capacity,
      if (basePrice != null) 'base_price': basePrice,
      if (amenities != null) 'amenities': amenities.join(','),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await db.update('halls', updates, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteHall(String id) async {
    final db = await _databaseService.database;
    await db.delete('halls', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasActiveBookings(String hallId) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'bookings',
      columns: ['id'],
      where: 'hall_id = ? AND status != ?',
      whereArgs: [hallId, BookingStatus.cancelled.name],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Hall _mapRowToHall(Map<String, dynamic> row) {
    final amenitiesStr = row['amenities'] as String? ?? '';
    return Hall(
      id: row['id'] as String,
      name: row['name'] as String,
      location: row['location'] as String,
      capacity: row['capacity'] as int,
      basePrice: row['base_price'] as double,
      amenities: amenitiesStr.isEmpty ? [] : amenitiesStr.split(','),
    );
  }
}
