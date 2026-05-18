import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hallmaster_enterprise/src/core/database.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/data/repositories/booking_repository.dart';
import 'package:hallmaster_enterprise/src/data/repositories/hall_repository.dart';
import 'package:hallmaster_enterprise/src/data/repositories/service_repository.dart';
import 'package:hallmaster_enterprise/src/data/repositories/user_repository.dart';

// Database Service Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Repository Providers
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return UserRepository(dbService);
});

final hallRepositoryProvider = Provider<HallRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return HallRepository(dbService);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BookingRepository(dbService);
});

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ServiceRepository(dbService);
});

// Current User Provider
final currentUserProvider = StateProvider<AppUser?>(
  (ref) => const AppUser(id: 'guest', name: 'Guest', email: '-', role: UserRole.guest),
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
final searchHallsProvider = FutureProvider.family<List<Hall>, String>((ref, query) async {
  final repository = ref.watch(hallRepositoryProvider);
  return repository.searchHalls(query: query.isEmpty ? null : query);
});

// User bookings provider
final userBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, userId) async {
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
final checkDoubleBookingProvider = FutureProvider.family<bool, (String, DateTime, int, int)>((ref, params) async {
  final repository = ref.watch(bookingRepositoryProvider);
  final (hallId, date, startHour, endHour) = params;
  return repository.isHallAvailable(hallId, date, startHour, endHour);
});
