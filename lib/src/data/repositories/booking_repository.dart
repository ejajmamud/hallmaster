import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hallmaster_enterprise/src/core/firestore_service.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';

class BookingRepository {
  BookingRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<Booking?> getBookingById(String id) async {
    try {
      final doc = await _firestoreService.bookings
          .doc(id)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      if (!doc.exists) return null;
      return _mapDataToBooking(doc.id, doc.data() ?? {});
    } catch (_) {
      final data = FirestoreService.fallbackBookings[id];
      return data == null ? null : _mapDataToBooking(id, data);
    }
  }

  Future<List<Booking>> getBookingsByUser(String userId) async {
    try {
      final result = await _firestoreService.bookings
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      final bookings = <Booking>[];
      for (final doc in result.docs) {
        final booking = await _mapDataToBooking(doc.id, doc.data());
        if (booking.status != BookingStatus.cancelled) {
          bookings.add(booking);
        }
      }
      bookings.sort((a, b) => b.date.compareTo(a.date));
      return bookings;
    } catch (_) {
      final bookings = await _fallbackBookings();
      return bookings
          .where((booking) =>
              booking.userId == userId &&
              booking.status != BookingStatus.cancelled)
          .toList();
    }
  }

  Stream<List<Booking>> watchBookingsByUser(String userId) {
    try {
      return _firestoreService.bookings
          .where('userId', isEqualTo: userId)
          .snapshots()
          .asyncMap((snapshot) async {
        final bookings = <Booking>[];
        for (final doc in snapshot.docs) {
          final booking = await _mapDataToBooking(doc.id, doc.data());
          if (booking.status != BookingStatus.cancelled) {
            bookings.add(booking);
          }
        }
        bookings.sort((a, b) => b.date.compareTo(a.date));
        return bookings;
      });
    } catch (_) {
      return Stream.fromFuture(getBookingsByUser(userId));
    }
  }

  Future<List<Booking>> getAllBookings() async {
    try {
      final result = await _firestoreService.bookings
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      final bookings = <Booking>[];
      for (final doc in result.docs) {
        bookings.add(await _mapDataToBooking(doc.id, doc.data()));
      }
      bookings.sort((a, b) => b.date.compareTo(a.date));
      return bookings;
    } catch (_) {
      return _fallbackBookings();
    }
  }

  Stream<List<Booking>> watchAllBookings() {
    try {
      return _firestoreService.bookings.snapshots().asyncMap((snapshot) async {
        final bookings = <Booking>[];
        for (final doc in snapshot.docs) {
          bookings.add(await _mapDataToBooking(doc.id, doc.data()));
        }
        bookings.sort((a, b) => b.date.compareTo(a.date));
        return bookings;
      });
    } catch (_) {
      return Stream.fromFuture(getAllBookings());
    }
  }

  Future<bool> isHallAvailable(
    String hallId,
    DateTime date,
    int startHour,
    int endHour,
  ) async {
    return isHallAvailableExcluding(hallId, date, startHour, endHour);
  }

  Future<bool> isHallAvailableExcluding(
    String hallId,
    DateTime date,
    int startHour,
    int endHour, {
    String? excludeBookingId,
  }) async {
    try {
      final conflicts = await _getRawConflictingBookingDocs(
        hallId,
        date,
        startHour,
        endHour,
        excludeBookingId: excludeBookingId,
      );
      return conflicts.isEmpty;
    } catch (_) {
      final conflicts = await _fallbackConflictingBookings(
        hallId,
        date,
        startHour,
        endHour,
        excludeBookingId: excludeBookingId,
      );
      return conflicts.isEmpty;
    }
  }

  Future<List<Booking>> getConflictingBookings(
    String hallId,
    DateTime date,
    int startHour,
    int endHour,
  ) async {
    try {
      final docs =
          await _getRawConflictingBookingDocs(hallId, date, startHour, endHour);
      final bookings = <Booking>[];
      for (final doc in docs) {
        bookings.add(await _mapDataToBooking(doc.id, doc.data()));
      }
      return bookings;
    } catch (_) {
      return _fallbackConflictingBookings(hallId, date, startHour, endHour);
    }
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
    final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();

    final data = {
      'userId': userId,
      'hallId': hallId,
      'bookingDate': _formatDate(date),
      'startHour': startHour,
      'endHour': endHour,
      'serviceIds': serviceIds,
      'status': BookingStatus.pending.name,
      'finalPrice': finalPrice,
      'createdAt': now,
      'updatedAt': now,
    };

    try {
      await _firestoreService.bookings
          .doc(bookingId)
          .set(data)
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackBookings[bookingId] = data;
    }

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
    final booking = await getBookingById(bookingId);
    if (booking == null || booking.status == BookingStatus.cancelled) {
      throw Exception('Cannot update this booking');
    }

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
      if (hallId != null) 'hallId': hallId,
      if (date != null) 'bookingDate': _formatDate(date),
      if (startHour != null) 'startHour': startHour,
      if (endHour != null) 'endHour': endHour,
      if (serviceIds != null) 'serviceIds': serviceIds,
      if (finalPrice != null) 'finalPrice': finalPrice,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _firestoreService.bookings
          .doc(bookingId)
          .update(updates)
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackBookings[bookingId]?.addAll(updates);
    }
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    if (booking.status == BookingStatus.cancelled) {
      throw Exception('Booking is already cancelled');
    }

    final updates = {
      'status': BookingStatus.cancelled.name,
      'cancelledAt': DateTime.now().toIso8601String(),
      'cancellationReason': reason ?? 'User cancelled',
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _firestoreService.bookings
          .doc(bookingId)
          .update(updates)
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackBookings[bookingId]?.addAll(updates);
    }
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

    final booking = await getBookingById(bookingId);
    if (booking == null) {
      throw Exception('Booking not found');
    }

