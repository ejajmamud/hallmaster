import 'package:hallmaster_enterprise/src/core/database.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:sqflite/sqflite.dart';

class BookingRepository {
  final DatabaseService _databaseService;

  BookingRepository(this._databaseService);

  Future<Booking?> getBookingById(String id) async {
    final db = await _databaseService.database;
    final result = await db.query('bookings', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;

    final booking = result.first;
    final hall = await _getHallForBooking(db, booking['hall_id'] as String);
    final services = await _getServicesForBooking(db, id);

    return _mapRowToBooking(booking, hall, services);
  }

  Future<List<Booking>> getBookingsByUser(String userId) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'bookings',
      where: 'user_id = ? AND status != ?',
      whereArgs: [userId, BookingStatus.cancelled.name],
      orderBy: 'booking_date DESC',
    );

    List<Booking> bookings = [];
    for (final row in result) {
      final hall = await _getHallForBooking(db, row['hall_id'] as String);
      final services = await _getServicesForBooking(db, row['id'] as String);
      bookings.add(_mapRowToBooking(row, hall, services));
    }
    return bookings;
  }

  Future<List<Booking>> getAllBookings() async {
    final db = await _databaseService.database;
    final result = await db.query('bookings', orderBy: 'booking_date DESC');

    List<Booking> bookings = [];
    for (final row in result) {
      final hall = await _getHallForBooking(db, row['hall_id'] as String);
      final services = await _getServicesForBooking(db, row['id'] as String);
      bookings.add(_mapRowToBooking(row, hall, services));
    }
    return bookings;
  }

  /// Check if a hall is available for the given time slot
  Future<bool> isHallAvailable(String hallId, DateTime date, int startHour, int endHour) async {
    return isHallAvailableExcluding(
      hallId,
      date,
      startHour,
      endHour,
    );
  }

  Future<bool> isHallAvailableExcluding(
    String hallId,
    DateTime date,
    int startHour,
    int endHour, {
    String? excludeBookingId,
  }) async {
    final db = await _databaseService.database;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    var whereClause =
      'hall_id = ? AND booking_date = ? AND status IN (?, ?) AND NOT (end_hour <= ? OR start_hour >= ?)';
    final whereArgs = <dynamic>[
      hallId,
      dateStr,
      BookingStatus.pending.name,
      BookingStatus.confirmed.name,
      startHour,
      endHour,
    ];

    if (excludeBookingId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeBookingId);
    }

    // Check for conflicts: any booking on same day that overlaps time
    final result = await db.query(
      'bookings',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.isEmpty;
  }

  /// Get conflicting bookings for a given time slot
  Future<List<Booking>> getConflictingBookings(String hallId, DateTime date, int startHour, int endHour) async {
    final db = await _databaseService.database;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final result = await db.query(
      'bookings',
      where: 'hall_id = ? AND booking_date = ? AND status IN (?, ?) AND NOT (end_hour <= ? OR start_hour >= ?)',
      whereArgs: [
        hallId,
        dateStr,
        BookingStatus.pending.name,
        BookingStatus.confirmed.name,
        startHour,
        endHour,
      ],
    );

    List<Booking> bookings = [];
    for (final row in result) {
      final hall = await _getHallForBooking(db, row['hall_id'] as String);
      final services = await _getServicesForBooking(db, row['id'] as String);
      bookings.add(_mapRowToBooking(row, hall, services));
    }
    return bookings;
  }

  Future<String> createBooking({
    required String userId,
    required String hallId,
    required DateTime date,
    required int startHour,
    required int endHour,
    required List<String> serviceIds,
    required double finalPrice,
  }) async {
    final db = await _databaseService.database;
    final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    await db.transaction((txn) async {
      // Insert booking
      await txn.insert('bookings', {
        'id': bookingId,
        'user_id': userId,
        'hall_id': hallId,
        'booking_date': dateStr,
        'start_hour': startHour,
        'end_hour': endHour,
        'status': BookingStatus.pending.name,
        'final_price': finalPrice,
        'created_at': now,
        'updated_at': now,
      });

      // Insert services
      for (final serviceId in serviceIds) {
        await txn.insert('booking_services', {
          'booking_id': bookingId,
          'service_id': serviceId,
        });
      }
    });

    return bookingId;
  }

  Future<void> updateBooking(
    String bookingId, {
    String? hallId,
    DateTime? date,
    int? startHour,
    int? endHour,
    List<String>? serviceIds,
    double? finalPrice,
  }) async {
    final db = await _databaseService.database;
    final booking = await getBookingById(bookingId);
    if (booking == null || booking.status == BookingStatus.cancelled) {
      throw Exception('Cannot update this booking');
    }

    // Check if it's past the booking date
    if (booking.date.isBefore(DateTime.now())) {
      throw Exception('Cannot update past bookings');
    }

    final resolvedHallId = hallId ?? booking.hall.id;
    final resolvedDate = date ?? booking.date;
    final resolvedStartHour = startHour ?? booking.startHour;
    final resolvedEndHour = endHour ?? booking.endHour;

    if (resolvedStartHour >= resolvedEndHour) {
      throw Exception('Start hour must be before end hour');
    }

    final available = await isHallAvailableExcluding(
      resolvedHallId,
      resolvedDate,
      resolvedStartHour,
      resolvedEndHour,
      excludeBookingId: bookingId,
    );

    if (!available) {
      throw Exception('Selected hall is not available for that time slot');
    }

    final updates = <String, dynamic>{
      if (hallId != null) 'hall_id': hallId,
      if (date != null)
        'booking_date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      if (startHour != null) 'start_hour': startHour,
      if (endHour != null) 'end_hour': endHour,
      if (finalPrice != null) 'final_price': finalPrice,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await db.transaction((txn) async {
      await txn.update('bookings', updates, where: 'id = ?', whereArgs: [bookingId]);

      if (serviceIds != null) {
        await txn.delete('booking_services', where: 'booking_id = ?', whereArgs: [bookingId]);
        for (final serviceId in serviceIds) {
          await txn.insert('booking_services', {
            'booking_id': bookingId,
            'service_id': serviceId,
          });
        }
      }
    });
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final db = await _databaseService.database;
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    if (booking.status == BookingStatus.cancelled) {
      throw Exception('Booking is already cancelled');
    }

    await db.update(
      'bookings',
      {
        'status': BookingStatus.cancelled.name,
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancellation_reason': reason ?? 'User cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  Future<void> setBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? reason,
  }) async {
    if (status == BookingStatus.cancelled) {
      await cancelBooking(bookingId, reason: reason ?? 'Cancelled by admin');
      return;
    }

    final db = await _databaseService.database;
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    await db.update(
      'bookings',
      {
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  Future<void> deleteBooking(String bookingId) async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await txn.delete('booking_services', where: 'booking_id = ?', whereArgs: [bookingId]);
      await txn.delete('bookings', where: 'id = ?', whereArgs: [bookingId]);
    });
  }

  Future<void> logAudit({
    required String entityType,
    required String entityId,
    required String action,
    required String actorId,
    String? changes,
  }) async {
    final db = await _databaseService.database;
    final auditId = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert('audit_logs', {
      'id': auditId,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'actor_id': actorId,
      'changes': changes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Hall?> _getHallForBooking(Database db, String hallId) async {
    final result = await db.query('halls', where: 'id = ?', whereArgs: [hallId]);
    if (result.isEmpty) return null;

    final row = result.first;
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

  Future<List<AddOnService>> _getServicesForBooking(Database db, String bookingId) async {
    final result = await db.rawQuery(
      'SELECT s.* FROM add_on_services s JOIN booking_services bs ON s.id = bs.service_id WHERE bs.booking_id = ?',
      [bookingId],
    );

    return result
        .map((row) => AddOnService(
              id: row['id'] as String,
              name: row['name'] as String,
              unitPrice: row['unit_price'] as double,
            ))
        .toList();
  }

  Booking _mapRowToBooking(Map<String, dynamic> row, Hall? hall, List<AddOnService> services) {
    final dateStr = row['booking_date'] as String;
    final parts = dateStr.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

    return Booking(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      hall: hall ?? Hall(id: '', name: '', location: '', capacity: 0, basePrice: 0, amenities: []),
      date: date,
      startHour: row['start_hour'] as int,
      endHour: row['end_hour'] as int,
      services: services,
      status: BookingStatus.values.firstWhere((e) => e.name == row['status'] as String),
      finalPrice: row['final_price'] as double,
    );
  }
}
