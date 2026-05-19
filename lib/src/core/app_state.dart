import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hallmaster_enterprise/src/core/firestore_service.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/data/repositories/booking_repository.dart';
import 'package:hallmaster_enterprise/src/data/repositories/hall_repository.dart';
import 'package:hallmaster_enterprise/src/data/repositories/service_repository.dart';
import 'package:hallmaster_enterprise/src/data/repositories/user_repository.dart';

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Repository Providers
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return UserRepository(firestoreService);
});

final hallRepositoryProvider = Provider<HallRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return HallRepository(firestoreService);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BookingRepository(firestoreService);
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ServiceRepository(firestoreService);
});

// Current User Provider
final currentUserProvider = StateProvider<AppUser?>(
  (ref) => const AppUser(
      id: 'guest', name: 'Guest', email: '-', role: UserRole.guest),
);

// Halls Provider - loads from database
final hallsProvider = FutureProvider<List<Hall>>((ref) async {
  final repository = ref.watch(hallRepositoryProvider);
  return repository.getAllHalls();
});

// Services Provider - loads from database
final servicesProvider = FutureProvider<List<AddOnService>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getAllServices();
});

// Search halls provider
final searchHallsProvider =
    FutureProvider.family<List<Hall>, String>((ref, query) async {
  final repository = ref.watch(hallRepositoryProvider);
  return repository.searchHalls(query: query.isEmpty ? null : query);
});

// User bookings provider
final userBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, userId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByUser(userId);
});

// All bookings provider (for admin)
final allBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getAllBookings();
});

// All users provider (for admin)
final allUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getAllUsers();
});

// Double booking check provider
final checkDoubleBookingProvider =
    FutureProvider.family<bool, (String, DateTime, int, int)>(
        (ref, params) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final (hallId, date, startHour, endHour) = params;
  return repository.isHallAvailable(hallId, date, startHour, endHour);
});
