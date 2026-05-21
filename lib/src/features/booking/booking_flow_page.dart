import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/widgets/async_state_views.dart';
import 'package:hallmaster_enterprise/src/core/widgets/app_shell_scaffold.dart';
import 'package:intl/intl.dart';

class BookingFlowPage extends ConsumerStatefulWidget {
  const BookingFlowPage({super.key});

  @override
  ConsumerState<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends ConsumerState<BookingFlowPage> {
  final _formKey = GlobalKey<FormState>();
  Hall? selectedHall;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  int startHour = 10;
  int endHour = 14;
  final selectedServices = <String>{};
  bool _isLoading = false;
  String? _validationError;

  @override
  Widget build(BuildContext context) {
    final hallsAsync = ref.watch(hallsProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final user = ref.watch(currentUserProvider);

    return AppShellScaffold(
      title: 'Create Booking',
      currentPath: '/booking/new',
      body: hallsAsync.when(
        data: (halls) {
          if (halls.isEmpty) {
            return const AppEmptyState(
              title: 'No halls available',
              description:
                  'Admin needs to add halls before bookings can be created.',
              icon: Icons.apartment_outlined,
            );
          }

          selectedHall ??= halls.isNotEmpty ? halls.first : null;

          return servicesAsync.when(
            data: (services) => _buildForm(halls, services, user),
            loading: () =>
                const AppLoadingState(label: 'Loading service options...'),
            error: (err, stack) => AppErrorState(
                message: 'Error loading services: $err',
                onRetry: () => setState(() {})),
          );
        },
        loading: () => const AppLoadingState(label: 'Loading halls...'),
        error: (err, stack) => AppErrorState(
            message: 'Error loading halls: $err',
            onRetry: () => setState(() {})),
      ),
    );
  }

  Widget _buildForm(
      List<Hall> halls, List<AddOnService> services, AppUser? user) {
    final chosen =
        services.where((s) => selectedServices.contains(s.id)).toList();
    final subtotal = (selectedHall?.basePrice ?? 0) *
        ((endHour - startHour).clamp(1, 24) / 4);
    final serviceTotal = chosen.fold<double>(0, (sum, s) => sum + s.unitPrice);
    final tax = (subtotal + serviceTotal) * 0.06;
    final total = subtotal + serviceTotal + tax;

    // Live availability probe — surfaces conflicts before submit.
    final availabilityAsync = (selectedHall != null && endHour > startHour)
        ? ref.watch(checkDoubleBookingProvider(
            (selectedHall!.id, selectedDate, startHour, endHour),
          ))
        : const AsyncValue<bool>.data(true);

    return Form(
      key: _formKey,
      child: ListView(
        padding: AppTokens.pagePadding,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
                AppTokens.s4, AppTokens.s4, AppTokens.s4, AppTokens.s3 + 2),
            decoration: BoxDecoration(
              color: AppTokens.brandSurface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: AppTokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available_outlined,
                        size: 18, color: AppTokens.brand),
                    const SizedBox(width: AppTokens.s2),
                    Text(
                      'New booking',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppTokens.brand),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s2),
                Text(
                  'Reserve a venue',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pricing updates instantly. Bookings stay pending until admin approval.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.s3),
          if (_validationError != null)
            AppInlineMessage.error(message: _validationError!),
          if (_validationError != null) const SizedBox(height: AppTokens.s3),
          _AvailabilityBanner(availability: availabilityAsync),
          const SizedBox(height: AppTokens.s3),
          Card(
            child: Padding(
              padding: AppTokens.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BookingSectionTitle(
                    icon: Icons.apartment_outlined,
                    title: 'Property and schedule',
                    subtitle: 'Choose where and when your event happens',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Hall>(
                    value: selectedHall,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Select Hall'),
                    validator: (value) =>
                        value == null ? 'Please select a hall' : null,
                    items: [
                      for (final hall in halls)
                        DropdownMenuItem(
                          value: hall,
                          child:
                              Text(hall.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) => setState(() => selectedHall = value),
                  ),
                  const SizedBox(height: 10),
                  Tooltip(
                    message: 'Select event date',
                    child: Material(
                      color: AppTokens.canvasTint,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                        onTap: () async {
                          final today = DateTime.now();
                          final startOfToday =
                              DateTime(today.year, today.month, today.day);
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate.isBefore(startOfToday)
                                ? startOfToday
                                : selectedDate,
                            firstDate: startOfToday,
                            lastDate:
                                startOfToday.add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.s3 + 2,
                              vertical: AppTokens.s3),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: AppTokens.brand, size: 18),
                              const SizedBox(width: AppTokens.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Event date',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                    Text(
                                      DateFormat('EEE, dd MMM yyyy')
                                          .format(selectedDate),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppTokens.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: startHour,
                          decoration:
                              const InputDecoration(labelText: 'Start Hour'),
                          items: [
                            for (int h = 8; h <= 20; h++)
                              DropdownMenuItem(value: h, child: Text('$h:00'))
                          ],
                          onChanged: (v) => setState(() => startHour = v ?? 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: endHour,
                          decoration:
                              const InputDecoration(labelText: 'End Hour'),
                          items: [
                            for (int h = 9; h <= 22; h++)
                              DropdownMenuItem(value: h, child: Text('$h:00'))
                          ],
                          onChanged: (v) => setState(() => endHour = v ?? 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: AppTokens.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BookingSectionTitle(
                    icon: Icons.room_service_outlined,
                    title: 'Add-on services',
                    subtitle: 'Select optional services for your event',
                  ),
                  const SizedBox(height: 8),
                  for (final service in services)
                    CheckboxListTile(
                      value: selectedServices.contains(service.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(service.name),
                      subtitle:
                          Text('RM ${service.unitPrice.toStringAsFixed(0)}'),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedServices.add(service.id);
                          } else {
                            selectedServices.remove(service.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: AppTokens.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BookingSectionTitle(
                    icon: Icons.receipt_long_outlined,
                    title: 'Price summary',
                    subtitle: 'Transparent pricing before confirmation',
                  ),
                  const SizedBox(height: 10),
                  _PriceLine(
                      label: 'Venue subtotal',
                      value: 'RM ${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _PriceLine(
                      label: 'Service add-ons',
                      value: 'RM ${serviceTotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _PriceLine(
                      label: 'Tax (6%)', value: 'RM ${tax.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _PriceLine(
                    label: 'Grand total',
                    value: 'RM ${total.toStringAsFixed(2)}',
                    emphasized: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your booking remains pending until admin approval.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTokens.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.s3),
          Tooltip(
            message: availabilityAsync.value == false
                ? 'This slot is already booked'
                : 'Submit booking request',
            child: FilledButton.icon(
              onPressed: (_isLoading || availabilityAsync.value == false)
                  ? null
                  : () => _handleBooking(user, total),
              icon: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTokens.textInverse,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(_isLoading ? 'Submitting...' : 'Confirm Booking'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking(AppUser? user, double total) async {
    if (user == null || user.role == UserRole.guest || selectedHall == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in as a user to book')),
      );
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (startHour >= endHour) {
      setState(() => _validationError = 'Start hour must be before end hour');
      return;
    }

    // Compare by calendar day, not by instant — otherwise same-day
    // bookings would be rejected as "past" later in the day.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    if (picked.isBefore(today)) {
      setState(() => _validationError = 'Cannot book for past dates');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bookingRepo = ref.read(bookingRepositoryProvider);

      // Check for double booking
      final available = await bookingRepo.isHallAvailable(
        selectedHall!.id,
        selectedDate,
        startHour,
        endHour,
      );

      if (!available) {
        setState(() => _validationError =
            'This time slot is already booked. Please select another time.');
        return;
      }

      final bookingId = await bookingRepo.createBooking(
        userId: user.id,
        hallId: selectedHall!.id,
        date: selectedDate,
        startHour: startHour,
        endHour: endHour,
        serviceIds: selectedServices.toList(),
        finalPrice: total,
      );

      // Log audit
      await bookingRepo.logAudit(
        entityType: 'Booking',
        entityId: bookingId,
        action: 'CREATED',
        actorId: user.id,
        changes: 'New booking created',
      );

      if (!mounted) return;
      ref.invalidate(userBookingsProvider(user.id));
      ref.invalidate(allBookingsProvider);
      ref.invalidate(checkDoubleBookingProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Booking submitted and pending admin approval.')),
      );
      context.go('/booking/my');
    } catch (e) {
      setState(() => _validationError = 'Error creating booking: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _BookingSectionTitle extends StatelessWidget {
  const _BookingSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTokens.brandSurface,
            borderRadius: BorderRadius.circular(AppTokens.radiusXs + 1),
          ),
          child: Icon(icon, size: 18, color: AppTokens.brand),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTokens.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  const _AvailabilityBanner({required this.availability});

  final AsyncValue<bool> availability;

  @override
  Widget build(BuildContext context) {
    return availability.when(
      data: (isAvailable) {
        final intent = isAvailable ? StatusIntent.success : StatusIntent.danger;
        final colors = AppTokens.statusColors(intent);
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s3 + 2, vertical: AppTokens.s3),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(color: AppTokens.border),
          ),
          child: Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle_outline : Icons.error_outline,
                color: colors.fg,
                size: 20,
              ),
              const SizedBox(width: AppTokens.s2 + 2),
              Expanded(
                child: Text(
                  isAvailable
                      ? 'This slot is available.'
                      : 'This slot conflicts with an existing booking. Pick another time.',
                  style: TextStyle(
                    color: colors.fg,
                    fontWeight: AppTokens.wSemibold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s3 + 2, vertical: AppTokens.s3),
        decoration: BoxDecoration(
          color: AppTokens.canvasTint,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          border: Border.all(color: AppTokens.border),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTokens.textSecondary,
              ),
            ),
            SizedBox(width: AppTokens.s2 + 2),
            Expanded(
              child: Text(
                'Checking availability...',
                style: TextStyle(
                  color: AppTokens.textSecondary,
                  fontWeight: AppTokens.wSemibold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
