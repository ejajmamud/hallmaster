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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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
    _resetInactivityTimer(role);

    final navItems = _buildNavItems(role);
    final currentIndex = _selectedIndex(navItems, widget.currentPath);

    return Scaffold(
      key: _scaffoldKey,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetInactivityTimer(role),
        child: SafeArea(top: true, child: widget.body),
      ),
      floatingActionButton: widget.floatingActionButton,
      endDrawer:
          (role == UserRole.user || role == UserRole.admin) && user != null
              ? _UserLinksDrawer(
                  user: user,
                  isAdmin: role == UserRole.admin,
                  onNavigate: (path) {
                    Navigator.of(context).pop();
                    _resetInactivityTimer(role);
                    context.go(path);
                  },
                  onEditProfile: () {
                    Navigator.of(context).pop();
                    _resetInactivityTimer(role);
                    _showEditProfileDialog(user);
                  },
                  onLogout: () {
                    Navigator.of(context).pop();
                    _logout();
                  },
                )
              : null,
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
          final item = navItems[index];
          if (item.opensDrawer) {
            _scaffoldKey.currentState?.openEndDrawer();
            return;
          }
          context.go(item.path);
        },
      ),
    );
  }

  Future<void> _showEditProfileDialog(AppUser user) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          var isSaving = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Edit Profile'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: ValidationService.validateName,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppTokens.s3),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.call_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: ValidationService.validatePhone,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }
                            setDialogState(() => isSaving = true);
                            final normalizedName =
                                SecurityService.normalizeName(
                                    nameController.text);
                            final phone = phoneController.text.trim();
                            await ref.read(userRepositoryProvider).updateUser(
                                  user.id,
                                  name: normalizedName,
                                  phone: phone,
                                );
                            ref.read(currentUserProvider.notifier).state =
                                AppUser(
                              id: user.id,
                              name: normalizedName,
                              email: user.email,
                              role: user.role,
                              phone: phone,
                            );
                            if (mounted && context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                    content: Text('Profile updated')),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
    }
  }

  void _logout() {
    _inactivityTimer?.cancel();
    ref.read(currentUserProvider.notifier).state = const AppUser(
      id: 'guest',
      name: 'Guest',
      email: '-',
      role: UserRole.guest,
    );
    context.go('/login');
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
          _NavItem(
              path: '__menu__',
              label: 'Menu',
              icon: Icons.menu_rounded,
              opensDrawer: true),
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
          _NavItem(
              path: '__menu__',
              label: 'Menu',
              icon: Icons.menu_rounded,
              opensDrawer: true),
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
}

class _NavItem {
  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    this.opensDrawer = false,
  });

  final String path;
  final String label;
  final IconData icon;
  final bool opensDrawer;
}

class _UserLinksDrawer extends StatelessWidget {
  const _UserLinksDrawer({
    required this.user,
    required this.isAdmin,
    required this.onNavigate,
    required this.onEditProfile,
    required this.onLogout,
  });

  final AppUser user;
  final bool isAdmin;
  final ValueChanged<String> onNavigate;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s4,
                AppTokens.s4,
                AppTokens.s4,
                AppTokens.s3,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTokens.brandSurface,
                    foregroundColor: AppTokens.brand,
                    child: Text(
                      user.name.trim().isEmpty
                          ? 'U'
                          : user.name.trim()[0].toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTokens.wExtraBold,
                        color: AppTokens.brand,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: AppTokens.wBold,
                          ),
                        ),
                        Text(
                          isAdmin ? '${user.email} | Admin' : user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.s2),
                children: [
                  _DrawerActionTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit profile',
                    subtitle: 'Update your name and phone',
                    onTap: onEditProfile,
                  ),
                  const Divider(height: AppTokens.s4),
                  if (isAdmin) ...[
                    _DrawerActionTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin overview',
                      subtitle: 'Metrics and operational summary',
                      onTap: () => onNavigate('/admin'),
                    ),
                    _DrawerActionTile(
                      icon: Icons.fact_check_outlined,
                      title: 'Booking queue',
                      subtitle: 'Review approvals and statuses',
                      onTap: () => onNavigate('/admin/bookings'),
                    ),
                    _DrawerActionTile(
                      icon: Icons.apartment_outlined,
                      title: 'Hall management',
                      subtitle: 'Create, edit, or remove halls',
                      onTap: () => onNavigate('/admin/halls'),
                    ),
                    _DrawerActionTile(
                      icon: Icons.people_outline,
                      title: 'User directory',
                      subtitle: 'View registered users',
                      onTap: () => onNavigate('/admin/users'),
                    ),
                    _DrawerActionTile(
                      icon: Icons.public_outlined,
                      title: 'Public hall view',
                      onTap: () => onNavigate('/guest'),
                    ),
                  ] else ...[
                    _DrawerActionTile(
                      icon: Icons.home_outlined,
                      title: 'Home',
                      onTap: () => onNavigate('/user'),
                    ),
                    _DrawerActionTile(
                      icon: Icons.add_circle_outline,
                      title: 'Create booking',
                      onTap: () => onNavigate('/booking/new'),
                    ),
                    _DrawerActionTile(
                      icon: Icons.event_note_outlined,
                      title: 'My bookings',
                      onTap: () => onNavigate('/booking/my'),
                    ),
                    _DrawerActionTile(
                      icon: Icons.apartment_outlined,
                      title: 'Browse public halls',
                      onTap: () => onNavigate('/guest'),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTokens.s3),
              child: _DrawerActionTile(
                icon: Icons.logout,
                title: 'Logout',
                danger: true,
                onTap: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTokens.danger : AppTokens.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: AppTokens.wSemibold,
            ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
    );
  }
}
