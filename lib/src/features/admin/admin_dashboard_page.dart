import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/widgets/async_state_views.dart';
import 'package:hallmaster_enterprise/src/core/widgets/app_shell_scaffold.dart';
import 'package:hallmaster_enterprise/src/core/widgets/hall_photo_frame.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({
    super.key,
    this.initialTabIndex = 0,
    this.currentPath = '/admin',
  });

  final int initialTabIndex;
  final String currentPath;

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
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
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

  void _openAdminTab(int index, {BookingStatus? statusFilter}) {
    setState(() {
      _bookingSearchController.clear();
      _bookingStatusFilter = statusFilter;
    });
    _tabController.animateTo(index);
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
    final hallId = hall?.id ?? const Uuid().v4();
    var services = await ref.read(servicesProvider.future);
    if (!mounted) return;
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
    final existingImageUrls = [...?hall?.imageUrls];
    final selectedAddOns = <String>{...?hall?.addOnServiceIds};
    final newPhotos = <XFile>[];

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(hall == null ? 'Add Hall' : 'Edit Hall'),
            content: SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HallPhotoFrame(imageUrls: existingImageUrls),
                      const SizedBox(height: AppTokens.s2),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final photo = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 1800,
                                  imageQuality: 82,
                                );
                                if (photo == null) return;
                                setDialogState(() {
                                  newPhotos
                                    ..clear()
                                    ..add(photo);
                                });
                              },
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              label: const Text('Upload Photo'),
                            ),
                          ),
                        ],
                      ),
                      if (newPhotos.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s1),
                        Text(
                          'New photo ready to save',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                      if (existingImageUrls.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s2),
                        Wrap(
                          spacing: AppTokens.s1,
                          runSpacing: AppTokens.s1,
                          children: [
                            for (final url in [...existingImageUrls])
                              InputChip(
                                avatar:
                                    const Icon(Icons.image_outlined, size: 16),
                                label: const Text('Current photo'),
                                onDeleted: () => setDialogState(
                                  () => existingImageUrls.remove(url),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppTokens.s2),
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Hall Name'),
                        validator: ValidationService.validateHallName,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: locationController,
                        decoration:
                            const InputDecoration(labelText: 'Location'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Location is required'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: capacityController,
                        decoration:
                            const InputDecoration(labelText: 'Capacity'),
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
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                      const SizedBox(height: AppTokens.s3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hall Add-ons',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final created = await _showServiceDialog();
                              if (!created || !mounted) return;
                              services =
                                  await ref.read(servicesProvider.future);
                              if (!mounted) return;
                              setDialogState(() {});
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('New'),
                          ),
                        ],
                      ),
                      if (services.isEmpty)
                        const Text('Create add-ons for this hall.')
                      else
                        for (final service in services)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: selectedAddOns.contains(service.id),
                            title: Text(service.name),
                            subtitle: Text(
                                'RM ${service.unitPrice.toStringAsFixed(0)}'),
                            onChanged: (selected) => setDialogState(() {
                              if (selected == true) {
                                selectedAddOns.add(service.id);
                              } else {
                                selectedAddOns.remove(service.id);
                              }
                            }),
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
          ),
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
        final uploadedUrls = await _newHallPhotoUrls(newPhotos);
        final imageUrls =
            uploadedUrls.isEmpty ? existingImageUrls : uploadedUrls;
        if (imageUrls.isEmpty) {
          throw Exception('Upload at least one hall photo');
        }
        await hallRepository.createHall(
          id: hallId,
          name: nameController.text.trim(),
          location: locationController.text.trim(),
          capacity: int.parse(capacityController.text.trim()),
          basePrice: double.parse(basePriceController.text.trim()),
          amenities: amenities,
          imageUrls: imageUrls,
          addOnServiceIds: selectedAddOns.toList(),
        );
      } else {
        final uploadedUrls = await _newHallPhotoUrls(newPhotos);
        final imageUrls =
            uploadedUrls.isEmpty ? existingImageUrls : uploadedUrls;
        if (imageUrls.isEmpty) {
          throw Exception('Keep or upload at least one hall photo');
        }
        await hallRepository.updateHall(
          hall.id,
          name: nameController.text.trim(),
          location: locationController.text.trim(),
          capacity: int.parse(capacityController.text.trim()),
          basePrice: double.parse(basePriceController.text.trim()),
          amenities: amenities,
          imageUrls: imageUrls,
          addOnServiceIds: selectedAddOns.toList(),
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

  Future<List<String>> _newHallPhotoUrls(List<XFile> photos) async {
    if (photos.isEmpty) return const [];

    final photo = photos.last;
    final bytes = await photo.readAsBytes();
    if (bytes.length > 650000) {
      throw Exception('Photo is too large. Choose a smaller image.');
    }

    final lowerName = photo.name.toLowerCase();
    final mimeType = lowerName.endsWith('.png')
        ? 'image/png'
        : lowerName.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    return ['data:$mimeType;base64,${base64Encode(bytes)}'];
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

  Future<bool> _showServiceDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final save = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('New Add-on'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Add-on Name',
                      prefixIcon: Icon(Icons.room_service_outlined),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                            ? 'Enter an add-on name'
                            : null,
                  ),
                  const SizedBox(height: AppTokens.s2),
                  TextFormField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Unit Price (RM)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) => ValidationService.validatePrice(
                      double.tryParse(value ?? ''),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ) ??
        false;

    try {
      if (!save) return false;
      await ref.read(serviceRepositoryProvider).createService(
            id: const Uuid().v4(),
            name: nameController.text.trim(),
            unitPrice: double.parse(priceController.text.trim()),
          );
      ref.invalidate(servicesProvider);
      return true;
    } finally {
      nameController.dispose();
      priceController.dispose();
    }
  }

  Future<void> _showUserDialog({AppUser? user}) async {
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var role = user?.role == UserRole.admin ? UserRole.admin : UserRole.user;

    final save = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(isEdit ? 'Edit User' : 'Add User'),
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
                          maxLength: 80,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: ValidationService.validateName,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppTokens.s2),
                        TextFormField(
                          controller: emailController,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: ValidationService.validateEmail,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppTokens.s2),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.call_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: ValidationService.validatePhone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppTokens.s2),
                        DropdownButtonFormField<UserRole>(
                          value: role,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon:
                                Icon(Icons.admin_panel_settings_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: UserRole.user,
                              child: Text('Standard User'),
                            ),
                            DropdownMenuItem(
                              value: UserRole.admin,
                              child: Text('Administrator'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => role = value);
                          },
                        ),
                        const SizedBox(height: AppTokens.s2),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: isEdit
                                ? 'New Password (optional)'
                                : 'Temporary Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (isEdit && (value == null || value.isEmpty)) {
                              return null;
                            }
                            return ValidationService.validatePassword(value);
                          },
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() == true) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text(isEdit ? 'Save' : 'Create'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!save) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
      return;
    }

    try {
      final repository = ref.read(userRepositoryProvider);
      final email = SecurityService.normalizeEmail(emailController.text);
      final emailOwner = await repository.getUserByEmail(email);
      if (emailOwner != null && emailOwner.id != user?.id) {
        throw Exception('Email is already registered');
      }

      if (isEdit) {
        await repository.updateUser(
          user.id,
          name: nameController.text,
          email: email,
          phone: phoneController.text.trim(),
          role: role,
          password: passwordController.text,
        );

        final currentUser = ref.read(currentUserProvider);
        if (currentUser?.id == user.id) {
          ref.read(currentUserProvider.notifier).state = AppUser(
            id: user.id,
            name: SecurityService.normalizeName(nameController.text),
            email: email,
            role: role,
            phone: phoneController.text.trim(),
          );
        }
      } else {
        await repository.createUser(
          id: const Uuid().v4(),
          name: nameController.text,
          email: email,
          password: passwordController.text,
          phone: phoneController.text.trim(),
          role: role,
        );
      }

      ref.invalidate(allUsersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'User updated.' : 'User created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User save failed: $e')),
      );
    } finally {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    if (ref.read(currentUserProvider)?.id == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.person_remove_outlined,
                size: 32, color: AppTokens.danger),
            title: const Text('Delete user?'),
            content: Text(
              '${user.name} (${user.email}) will be removed. Existing booking records keep their user id for history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep User'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.danger,
                  foregroundColor: AppTokens.textInverse,
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ref.read(userRepositoryProvider).deleteUser(user.id);
      ref.invalidate(allUsersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} deleted.')),
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
      currentPath: widget.currentPath,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.s3,
          AppTokens.s3,
          AppTokens.s3,
          AppTokens.s2,
        ),
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
                    final approvedCount = bookings
                        .where((b) => b.status == BookingStatus.confirmed)
                        .length;
                    final activeCount = bookings
                        .where((b) =>
                            b.status == BookingStatus.pending ||
                            b.status == BookingStatus.confirmed)
                        .length;

                    return _MetricsPanel(
                      onRefresh: _refreshAdminData,
                      metrics: [
                        _MetricData(
                          label: 'Total bookings',
                          value: bookings.length.toString(),
                          icon: Icons.event_note_outlined,
                          intent: StatusIntent.info,
                          onTap: () => _openAdminTab(0),
                        ),
                        _MetricData(
                          label: 'Pending approval',
                          value: pendingCount.toString(),
                          icon: Icons.hourglass_top_rounded,
                          intent: StatusIntent.warning,
                          onTap: () => _openAdminTab(
                            0,
                            statusFilter: BookingStatus.pending,
                          ),
                        ),
                        _MetricData(
                          label: 'Approved',
                          value: approvedCount.toString(),
                          icon: Icons.verified_outlined,
                          intent: StatusIntent.success,
                          onTap: () => _openAdminTab(
                            0,
                            statusFilter: BookingStatus.confirmed,
                          ),
                        ),
                        _MetricData(
                          label: 'Active workflow',
                          value: activeCount.toString(),
                          icon: Icons.bolt_outlined,
                          intent: StatusIntent.info,
                          onTap: () => _openAdminTab(0),
                        ),
                        _MetricData(
                          label: 'Managed halls',
                          value: halls.length.toString(),
                          icon: Icons.apartment_outlined,
                          intent: StatusIntent.info,
                          onTap: () => _openAdminTab(1),
                        ),
                        _MetricData(
                          label: 'Registered users',
                          value: users.length.toString(),
                          icon: Icons.people_outline,
                          intent: StatusIntent.success,
                          onTap: () => _openAdminTab(2),
                        ),
                        _MetricData(
                          label: 'Revenue',
                          value: 'RM ${revenue.toStringAsFixed(0)}',
                          icon: Icons.payments_outlined,
                          intent: StatusIntent.success,
                          onTap: () => _openAdminTab(
                            0,
                            statusFilter: BookingStatus.confirmed,
                          ),
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
              loading: () => const AppLoadingState(label: 'Loading halls...'),
              error: (err, stack) => AppErrorState(
                message: 'Failed to load halls: $err',
                onRetry: _refreshAdminData,
              ),
            ),
            const SizedBox(height: AppTokens.s2),
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
                                          'User: ${booking.userId}  |  RM ${booking.finalPrice.toStringAsFixed(2)}',
                                        ),
                                        isThreeLine: true,
                                        trailing: PopupMenuButton<String>(
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
                                            final status = BookingStatus.values
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
                                                label: 'Reschedule / Edit',
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
                                            const PopupMenuItem<String>(
                                              value: 'cancelled',
                                              child: _MenuRow(
                                                icon: Icons.cancel_outlined,
                                                label: 'Cancel Booking',
                                                color: AppTokens.warning,
                                              ),
                                            ),
                                            const PopupMenuItem<String>(
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
                                            leading: SizedBox(
                                              width: 70,
                                              child: HallPhotoFrame(
                                                imageUrls: hall.imageUrls,
                                                borderRadius:
                                                    AppTokens.radiusSm,
                                                compact: true,
                                              ),
                                            ),
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
                      data: (users) => Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: AppTokens.s2,
                              children: [
                                Tooltip(
                                  message: 'Refresh user list',
                                  child: OutlinedButton.icon(
                                    onPressed: _refreshAdminData,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh'),
                                  ),
                                ),
                                Tooltip(
                                  message: 'Create a user account',
                                  child: FilledButton.icon(
                                    onPressed: _showUserDialog,
                                    icon: const Icon(Icons.person_add_alt),
                                    label: const Text('Add User'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTokens.s2),
                          Expanded(
                            child: users.isEmpty
                                ? const AppEmptyState(
                                    title: 'No users registered',
                                    description:
                                        'Create a user account to start managing bookings.',
                                    icon: Icons.people_outline,
                                  )
                                : ListView.builder(
                                    itemCount: users.length,
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      final phone = user.phone?.trim() ?? '';
                                      return Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            child: Text(user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : '?'),
                                          ),
                                          title: Text(user.name),
                                          subtitle: Text(
                                            '${user.email}\n'
                                            '${user.role == UserRole.admin ? 'Administrator' : 'Standard User'}'
                                            '${phone.isEmpty ? '' : ' | $phone'}',
                                          ),
                                          isThreeLine: true,
                                          trailing: PopupMenuButton<String>(
                                            tooltip: 'User actions',
                                            icon: const Icon(
                                                Icons.more_horiz_rounded),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showUserDialog(user: user);
                                              }
                                              if (value == 'delete') {
                                                _deleteUser(user);
                                              }
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem<String>(
                                                value: 'edit',
                                                child: _MenuRow(
                                                  icon: Icons.edit_outlined,
                                                  label: 'Edit User',
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                value: 'delete',
                                                child: _MenuRow(
                                                  icon: Icons
                                                      .person_remove_outlined,
                                                  label: 'Delete User',
                                                  color: AppTokens.danger,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
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

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.intent,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatusIntent intent;
  final VoidCallback? onTap;
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({
    required this.metrics,
    required this.onRefresh,
  });

  final List<_MetricData> metrics;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppTokens.bpMedium;
        return compact
            ? _buildCompactGrid(context)
            : _buildExpandedGrid(context);
      },
    );
  }

  Widget _buildCompactGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricsHeader(onRefresh: onRefresh),
        const SizedBox(height: AppTokens.s2),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: metrics.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTokens.s2),
            itemBuilder: (context, index) => SizedBox(
              width: 138,
              child: _MetricTile(metric: metrics[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedGrid(BuildContext context) {
    return Column(
      children: [
        _MetricsHeader(onRefresh: onRefresh),
        const SizedBox(height: AppTokens.s2),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100 ? 4 : 3;
            final totalGap = AppTokens.s2 * (columns - 1);
            final columnWidth = (constraints.maxWidth - totalGap) / columns;

            return Wrap(
              spacing: AppTokens.s2,
              runSpacing: AppTokens.s2,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: columnWidth,
                    child: _MetricTile(metric: metric),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetricsHeader extends StatelessWidget {
  const _MetricsHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.admin_panel_settings_outlined,
            color: AppTokens.brand, size: 20),
        const SizedBox(width: AppTokens.s2),
        Expanded(
          child: Text(
            'Admin control center',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: AppTokens.wBold,
                ),
          ),
        ),
        Tooltip(
          message: 'Refresh dashboard data',
          child: IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pair = AppTokens.statusColors(metric.intent);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        onTap: metric.onTap,
        child: Ink(
          height: 86,
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
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: pair.bg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                  child: Icon(metric.icon, size: 17, color: pair.fg),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        height: 1.0,
                        fontWeight: AppTokens.wExtraBold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      metric.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.textSecondary,
                        fontWeight: AppTokens.wSemibold,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppTokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
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
