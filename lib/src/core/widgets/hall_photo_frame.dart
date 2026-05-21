import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';

class HallPhotoFrame extends StatefulWidget {
  const HallPhotoFrame({
    super.key,
    required this.imageUrls,
    this.borderRadius = AppTokens.radiusMd,
    this.compact = false,
  });

  final List<String> imageUrls;
  final double borderRadius;
  final bool compact;

  @override
  State<HallPhotoFrame> createState() => _HallPhotoFrameState();
}

class _HallPhotoFrameState extends State<HallPhotoFrame> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final urls =
        widget.imageUrls.where((url) => url.trim().isNotEmpty).toList();

    return AspectRatio(
      aspectRatio: widget.compact ? 4 / 3 : 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (urls.isEmpty)
              const _MissingHallPhoto()
            else
              PageView.builder(
                itemCount: urls.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => _HallPhoto(url: urls[index]),
              ),
            if (urls.length > 1)
              Positioned(
                right: AppTokens.s2,
                bottom: AppTokens.s2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s2,
                    vertical: AppTokens.s1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB3000000),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                  child: Text(
                    '${_index + 1}/${urls.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: AppTokens.wBold,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HallPhoto extends StatelessWidget {
  const _HallPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('data:image/')) {
      final marker = url.indexOf(',');
      if (marker > 0) {
        try {
          return Image.memory(
            base64Decode(url.substring(marker + 1)),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const _MissingHallPhoto(),
          );
        } catch (_) {
          return const _MissingHallPhoto();
        }
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => const _MissingHallPhoto(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _PhotoLoadingFrame(),
    );
  }
}

class _PhotoLoadingFrame extends StatelessWidget {
  const _PhotoLoadingFrame();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTokens.canvasTint,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _MissingHallPhoto extends StatelessWidget {
  const _MissingHallPhoto();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/hall_fallback.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.center,
    );
  }
}
