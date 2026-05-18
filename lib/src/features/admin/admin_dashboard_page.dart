import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/widgets/async_state_views.dart';
import 'package:hallmaster_enterprise/src/core/widgets/app_shell_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _bookingSearchController = TextEditingController();
  BookingStatus? _bookingStatusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _bookingSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAdminData() {
    ref.invalidate(hallsProvider);
    ref.invalidate(allBookingsProvider);
    ref.invalidate(allUsersProvider);
  }

  Future<void> _handleRefresh() async {
    _refreshAdminData();
    // Give providers a moment to refetch so pull-to-refresh feels responsive.
    await Future<void>.delayed(const Duration(milliseconds: 220));
  }

  List<Booking> _filterBookings(List<Booking> bookings) {
    final query = _bookingSearchController.text.trim().toLowerCase();
    return bookings.where((booking) {
      final matchesStatus = _bookingStatusFilter == null ||
          booking.status == _bookingStatusFilter;
      final matchesQuery = query.isEmpty ||
          booking.hall.name.toLowerCase().contains(query) ||
          booking.userId.toLowerCase().contains(query) ||
          booking.status.name.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  Future<void> _exportBookingsCsv(List<Booking> bookings) async {
    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No booking records to export.')),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(directory.path, 'hallmaster_exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(p.join(exportDir.path, 'bookings_$timestamp.csv'));

      final rows = <String>[
        'booking_id,user_id,hall_name,booking_date,start_hour,end_hour,status,final_price',
      ];

      for (final booking in bookings) {
        rows.add([
          _escapeCsv(booking.id),
          _escapeCsv(booking.userId),
          _escapeCsv(booking.hall.name),
          _escapeCsv(DateFormat('yyyy-MM-dd').format(booking.date)),
          booking.startHour,
          booking.endHour,
          _escapeCsv(booking.status.name),
          booking.finalPrice.toStringAsFixed(2),
        ].join(','));
      }

      await file.writeAsString(rows.join('\n'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<void> _showHallDialog({Hall? hall}) async {
    final nameController = TextEditingController(text: hall?.name ?? '');
    final locationController =
        TextEditingController(text: hall?.location ?? '');
    final capacityController =
        TextEditingController(text: hall != null ? '${hall.capacity}' : '');
    final basePriceController =
        TextEditingController(text: hall != null ? '${hall.basePrice}' : '');
    final amenitiesController =
        TextEditingController(text: hall?.amenities.join(', ') ?? '');
    final formKey = GlobalKey<FormState>();

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(hall == null ? 'Add Hall' : 'Edit Hall'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Hall Name'),
                      validator: ValidationService.validateHallName,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Location is required'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: capacityController,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        return ValidationService.validateCapacity(parsed);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: basePriceController,
                      decoration: const InputDecoration(
                          labelText: 'Base Price (RM / 4 hours)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        return ValidationService.validatePrice(parsed);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: amenitiesController,
                      decoration: const InputDecoration(
                        labelText: 'Amenities (comma separated)',
                        hintText: 'Wi-Fi, Stage, Parking',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Tooltip(
              message: 'Close without saving',
              child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
            ),
            Tooltip(
              message: hall == null ? 'Create hall' : 'Update hall',
              child: FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text(hall == null ? 'Create' : 'Update'),
              ),
            ),
          ],
        );
      },
    );

    if (submit != true) {
      nameController.dispose();
      locationController.dispose();
      capacityController.dispose();
      basePriceController.dispose();
      amenitiesController.dispose();
      return;
    }

    try {
      final hallRepository = ref.read(hallRepositoryProvider);
      final amenities = amenitiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (hall == null) {
        const uuid = Uuid();
        await hallRepository.createHall(
          id: uuid.v4(),
          name: nameController.text.trim(),
          location: locationController.text.trim(),
          capacity: int.parse(capacityController.text.trim()),
          basePrice: double.parse(basePriceController.text.trim()),
          amenities: amenities,
        );
      } else {
        await hallRepository.updateHall(
          hall.id,
          name: nameController.text.trim(),
          location: locationController.text.trim(),
          capacity: int.parse(capacityController.text.trim()),
          basePrice: double.parse(basePriceController.text.trim()),
          amenities: amenities,
        );
      }

      _refreshAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(hall == null
                ? 'Hall created successfully'
                : 'Hall updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save hall: $e')),
      );
    } finally {
      nameController.dispose();
      locationController.dispose();
      capacityController.dispose();
      basePriceController.dispose();
      amenitiesController.dispose();
    }
  }

  Future<void> _deleteHall(Hall hall) async {
    final hallRepository = ref.read(hallRepositoryProvider);

    // Pre-flight check: reject delete early if active bookings exist,
    // so admins never get prompted to confirm a destructive action that
    // we already know will fail.
    bool hasActive;
    try {
      hasActive = await hallRepository.hasActiveBookings(hall.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not verify hall status: $e')),
      );
      return;
    }

    if (!mounted) return;

    if (hasActive) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.block_outlined,
              size: 32, color: AppTokens.warning),
          title: const Text('Hall cannot be deleted'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hall.name} has active bookings.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTokens.textPrimary,
                      fontWeight: AppTokens.wSemibold,
                    ),
              ),
              const SizedBox(height: AppTokens.s2),
              const Text(
                'Cancel or complete all active bookings for this hall before deleting it. Deleting a hall with live bookings would leave users with orphaned reservations.',
                style: TextStyle(
                  color: AppTokens.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.delete_forever_outlined,
                size: 32, color: AppTokens.danger),
            title: const Text('Delete hall?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hall.name} in ${hall.location} will be permanently removed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.textPrimary,
                      ),
                ),
                const SizedBox(height: AppTokens.s2),
                const Text(
                  'This cannot be undone. Audit logs and historical bookings will be preserved.',
                  style: TextStyle(
                    color: AppTokens.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Hall'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.danger,
                  foregroundColor: AppTokens.textInverse,
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Hall'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await hallRepository.deleteHall(hall.id);
      _refreshAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${hall.name} deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _updateBookingStatus(
      Booking booking, BookingStatus newStatus) async {
    try {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.setBookingStatus(
        booking.id,
        newStatus,
        reason:
            newStatus == BookingStatus.cancelled ? 'Cancelled by admin' : null,
      );

      await repository.logAudit(
        entityType: 'Booking',
        entityId: booking.id,
        action: 'STATUS_${newStatus.name.toUpperCase()}',
        actorId: ref.read(currentUserProvider)?.id ?? 'admin',
        changes: 'Status changed to ${newStatus.name}',
      );

      _refreshAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Booking updated to ${newStatus.name.toUpperCase()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: $e')),
      );
    }
  }

  Future<void> _deleteBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.delete_forever_outlined,
                size: 32, color: AppTokens.danger),
            title: const Text('Delete booking record?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.hall.name} — ${DateFormat('dd MMM yyyy').format(booking.date)}, ${booking.startHour}:00–${booking.endHour}:00',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.textPrimary,
                        fontWeight: AppTokens.wSemibold,
                      ),
                ),
                const SizedBox(height: AppTokens.s2),
                const Text(
                  'Prefer "Cancel booking" where possible — that preserves audit trail. Use delete only for duplicates or test records.',
                  style: TextStyle(
                    color: AppTokens.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep Record'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.danger,
                  foregroundColor: AppTokens.textInverse,
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete Record'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.deleteBooking(booking.id);
      _refreshAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete booking: $e')),
      );
    }
  }

  Future<void> _showAdminEditBookingDialog(Booking booking) async {
    final halls = await ref.read(hallsProvider.future);

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
            final currentPrice =
                selectedHall?.basePrice ?? booking.hall.basePrice;
            final durationFactor = ((endHour - startHour).clamp(1, 24)) / 4;
            final serviceTotal = booking.services
                .fold<double>(0, (sum, item) => sum + item.unitPrice);
            final subtotal = currentPrice * durationFactor;
            final tax = (subtotal + serviceTotal) * 0.06;
            final total = subtotal + serviceTotal + tax;

            return AlertDialog(
              title: const Text('Edit Booking'),
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
                              (hall) => DropdownMenuItem(
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
                      ListTile(
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
                          'Services: ${booking.services.map((s) => s.name).join(', ')}'),
                      const SizedBox(height: 8),
                      Text('Updated total: RM ${total.toStringAsFixed(2)}'),
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
    final serviceTotal =
        booking.services.fold<double>(0, (sum, item) => sum + item.unitPrice);
    final subtotal = selectedHall!.basePrice * durationFactor;
    final tax = (subtotal + serviceTotal) * 0.06;
    final total = subtotal + serviceTotal + tax;

    try {
      final repository = ref.read(bookingRepositoryProvider);
      await repository.updateBooking(
        booking.id,
        hallId: selectedHall!.id,
        date: selectedDate,
        startHour: startHour,
        endHour: endHour,
        finalPrice: total,
      );

      await repository.logAudit(
        entityType: 'Booking',
        entityId: booking.id,
        action: 'RESCHEDULED_BY_ADMIN',
        actorId: ref.read(currentUserProvider)?.id ?? 'admin',
        changes:
            'Updated to ${DateFormat('yyyy-MM-dd').format(selectedDate)} $startHour:00-$endHour:00',
      );

      _refreshAdminData();
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
    final hallsAsync = ref.watch(hallsProvider);
    final bookingsAsync = ref.watch(allBookingsProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return AppShellScaffold(
      title: 'Admin Dashboard',
      currentPath: '/admin',
      body: Padding(
        padding: AppTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hallsAsync.when(
                      data: (halls) => bookingsAsync.when(
                        data: (bookings) => usersAsync.when(
                          data: (users) {
                            final revenue = bookings
                                .where((b) =>
                                    b.status == BookingStatus.confirmed ||
                                    b.status == BookingStatus.completed)
                                .fold<double>(0, (sum, b) => sum + b.finalPrice);
                            final pendingCount = bookings
                                .where((b) => b.status == BookingStatus.pending)
                                .length;

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _MetricCard(
                                    label: 'Halls',
                                    value: halls.length.toString(),
                                    icon: Icons.apartment),
                                _MetricCard(
                                    label: 'Users',
                                    value: users.length.toString(),
                                    icon: Icons.people),
                                _MetricCard(
                                    label: 'Bookings',
                                    value: bookings.length.toString(),
                                    icon: Icons.event_note),
                                _MetricCard(
                                  label: 'Pending Approval',
                                  value: pendingCount.toString(),
                                  icon: Icons.schedule,
                                ),
                                _MetricCard(
                                  label: 'Confirmed Revenue',
                                  value: 'RM ${revenue.toStringAsFixed(2)}',
                                  icon: Icons.payments_outlined,
                                  width: 220,
                                ),
                              ],
                            );
                          },
                          loading: () =>
                              const AppLoadingState(label: 'Loading users...'),
                          error: (err, stack) => AppErrorState(
                            message: 'Failed to load users: $err',
                            onRetry: _refreshAdminData,
                          ),
                        ),
                        loading: () =>
                            const AppLoadingState(label: 'Loading bookings...'),
                        error: (err, stack) => AppErrorState(
                          message: 'Failed to load bookings: $err',
                          onRetry: _refreshAdminData,
                        ),
                      ),
                      loading: () =>
                          const AppLoadingState(label: 'Loading halls...'),
                      error: (err, stack) => AppErrorState(
                        message: 'Failed to load halls: $err',
                        onRetry: _refreshAdminData,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s4, vertical: AppTokens.s3),
                      decoration: BoxDecoration(
                        color: AppTokens.brandSurface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: AppTokens.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune,
                              color: AppTokens.brand, size: 18),
                          const SizedBox(width: AppTokens.s2),
                          Expanded(
                            child: Text(
                              'Control center',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Tooltip(
                            message: 'Refresh dashboard data',
                            child: OutlinedButton.icon(
                              onPressed: _refreshAdminData,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Refresh'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Bookings', icon: Icon(Icons.event_note_outlined)),
                Tab(text: 'Halls', icon: Icon(Icons.apartment_outlined)),
                Tab(text: 'Users', icon: Icon(Icons.people_outline)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 6,
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    bookingsAsync.when(
                      data: (bookings) {
                        final filteredBookings = _filterBookings(bookings);

                        if (bookings.isEmpty) {
                          return const AppEmptyState(
                            title: 'No booking records',
                            description:
                                'Bookings will appear here once users start creating reservations.',
                            icon: Icons.event_busy_outlined,
                          );
                        }
                        return Column(
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                _bookingSearchController,
                                            onChanged: (_) => setState(() {}),
                                            decoration: const InputDecoration(
                                              labelText: 'Search bookings',
                                              hintText:
                                                  'Hall, user id, or status',
                                              prefixIcon: Icon(Icons.search),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: DropdownButtonFormField<
                                              BookingStatus?>(
                                            value: _bookingStatusFilter,
                                            decoration: const InputDecoration(
                                                labelText: 'Status Filter'),
                                            items: [
                                              const DropdownMenuItem<
                                                  BookingStatus?>(
                                                value: null,
                                                child: Text('All Statuses'),
                                              ),
                                              ...BookingStatus.values.map(
                                                (status) => DropdownMenuItem<
                                                    BookingStatus?>(
                                                  value: status,
                                                  child: Text(status.name
                                                      .toUpperCase()),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) => setState(() =>
                                                _bookingStatusFilter = value),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Tooltip(
                                          message: 'Reset booking filters',
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _bookingSearchController
                                                    .clear();
                                                _bookingStatusFilter = null;
                                              });
                                            },
                                            icon: const Icon(
                                                Icons.filter_alt_off_outlined),
                                            label: const Text('Clear Filters'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Tooltip(
                                          message:
                                              'Export filtered bookings as CSV',
                                          child: FilledButton.icon(
                                            onPressed: () => _exportBookingsCsv(
                                                filteredBookings),
                                            icon: const Icon(
                                                Icons.download_outlined),
                                            label: const Text('Export CSV'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (filteredBookings.isEmpty)
                              const Expanded(
                                child: AppEmptyState(
                                  title: 'No matches for current filters',
                                  description:
                                      'Try adjusting status filter or search keywords.',
                                  icon: Icons.filter_alt_off,
                                ),
                              )
                            else
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredBookings.length,
                                  itemBuilder: (context, index) {
                                    final booking = filteredBookings[index];
                                    return Card(
                                      child: ListTile(
                                        onTap: () =>
                                            _showAdminEditBookingDialog(
                                                booking),
                                        title: Text(booking.hall.name),
                                        subtitle: Text(
                                          '${DateFormat('dd MMM yyyy').format(booking.date)} | '
                                          '${booking.startHour}:00-${booking.endHour}:00\n'
                                          'User: ${booking.userId}',
                                        ),
                                        isThreeLine: true,
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                                'RM ${booking.finalPrice.toStringAsFixed(2)}'),
                                            const SizedBox(height: 6),
                                            PopupMenuButton<String>(
                                              tooltip: 'Booking actions',
                                              icon: const Icon(
                                                  Icons.more_horiz_rounded),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _showAdminEditBookingDialog(
                                                      booking);
                                                  return;
                                                }
                                                if (value == 'delete') {
                                                  _deleteBooking(booking);
                                                  return;
                                                }
                                                final status = BookingStatus
                                                    .values
                                                    .firstWhere(
                                                        (s) => s.name == value);
                                                _updateBookingStatus(
                                                    booking, status);
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: _MenuRow(
                                                    icon: Icons.edit_outlined,
                                                    label:
                                                        'Reschedule / Edit',
                                                  ),
                                                ),
                                                const PopupMenuDivider(),
                                                const PopupMenuItem<String>(
                                                  value: 'pending',
                                                  child: _MenuRow(
                                                    icon: Icons
                                                        .hourglass_empty_rounded,
                                                    label: 'Mark Pending',
                                                  ),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'confirmed',
                                                  child: _MenuRow(
                                                    icon:
                                                        Icons.check_circle_outline,
                                                    label: 'Mark Confirmed',
                                                  ),
                                                ),
                                                const PopupMenuItem<String>(
                                                  value: 'completed',
                                                  child: _MenuRow(
                                                    icon: Icons.flag_outlined,
                                                    label: 'Mark Completed',
                                                  ),
                                                ),
                                                const PopupMenuDivider(),
                                                PopupMenuItem<String>(
                                                  value: 'cancelled',
                                                  child: _MenuRow(
                                                    icon:
                                                        Icons.cancel_outlined,
                                                    label: 'Cancel Booking',
                                                    color: AppTokens.warning,
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: _MenuRow(
                                                    icon: Icons
                                                        .delete_forever_outlined,
                                                    label: 'Delete Record',
                                                    color: AppTokens.danger,
                                                  ),
                                                ),
                                              ],
                                            ),
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
                      loading: () => const AppLoadingState(
                          label: 'Loading booking records...'),
                      error: (err, stack) => AppErrorState(
                        message: 'Failed to load bookings: $err',
                        onRetry: _refreshAdminData,
                      ),
                    ),
                    hallsAsync.when(
                      data: (halls) {
                        return Column(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  Tooltip(
                                    message: 'Refresh hall list',
                                    child: OutlinedButton.icon(
                                      onPressed: _refreshAdminData,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Refresh'),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Create a new hall',
                                    child: FilledButton.icon(
                                      onPressed: () => _showHallDialog(),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Hall'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: halls.isEmpty
                                  ? const AppEmptyState(
                                      title: 'No halls available',
                                      description:
                                          'Create your first hall to start accepting bookings.',
                                      icon: Icons.apartment_outlined,
                                    )
                                  : ListView.builder(
                                      itemCount: halls.length,
                                      itemBuilder: (context, index) {
                                        final hall = halls[index];
                                        return Card(
                                          child: ListTile(
                                            title: Text(hall.name),
                                            subtitle: Text(
                                              '${hall.location} | Capacity: ${hall.capacity}\n'
                                              'RM ${hall.basePrice.toStringAsFixed(2)} / 4 hours',
                                            ),
                                            isThreeLine: true,
                                            trailing: Wrap(
                                              spacing: 4,
                                              children: [
                                                IconButton(
                                                  onPressed: () =>
                                                      _showHallDialog(
                                                          hall: hall),
                                                  icon: const Icon(
                                                      Icons.edit_outlined),
                                                  tooltip: 'Edit hall',
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      _deleteHall(hall),
                                                  icon: const Icon(
                                                      Icons.delete_outline),
                                                  tooltip: 'Delete hall',
                                                ),
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
                      loading: () =>
                          const AppLoadingState(label: 'Loading halls...'),
                      error: (err, stack) => AppErrorState(
                        message: 'Failed to load halls: $err',
                        onRetry: _refreshAdminData,
                      ),
                    ),
                    usersAsync.when(
                      data: (users) => users.isEmpty
                          ? const AppEmptyState(
                              title: 'No users registered',
                              description:
                                  'Users will appear here after registration or seeded demo login.',
                              icon: Icons.people_outline,
                            )
                          : ListView.builder(
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?'),
                                    ),
                                    title: Text(user.name),
                                    subtitle: Text(
                                        '${user.email}\nRole: ${user.role.name.toUpperCase()}'),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                      loading: () =>
                          const AppLoadingState(label: 'Loading users...'),
                      error: (err, stack) => AppErrorState(
                        message: 'Failed to load users: $err',
                        onRetry: _refreshAdminData,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.width = 160,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On compact parents, let the card flex to parent width so metric
        // tiles stack cleanly instead of overflowing horizontally.
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final effectiveWidth = width > maxWidth ? maxWidth : width;

        return SizedBox(
          width: effectiveWidth,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.s4),
            decoration: BoxDecoration(
              color: AppTokens.cardSurface,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: AppTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTokens.brandSurface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: AppTokens.brand),
                ),
                const SizedBox(height: AppTokens.s3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: AppTokens.wExtraBold),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppTokens.textPrimary;
    return Row(
      children: [
        Icon(icon, size: 18, color: tone),
        const SizedBox(width: AppTokens.s2 + 2),
        Text(
          label,
          style: TextStyle(
            color: tone,
            fontWeight: AppTokens.wSemibold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
