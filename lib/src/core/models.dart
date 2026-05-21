import 'package:equatable/equatable.dart';

enum UserRole { guest, user, admin }

enum BookingStatus { pending, confirmed, cancelled, completed }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;

  @override
  List<Object?> get props => [id, name, email, role, phone];
}

class Hall extends Equatable {
  const Hall({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.basePrice,
    required this.amenities,
    this.imageUrls = const [],
    this.addOnServiceIds = const [],
  });

  final String id;
  final String name;
  final String location;
  final int capacity;
  final double basePrice;
  final List<String> amenities;
  final List<String> imageUrls;
  final List<String> addOnServiceIds;

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        capacity,
        basePrice,
        amenities,
        imageUrls,
        addOnServiceIds,
      ];
}

class AddOnService extends Equatable {
  const AddOnService(
      {required this.id, required this.name, required this.unitPrice});

  final String id;
  final String name;
  final double unitPrice;

  @override
  List<Object?> get props => [id, name, unitPrice];
}

class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.userId,
    required this.hall,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.services,
    required this.status,
    required this.finalPrice,
  });

  final String id;
  final String userId;
  final Hall hall;
  final DateTime date;
  final int startHour;
  final int endHour;
  final List<AddOnService> services;
  final BookingStatus status;
  final double finalPrice;

  Booking copyWith({
    DateTime? date,
    int? startHour,
    int? endHour,
    List<AddOnService>? services,
    BookingStatus? status,
    double? finalPrice,
  }) {
    return Booking(
      id: id,
      userId: userId,
      hall: hall,
      date: date ?? this.date,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      services: services ?? this.services,
      status: status ?? this.status,
      finalPrice: finalPrice ?? this.finalPrice,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        hall,
        date,
        startHour,
        endHour,
        services,
        status,
        finalPrice
      ];
}
