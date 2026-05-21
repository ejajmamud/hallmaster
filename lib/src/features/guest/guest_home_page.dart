import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/widgets/async_state_views.dart';
import 'package:hallmaster_enterprise/src/core/widgets/app_shell_scaffold.dart';
import 'package:hallmaster_enterprise/src/core/widgets/hall_photo_frame.dart';

class GuestHomePage extends ConsumerStatefulWidget {
  const GuestHomePage({super.key});

  @override
  ConsumerState<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends ConsumerState<GuestHomePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final hallsAsync = _query.trim().isEmpty
        ? ref.watch(hallsProvider)
        : ref.watch(searchHallsProvider(_query.trim()));
    final hallCount =
        hallsAsync.maybeWhen(data: (halls) => halls.length, orElse: () => null);

    return AppShellScaffold(
      title: 'Browse Halls',
      currentPath: '/guest',
      body: hallsAsync.when(
        data: (halls) {
          if (halls.isEmpty) {
            return AppEmptyState(
              title: 'No halls found',
              description:
                  'Try a different keyword or browse all available halls.',
              icon: Icons.search_off,
              primaryActionLabel: _query.trim().isEmpty ? null : 'Clear Search',
              onPrimaryAction: _query.trim().isEmpty
                  ? null
                  : () => setState(() => _query = ''),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s4,
                    AppTokens.s3,
                    AppTokens.s4,
                    AppTokens.s4,
                  ),
                  child: _GuestHero(
                    hallCount: hallCount,
                    onSignIn: () => context.go('/login'),
                    onQueryChanged: (value) => setState(() => _query = value),
                    onClearQuery: () => setState(() => _query = ''),
                    query: _query,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.s4,
                    0,
                    AppTokens.s4,
                    AppTokens.s2,
                  ),
                  child: _HallShowcaseSlider(halls: halls),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.s4, AppTokens.s3, AppTokens.s4, AppTokens.s2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _query.trim().isEmpty
                              ? 'Available halls'
                              : 'Matches for "${_query.trim()}"',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (hallCount != null)
                        Text(
                          hallCount == 1 ? '1 hall' : '$hallCount halls',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppTokens.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: halls.length,
                itemBuilder: (context, index) {
                  final hall = halls[index];
                  final amenities = hall.amenities.take(3).toList();
                  // "Best value" = highest capacity per RM of base price among
                  // the currently shown halls. Only show the badge when we
                  // can meaningfully rank (>=3 halls) and when the search
                  // query is empty (so it is not misleading while filtering).
                  final bestValueId = _query.trim().isEmpty && halls.length >= 3
                      ? _bestValueHallId(halls)
                      : null;
                  final isBestValue = hall.id == bestValueId;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Tooltip(
                      message:
                          'View ${hall.name} and sign in to request booking',
                      child: Card(
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusMd),
                          onTap: () => context.go('/login'),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HallPhotoFrame(imageUrls: hall.imageUrls),
                                const SizedBox(height: AppTokens.s3),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(hall.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w800)),
                                    ),
                                    if (isBestValue)
                                      Tooltip(
                                        message:
                                            'Highest capacity per RM among halls currently shown',
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: AppTokens.s3,
                                              vertical: AppTokens.s1 + 1),
                                          decoration: BoxDecoration(
                                            color: AppTokens.successSurface,
                                            borderRadius: BorderRadius.circular(
                                                AppTokens.radiusPill),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.verified_outlined,
                                                  size: 12,
                                                  color: AppTokens
                                                      .onSuccessSurface),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Best value',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: AppTokens
                                                          .onSuccessSurface,
                                                      fontWeight:
                                                          AppTokens.wBold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hall.location,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: AppTokens.textSecondary),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _InfoPill(
                                      icon: Icons.groups_2_outlined,
                                      label: '${hall.capacity} guests',
                                    ),
                                    ...amenities.map((amenity) => _InfoPill(
                                          icon: Icons.check_circle_outline,
                                          label: amenity,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'from RM ${hall.basePrice.toStringAsFixed(0)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w800),
                                          ),
                                          Text(
                                            'per 4 hours, before add-ons',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 138,
                                      child: FilledButton.tonalIcon(
                                        onPressed: () => context.go('/login'),
                                        icon: const Icon(Icons.arrow_forward,
                                            size: 18),
                                        label: const Text('View rates'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                  child: SizedBox(
                    width: double.infinity,
                    child: Tooltip(
                      message: 'Open sign in page',
                      child: FilledButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In To Request Booking'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingState(label: 'Loading halls...'),
        error: (err, stack) => AppErrorState(
          message: 'Failed to load halls: $err',
          onRetry: () => setState(() {}),
        ),
      ),
    );
  }
}

class _HallShowcaseSlider extends StatefulWidget {
  const _HallShowcaseSlider({required this.halls});

  final List<Hall> halls;

  @override
  State<_HallShowcaseSlider> createState() => _HallShowcaseSliderState();
}

class _HallShowcaseSliderState extends State<_HallShowcaseSlider> {
  int _activeSlide = 0;

  @override
  Widget build(BuildContext context) {
    final slideHalls = widget.halls.take(_hallSlideAssets.length).toList();
    if (slideHalls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            child: PageView.builder(
              itemCount: slideHalls.length,
              onPageChanged: (value) => setState(() => _activeSlide = value),
              itemBuilder: (context, index) => _HallSlide(
                hall: slideHalls[index],
                imageAsset: _hallSlideAssetFor(slideHalls[index], index),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.s2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int index = 0; index < slideHalls.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _activeSlide ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _activeSlide
                      ? AppTokens.brand
                      : AppTokens.borderStrong,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HallSlide extends StatelessWidget {
  const _HallSlide({required this.hall, required this.imageAsset});

  final Hall hall;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(imageAsset, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x08000000), Color(0xC4000000)],
              stops: [0.45, 1],
            ),
          ),
        ),
        Positioned(
          left: AppTokens.s3,
          right: AppTokens.s3,
          bottom: AppTokens.s3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hall.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTokens.textInverse,
                      fontWeight: AppTokens.wExtraBold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${hall.location} | ${hall.capacity} guests',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _hallSlideAssets = [
  'assets/hall_slides/prime_ballroom.jpg',
  'assets/hall_slides/orchid_conference_hall.jpg',
  'assets/hall_slides/zenith_boardroom.jpg',
];

String _hallSlideAssetFor(Hall hall, int index) {
  final hallName = hall.name.toLowerCase();
  if (hall.id == 'h1' || hallName.contains('ballroom')) {
    return _hallSlideAssets[0];
  }
  if (hall.id == 'h2' ||
      hallName.contains('conference') ||
      hallName.contains('orchid')) {
    return _hallSlideAssets[1];
  }
  if (hall.id == 'h3' ||
      hallName.contains('boardroom') ||
      hallName.contains('zenith')) {
    return _hallSlideAssets[2];
  }
  return _hallSlideAssets[index % _hallSlideAssets.length];
}

class _GuestHero extends StatelessWidget {
  const _GuestHero({
    required this.hallCount,
    required this.onSignIn,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.query,
  });

  final int? hallCount;
  final VoidCallback onSignIn;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final String query;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        color: AppTokens.brand,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0B3F9A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HallMaster',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: AppTokens.wSemibold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Public halls',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: AppTokens.wExtraBold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeroBadge(
                  icon: Icons.apartment_outlined,
                  label: hallCount == null ? 'Loading' : '$hallCount halls',
                  variant: _HeroBadgeVariant.accent,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s3),
            Tooltip(
              message: 'Search halls by name or location',
              child: TextField(
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search hall or location',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: onClearQuery,
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear search text',
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s2,
                    vertical: AppTokens.s2,
                  ),
                ),
                onPressed: onSignIn,
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text('Sign in to book'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        color: AppTokens.brandInk,
        border: Border.all(color: AppTokens.brandInk),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTokens.textInverse),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTokens.textInverse,
                  fontWeight: AppTokens.wSemibold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Computes the id of the hall with the best capacity-per-ringgit ratio
/// within the currently displayed list. Safe against zero or negative
/// base prices by clamping the denominator.
String? _bestValueHallId(List<Hall> halls) {
  if (halls.isEmpty) return null;
  String? bestId;
  double bestRatio = -1;
  for (final hall in halls) {
    final ratio = hall.capacity / (hall.basePrice <= 0 ? 1 : hall.basePrice);
    if (ratio > bestRatio) {
      bestRatio = ratio;
      bestId = hall.id;
    }
  }
  return bestId;
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    this.variant = _HeroBadgeVariant.primary,
  });

  final IconData icon;
  final String label;
  final _HeroBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final isAccent = variant == _HeroBadgeVariant.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAccent ? AppTokens.accentSurface : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: isAccent ? AppTokens.accent : const Color(0x26FFFFFF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isAccent ? AppTokens.accentStrong : Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: isAccent ? AppTokens.onAccentSurface : Colors.white,
                  fontWeight: AppTokens.wSemibold,
                ),
          ),
        ],
      ),
    );
  }
}

enum _HeroBadgeVariant { primary, accent }
