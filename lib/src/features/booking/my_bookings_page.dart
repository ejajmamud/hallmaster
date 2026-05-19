import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';
import 'package:hallmaster_enterprise/src/core/widgets/async_state_views.dart';
import 'package:hallmaster_enterprise/src/core/widgets/app_shell_scaffold.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends ConsumerStatefulWidget {
  const MyBookingsPage({super.key});

  @override
  ConsumerState<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends ConsumerState<MyBookingsPage> {
  final _searchController = TextEditingController();
  BookingStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    final query = _searchController.text.trim().toLowerCase();
    return bookings.where((booking) {
      final matchesStatus =
          _statusFilter == null || booking.status == _statusFilter;
      final matchesQuery = query.isEmpty ||
          booking.hall.name.toLowerCase().contains(query) ||
          booking.status.name.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  Future<void> _handleCancel(Booking booking) async {
    final confirmed = await _confirmCancelBooking(booking);
    if (!confirmed || !mounted) return;

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      await bookingRepo.cancelBooking(
        booking.id,
        reason: 'User cancelled',
      );
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        ref.invalidate(userBookingsProvider(currentUser.id));
      }
      ref.invalidate(allBookingsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking cancelled. Your slot has been released.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel booking: $e')),
      );
    }
  }

  Future<bool> _confirmCancelBooking(Booking booking) async {
    final dateLabel = DateFormat('EEE, dd MMM yyyy').format(booking.date);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined,
            size: 32, color: AppTokens.danger),
        title: const Text('Cancel this booking?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to cancel your booking for ${booking.hall.name}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTokens.textPrimary,
                  ),
            ),
            const SizedBox(height: AppTokens.s2),
            Container(
              padding: const EdgeInsets.all(AppTokens.s3),
              decoration: BoxDecoration(
                color: AppTokens.canvasTint,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                border: Border.all(color: AppTokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(label: 'Date', value: dateLabel),
                  const SizedBox(height: 4),
                  _SummaryRow(
                    label: 'Time',
                    value:
                        '${booking.startHour.toString().padLeft(2, '0')}:00 – ${booking.endHour.toString().padLeft(2, '0')}:00',
                  ),
                  const SizedBox(height: 4),
                  _SummaryRow(
                    label: 'Total',
                    value: 'RM ${booking.finalPrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s3),
            const Text(
              'This cannot be undone. Your booking slot will be released and cannot be edited afterwards.',
              style: TextStyle(
                color: AppTokens.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
            AppTokens.s3, 0, AppTokens.s3, AppTokens.s3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Booking'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.danger,
              foregroundColor: AppTokens.textInverse,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showEditBookingDialog(Booking booking) async {
    final halls = await ref.read(hallsProvider.future);
    if (!mounted) return;
    Hall? selectedHall = booking.hall;
    for (final hall in halls) {
      if (hall.id == booking.hall.id) {
        selectedHall = hall;
        break;
      }
    }
    DateTime selectedDate = booking.date;
    int startHour = booking.startHour;
    int endHour = booking.endHour;
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedHallPrice =
                selectedHall?.basePrice ?? booking.hall.basePrice;
            final durationFactor = ((endHour - startHour).clamp(1, 24)) / 4;
            final serviceTotal = booking.services
                .fold<double>(0, (sum, service) => sum + service.unitPrice);
            final subtotal = selectedHallPrice * durationFactor;
            final tax = (subtotal + serviceTotal) * 0.06;
            final total = subtotal + serviceTotal + tax;

            return AlertDialog(
              title: const Text('Reschedule Booking'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (dialogError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(dialogError!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ),
                      DropdownButtonFormField<Hall>(
                        value: selectedHall,
                        decoration: const InputDecoration(labelText: 'Hall'),
                        items: halls
                            .map(
                              (hall) => DropdownMenuItem<Hall>(
                                value: hall,
                                child: Text(
                                    '${hall.name} (RM ${hall.basePrice.toStringAsFixed(2)})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setDialogState(() => selectedHall = value),
                      ),
                      const SizedBox(height: 10),
                      Tooltip(
                        message: 'Select booking date',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date'),
                          subtitle: Text(DateFormat('EEE, dd MMM yyyy')
                              .format(selectedDate)),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: startHour,
                              decoration: const InputDecoration(
                                  labelText: 'Start Hour'),
                              items: [
                                for (int h = 8; h <= 20; h++)
                                  DropdownMenuItem(
                                      value: h, child: Text('$h:00')),
                              ],
                              onChanged: (value) => setDialogState(
                                  () => startHour = value ?? startHour),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: endHour,
                              decoration:
                                  const InputDecoration(labelText: 'End Hour'),
                              items: [
                                for (int h = 9; h <= 22; h++)
                                  DropdownMenuItem(
                                      value: h, child: Text('$h:00')),
                              ],
                              onChanged: (value) => setDialogState(
                                  () => endHour = value ?? endHour),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                          'Services kept: ${booking.services.map((s) => s.name).join(', ')}'),
                      const SizedBox(height: 8),
                      Text('New total: RM ${total.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              actions: [
                Tooltip(
                  message: 'Cancel without saving',
                  child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                ),
                Tooltip(
                  message: 'Save booking changes',
                  child: FilledButton(
                    onPressed: () {
                      if (startHour >= endHour) {
                        setDialogState(() =>
                            dialogError = 'Start hour must be before end hour');
                        return;
                      }
                      final capacityValidation =
                          ValidationService.validateCapacity(
                              selectedHall?.capacity);
                      if (capacityValidation != null) {
                        setDialogState(() => dialogError = capacityValidation);
                        return;
                      }
                      Navigator.pop(context, true);
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || selectedHall == null) {
      return;
    }

    final durationFactor = ((endHour - startHour).clamp(1, 24)) / 4;
    final serviceTotal = booking.services
        .fold<double>(0, (sum, service) => sum + service.unitPrice);
    final subtotal = selectedHall!.basePrice * durationFactor;
    final tax = (subtotal + serviceTotal) * 0.06;
    final total = subtotal + serviceTotal + tax;

    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);
      await bookingRepo.updateBooking(
        booking.id,
        hallId: selectedHall!.id,
        date: selectedDate,
        startHour: startHour,
        endHour: endHour,
        finalPrice: total,
      );

      await bookingRepo.logAudit(
        entityType: 'Booking',
        entityId: booking.id,
        action: 'RESCHEDULED_BY_USER',
        actorId: ref.read(currentUserProvider)?.id ?? booking.userId,
        changes:
            'Updated to ${DateFormat('yyyy-MM-dd').format(selectedDate)} $startHour:00-$endHour:00',
      );

      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.invalidate(userBookingsProvider(user.id));
      }
      ref.invalidate(allBookingsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final bookingsAsync = user != null
        ? ref.watch(userBookingsProvider(user.id))
        : const AsyncValue.data(<Booking>[]);

    return AppShellScaffold(
      title: 'My Bookings',
      currentPath: '/booking/my',
      body: bookingsAsync.when(
        data: (bookings) {
          final filteredBookings = _filterBookings(bookings);
          final pendingCount = bookings
              .where((booking) => booking.status == BookingStatus.pending)
              .length;
          final confirmedCount = bookings
              .where((booking) => booking.status == BookingStatus.confirmed)
              .length;
          final completedCount = bookings
              .where((booking) => booking.status == BookingStatus.completed)
              .length;

          if (bookings.isEmpty) {
            return AppEmptyState(
              title: 'No bookings yet',
              description:
                  'Create your first booking to start planning your event.',
              icon: Icons.event_busy_outlined,
              primaryActionLabel: 'Create Booking',
              onPrimaryAction: () => context.go('/booking/new'),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    color: AppTokens.cardSurface,
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note_outlined,
                              color: AppTokens.brand, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Your booking portfolio',
                                style: Theme.of(context).textTheme.titleSmall),
                          ),
                          Text('${bookings.length} total',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: AppTokens.brand)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CountChip(label: 'Pending', value: pendingCount),
                            const SizedBox(width: 8),
                            _CountChip(
                                label: 'Confirmed', value: confirmedCount),
                            const SizedBox(width: 8),
                            _CountChip(
                                label: 'Completed', value: completedCount),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Search my bookings',
                          hintText: 'Hall name or status',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<BookingStatus?>(
                              value: _statusFilter,
                              decoration: const InputDecoration(
                                  labelText: 'Status Filter'),
                              items: [
                                const DropdownMenuItem<BookingStatus?>(
                                  value: null,
                                  child: Text('All Statuses'),
                                ),
                                ...BookingStatus.values.map(
                                  (status) => DropdownMenuItem<BookingStatus?>(
                                    value: status,
                                    child: Text(status.name.toUpperCase()),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _statusFilter = value),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: 'Reset search and status filters',
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _statusFilter = null;
                                });
                              },
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: const Text('Clear'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredBookings.isEmpty)
                const Expanded(
                  child: AppEmptyState(
                    title: 'No bookings match this filter',
                    description:
                        'Try clearing search or changing status filter.',
                    icon: Icons.filter_alt_off,
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      final isClosed =
                          booking.status == BookingStatus.cancelled ||
                              booking.status == BookingStatus.completed;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(booking.hall.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w800)),
                                  ),
                                  _StatusChip(status: booking.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _DetailPill(
                                    icon: Icons.calendar_month_outlined,
                                    label: DateFormat('dd MMM yyyy')
                                        .format(booking.date),
                                  ),
                                  _DetailPill(
                                    icon: Icons.schedule_outlined,
                                    label:
                                        '${booking.startHour}:00-${booking.endHour}:00',
                                  ),
                                  _DetailPill(
                                    icon: Icons.payments_outlined,
                                    label:
                                        'RM ${booking.finalPrice.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              if (!isClosed) ...[
                                const SizedBox(height: AppTokens.s3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _showEditBookingDialog(booking),
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                      label: const Text('Reschedule'),
                                    ),
                                    const SizedBox(width: AppTokens.s2),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTokens.danger,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTokens.s3,
                                          vertical: AppTokens.s2,
                                        ),
                                      ),
                                      onPressed: () => _handleCancel(booking),
                                      icon: const Icon(Icons.cancel_outlined,
                                          size: 18),
                                      label: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const AppLoadingState(label: 'Loading your bookings...'),
        error: (err, stack) => AppErrorState(
          message: 'Error loading bookings: $err',
          onRetry: () {
            if (user != null) {
              ref.invalidate(userBookingsProvider(user.id));
            }
          },
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTokens.brandSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: AppTokens.wBold,
              color: AppTokens.brandInk,
            ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTokens.canvasTint,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTokens.brand),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final intent = switch (status) {
      BookingStatus.confirmed => StatusIntent.success,
      BookingStatus.pending => StatusIntent.warning,
      BookingStatus.cancelled => StatusIntent.danger,
      BookingStatus.completed => StatusIntent.info,
    };
    final colors = AppTokens.statusColors(intent);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s3, vertical: AppTokens.s1 + 2),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.s1 + 2),
          Text(
            status.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.fg,
                  fontWeight: AppTokens.wBold,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTokens.textSecondary,
              fontSize: 12.5,
              fontWeight: AppTokens.wSemibold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTokens.textPrimary,
              fontSize: 13,
              fontWeight: AppTokens.wSemibold,
            ),
          ),
        ),
      ],
    );
  }
}
