import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/widgets/app_shell_scaffold.dart';
import 'package:intl/intl.dart';

class UserHomePage extends ConsumerWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final bookingsAsync =
        user == null ? null : ref.watch(userBookingsProvider(user.id));
    final bookings = bookingsAsync?.maybeWhen(
            data: (items) => items, orElse: () => <Booking>[]) ??
        <Booking>[];

    final bookedCount = bookings.length;
    final pendingCount = bookings
        .where((booking) => booking.status == BookingStatus.pending)
        .length;
    final approvedCount = bookings
        .where((booking) => booking.status == BookingStatus.confirmed)
        .length;
    final activeCount = bookings
        .where((booking) =>
            booking.status == BookingStatus.pending ||
            booking.status == BookingStatus.confirmed)
        .length;
    final recentBookings = [...bookings]
      ..sort((a, b) => b.date.compareTo(a.date));

    return AppShellScaffold(
      title: 'Welcome, ${user?.name ?? 'User'}',
      currentPath: '/user',
      body: ColoredBox(
        color: AppTokens.canvas,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s4,
            0,
            AppTokens.s4,
            AppTokens.s4,
          ),
          children: [
            _HeroSection(
              userName: user?.name ?? 'User',
              activeCount: activeCount,
              pendingCount: pendingCount,
              onBookNow: () => context.go('/booking/new'),
              onOpenBookings: () => context.go('/booking/my'),
            ),
            const SizedBox(height: AppTokens.s4),
            _MetricsGrid(
              bookedCount: bookedCount,
              pendingCount: pendingCount,
              approvedCount: approvedCount,
              activeCount: activeCount,
            ),
            const SizedBox(height: AppTokens.s4),
            _RecentBookingsSection(
              bookings: recentBookings.take(3).toList(),
              onOpenAll: () => context.go('/booking/my'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.userName,
    required this.activeCount,
    required this.pendingCount,
    required this.onBookNow,
    required this.onOpenBookings,
  });

  final String userName;
  final int activeCount;
  final int pendingCount;
  final VoidCallback onBookNow;
  final VoidCallback onOpenBookings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = DateFormat('EEE, d MMM').format(DateTime.now());
    final primaryButtonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: AppTokens.brandInk,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s3,
        vertical: AppTokens.s3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
    );
    final secondaryButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.white70),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s3,
        vertical: AppTokens.s3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565D8), Color(0xFF0B4DB5), Color(0xFF083A80)],
            stops: [0.0, 0.58, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F0B3F9A),
              blurRadius: 30,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -48,
              right: -34,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              child: Container(
                width: 92,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x00FFFFFF), // Hidden - was causing visual artifact
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
              ),
            ),
            Positioned(
              bottom: -56,
              left: -28,
              child: Container(
                width: 124,
                height: 124,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x18FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Workspace overview',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s2,
                          vertical: AppTokens.s1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusPill),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              today,
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s2),
                  Text(
                    'Hello, $userName',
                    style: textTheme.titleLarge?.copyWith(
                      letterSpacing: -0.2,
                      fontWeight: AppTokens.wExtraBold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Track request status and keep your booking flow moving.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: '$activeCount active',
                        icon: Icons.bolt_outlined,
                      ),
                      _StatusChip(
                        label: '$pendingCount pending',
                        icon: Icons.schedule,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s3),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 420;
                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Tooltip(
                              message: 'Open new booking form',
                              child: FilledButton.icon(
                                style: primaryButtonStyle,
                                onPressed: onBookNow,
                                icon: const Icon(Icons.add),
                                label: const Text('Create booking'),
                              ),
                            ),
                            const SizedBox(height: AppTokens.s2),
                            Tooltip(
                              message: 'Open your booking list',
                              child: TextButton.icon(
                                style: secondaryButtonStyle,
                                onPressed: onOpenBookings,
                                icon: const Icon(Icons.event_note_outlined),
                                label: const Text('View bookings'),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Tooltip(
                              message: 'Open new booking form',
                              child: FilledButton.icon(
                                style: primaryButtonStyle,
                                onPressed: onBookNow,
                                icon: const Icon(Icons.add),
                                label: const Text('Create booking'),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.s2),
                          Expanded(
                            flex: 2,
                            child: Tooltip(
                              message: 'Open your booking list',
                              child: TextButton.icon(
                                style: secondaryButtonStyle,
                                onPressed: onOpenBookings,
                                icon: const Icon(Icons.event_note_outlined),
                                label: const Text('View bookings'),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s3,
        vertical: AppTokens.s2,
      ),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: AppTokens.wSemibold,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecentBookingsSection extends StatelessWidget {
  const _RecentBookingsSection({
    required this.bookings,
    required this.onOpenAll,
  });

  final List<Booking> bookings;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Card(
        child: Padding(
          padding: AppTokens.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTokens.brandSurface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: const Icon(Icons.event_available_outlined,
                    color: AppTokens.brand, size: 20),
              ),
              const SizedBox(width: AppTokens.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No bookings yet',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Create your first request to get started.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTokens.textSecondary),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Open all bookings',
                child: IconButton(
                  onPressed: onOpenAll,
                  tooltip: 'Open bookings',
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('EEE, dd MMM');
    return Card(
      child: Padding(
        padding: AppTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Recent bookings',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Tooltip(
                  message: 'Open full booking list',
                  child: TextButton(
                      onPressed: onOpenAll, child: const Text('View all')),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s2),
            for (int i = 0; i < bookings.length; i++) ...[
              _RecentBookingRow(
                booking: bookings[i],
                dateFormat: dateFormat,
              ),
              if (i < bookings.length - 1)
                const Divider(height: AppTokens.s4, thickness: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentBookingRow extends StatelessWidget {
  const _RecentBookingRow({
    required this.booking,
    required this.dateFormat,
  });

  final Booking booking;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final intent = _intentFor(booking.status);
    final pair = AppTokens.statusColors(intent);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.hall.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${dateFormat.format(booking.date)} · '
                '${booking.startHour.toString().padLeft(2, '0')}:00–'
                '${booking.endHour.toString().padLeft(2, '0')}:00',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTokens.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.s2),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s2 + 2, vertical: AppTokens.s1),
          decoration: BoxDecoration(
            color: pair.bg,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                booking.status == BookingStatus.confirmed
                    ? Icons.verified_outlined
                    : booking.status == BookingStatus.pending
                        ? Icons.schedule
                        : Icons.event_busy_outlined,
                size: 14,
                color: pair.fg,
              ),
              const SizedBox(width: 4),
              Text(
                booking.status.name.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: pair.fg,
                      fontWeight: AppTokens.wSemibold,
                      letterSpacing: 0.6,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  StatusIntent _intentFor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return StatusIntent.success;
      case BookingStatus.pending:
        return StatusIntent.warning;
      case BookingStatus.cancelled:
        return StatusIntent.danger;
      case BookingStatus.completed:
        return StatusIntent.info;
    }
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.bookedCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.activeCount,
  });

  final int bookedCount;
  final int pendingCount;
  final int approvedCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MetricTile(
        label: 'Total',
        value: '$bookedCount',
        icon: Icons.dataset_outlined,
        intent: StatusIntent.info,
      ),
      _MetricTile(
        label: 'Pending',
        value: '$pendingCount',
        icon: Icons.hourglass_top_rounded,
        intent: StatusIntent.warning,
      ),
      _MetricTile(
        label: 'Approved',
        value: '$approvedCount',
        icon: Icons.verified_outlined,
        intent: StatusIntent.success,
      ),
      _MetricTile(
        label: 'Active',
        value: '$activeCount',
        icon: Icons.bolt_outlined,
        intent: StatusIntent.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppTokens.s2;
        final isCompact = constraints.maxWidth < 680;

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: spacing),
                  Expanded(child: tiles[1]),
                ],
              ),
              const SizedBox(height: spacing),
              Row(
                children: [
                  Expanded(child: tiles[2]),
                  const SizedBox(width: spacing),
                  Expanded(child: tiles[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: spacing),
            Expanded(child: tiles[1]),
            const SizedBox(width: spacing),
            Expanded(child: tiles[2]),
            const SizedBox(width: spacing),
            Expanded(child: tiles[3]),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.intent,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatusIntent intent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pair = AppTokens.statusColors(intent);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: AppTokens.cardSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B3F9A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: pair.bg,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
              child: Icon(icon, size: 18, color: pair.fg),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    height: 1.0,
                    fontWeight: AppTokens.wSemibold,
                  ),
                ),
                const SizedBox(height: AppTokens.s1),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTokens.textSecondary,
                    fontWeight: AppTokens.wSemibold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
