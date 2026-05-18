import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';

class AppShellScaffold extends ConsumerStatefulWidget {
  const AppShellScaffold({
    super.key,
    required this.title,
    required this.currentPath,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final String currentPath;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  ConsumerState<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends ConsumerState<AppShellScaffold> {
  Timer? _inactivityTimer;

  void _resetInactivityTimer(UserRole role) {
    _inactivityTimer?.cancel();
    if (role == UserRole.guest) {
      return;
    }

    _inactivityTimer = Timer(SessionPolicy.inactivityTimeout, () {
      if (!mounted) return;

      ref.read(currentUserProvider.notifier).state = const AppUser(
          id: 'guest', name: 'Guest', email: '-', role: UserRole.guest);
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Session expired due to inactivity. Please sign in again.')),
      );
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final role = user?.role ?? UserRole.guest;
    final usesBrandHeader = role != UserRole.admin;

    _resetInactivityTimer(role);

    final navItems = _buildNavItems(role);
    final currentIndex = _selectedIndex(navItems, widget.currentPath);

    // Eyebrow label is only informative for signed-in roles; for guests
    // the page title already carries that context.
    final eyebrow = role == UserRole.admin
        ? 'Admin'
        : role == UserRole.user
            ? 'Bookings'
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1565D8), // Blue branding color
        elevation: 8,
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetInactivityTimer(role),
        child: SafeArea(top: !usesBrandHeader, child: widget.body),
      ),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        surfaceTintColor: Colors.transparent,
        destinations: [
          for (final item in navItems)
            NavigationDestination(
              icon: Tooltip(message: item.label, child: Icon(item.icon)),
              label: item.label,
            ),
        ],
        onDestinationSelected: (index) {
          _resetInactivityTimer(role);
          context.go(navItems[index].path);
        },
      ),
    );
  }

  List<_NavItem> _buildNavItems(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          _NavItem(
              path: '/admin',
              label: 'Dashboard',
              icon: Icons.admin_panel_settings_outlined),
          _NavItem(
              path: '/guest', label: 'Public', icon: Icons.public_outlined),
        ];
      case UserRole.user:
        return const [
          _NavItem(path: '/user', label: 'Home', icon: Icons.home_outlined),
          _NavItem(
              path: '/booking/new',
              label: 'Book',
              icon: Icons.add_circle_outline),
          _NavItem(
              path: '/booking/my',
              label: 'My Bookings',
              icon: Icons.event_note_outlined),
        ];
      case UserRole.guest:
        return const [
          _NavItem(
              path: '/guest', label: 'Browse', icon: Icons.apartment_outlined),
          _NavItem(path: '/login', label: 'Login', icon: Icons.login_outlined),
        ];
    }
  }

  int _selectedIndex(List<_NavItem> items, String path) {
    final index = items.indexWhere((item) => item.path == path);
    return index < 0 ? 0 : index;
  }

  String _homePathForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin';
      case UserRole.user:
        return '/user';
      case UserRole.guest:
        return '/guest';
    }
  }
}

class _NavItem {
  const _NavItem({required this.path, required this.label, required this.icon});

  final String path;
  final String label;
  final IconData icon;
}
