import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/features/admin/admin_dashboard_page.dart';
import 'package:hallmaster_enterprise/src/features/auth/login_page.dart';
import 'package:hallmaster_enterprise/src/features/booking/booking_flow_page.dart';
import 'package:hallmaster_enterprise/src/features/booking/my_bookings_page.dart';
import 'package:hallmaster_enterprise/src/features/guest/guest_home_page.dart';
import 'package:hallmaster_enterprise/src/features/user/user_home_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/guest',
    routes: [
      GoRoute(path: '/guest', builder: (_, __) => GuestHomePage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/user', builder: (_, __) => const UserHomePage()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardPage()),
      GoRoute(path: '/booking/new', builder: (_, __) => BookingFlowPage()),
      GoRoute(path: '/booking/my', builder: (_, __) => MyBookingsPage()),
    ],
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final path = state.fullPath ?? state.path;
      final role = user?.role ?? UserRole.guest;

      if (path == '/admin' && role != UserRole.admin) {
        return '/login';
      }
      if ((path == '/user' || path == '/booking/new' || path == '/booking/my') && role == UserRole.guest) {
        return '/login';
      }
      return null;
    },
  );
});