    final updates = {
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _firestoreService.bookings
          .doc(bookingId)
          .update(updates)
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackBookings[bookingId]?.addAll(updates);
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestoreService.bookings
          .doc(bookingId)
          .delete()
          .timeout(FirestoreService.fallbackTimeout);
    } catch (_) {
      FirestoreService.fallbackBookings.remove(bookingId);
    }
  }

  Future<void> logAudit({
    required String entityType,
    required String entityId,
    required String action,
    required String actorId,
    String? changes,
  }) async {
    final auditId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      await _firestoreService.auditLogs.doc(auditId).set({
        'entityType': entityType,
        'entityId': entityId,
        'action': action,
        'actorId': actorId,
        'changes': changes,
        'createdAt': DateTime.now().toIso8601String(),
      }).timeout(FirestoreService.fallbackTimeout);
    } catch (_) {}
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _getRawConflictingBookingDocs(
    String hallId,
    DateTime date,
    int startHour,
    int endHour, {
    String? excludeBookingId,
  }) async {
    final result = await _firestoreService.bookings
        .where('hallId', isEqualTo: hallId)
        .where('bookingDate', isEqualTo: _formatDate(date))
        .get()
        .timeout(FirestoreService.fallbackTimeout);

    return result.docs.where((doc) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      final existingStart = (data['startHour'] as num?)?.toInt() ?? 0;
      final existingEnd = (data['endHour'] as num?)?.toInt() ?? 0;
      final active = status == BookingStatus.pending.name ||
          status == BookingStatus.confirmed.name;
      final overlaps = !(existingEnd <= startHour || existingStart >= endHour);
      return active &&
          overlaps &&
          (excludeBookingId == null || doc.id != excludeBookingId);
    }).toList();
  }

  Future<Booking> _mapDataToBooking(
    String id,
    Map<String, dynamic> data,
  ) async {
    final hall = await _getHallForBooking(data['hallId'] as String? ?? '');
    final services = await _getServicesForBooking(
        data['serviceIds'] as List<dynamic>? ?? []);

    return Booking(
      id: id,
      userId: data['userId'] as String? ?? '',
      hall: hall,
      date: _parseDate(data['bookingDate'] as String? ?? ''),
      startHour: (data['startHour'] as num?)?.toInt() ?? 0,
      endHour: (data['endHour'] as num?)?.toInt() ?? 0,
      services: services,
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<Hall> _getHallForBooking(String hallId) async {
    try {
      final doc = await _firestoreService.halls
          .doc(hallId)
          .get()
          .timeout(FirestoreService.fallbackTimeout);
      final data = doc.data() ?? {};
      return Hall(
        id: doc.exists ? doc.id : '',
        name: data['name'] as String? ?? '',
        location: data['location'] as String? ?? '',
        capacity: (data['capacity'] as num?)?.toInt() ?? 0,
        basePrice: (data['basePrice'] as num?)?.toDouble() ?? 0,
        amenities: (data['amenities'] as List<dynamic>? ?? [])
            .map((e) => '$e')
            .toList(),
        imageUrls: (data['imageUrls'] as List<dynamic>? ?? [])
            .map((e) => '$e')
            .toList(),
        addOnServiceIds: data.containsKey('addOnServiceIds')
            ? (data['addOnServiceIds'] as List<dynamic>? ?? [])
                .map((e) => '$e')
                .toList()
            : FirestoreService.fallbackServices
                .map((service) => service.id)
                .toList(),
      );
    } catch (_) {
      for (final hall in FirestoreService.fallbackHalls) {
        if (hall.id == hallId) return hall;
      }
    }

    return const Hall(
      id: '',
      name: '',
      location: '',
      capacity: 0,
      basePrice: 0,
      amenities: [],
    );
  }

  Future<List<AddOnService>> _getServicesForBooking(
    List<dynamic> serviceIds,
  ) async {
    final services = <AddOnService>[];
    for (final serviceId in serviceIds.map((e) => '$e')) {
      try {
        final doc = await _firestoreService.services
            .doc(serviceId)
            .get()
            .timeout(FirestoreService.fallbackTimeout);
        final data = doc.data();
        if (data == null) continue;
        services.add(AddOnService(
          id: doc.id,
          name: data['name'] as String? ?? '',
          unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
        ));
      } catch (_) {
        for (final service in FirestoreService.fallbackServices) {
          if (service.id == serviceId) services.add(service);
        }
      }
    }
    return services;
  }

  Future<List<Booking>> _fallbackBookings() async {
    final bookings = <Booking>[];
    for (final entry in FirestoreService.fallbackBookings.entries) {
      bookings.add(await _mapDataToBooking(entry.key, entry.value));
    }
    bookings.sort((a, b) => b.date.compareTo(a.date));
    return bookings;
  }

  Future<List<Booking>> _fallbackConflictingBookings(
    String hallId,
    DateTime date,
    int startHour,
    int endHour, {
    String? excludeBookingId,
  }) async {
    final bookings = await _fallbackBookings();
    final dateStr = _formatDate(date);
    return bookings.where((booking) {
      final active = booking.status == BookingStatus.pending ||
          booking.status == BookingStatus.confirmed;
      final overlaps =
          !(booking.endHour <= startHour || booking.startHour >= endHour);
      return active &&
          overlaps &&
          booking.hall.id == hallId &&
          _formatDate(booking.date) == dateStr &&
          (excludeBookingId == null || booking.id != excludeBookingId);
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) {
      return DateTime.now();
    }
    return DateTime(
      int.tryParse(parts[0]) ?? DateTime.now().year,
      int.tryParse(parts[1]) ?? DateTime.now().month,
      int.tryParse(parts[2]) ?? DateTime.now().day,
    );
  }
}
