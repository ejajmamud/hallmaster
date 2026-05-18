import 'package:flutter/material.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.label = 'Loading…',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: AppTokens.s3),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Something went wrong',
  });

  final String message;
  final String title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final pair = AppTokens.statusColors(StatusIntent.danger);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: AppTokens.cardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: pair.bg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: pair.fg,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppTokens.s3),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.s2),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppTokens.s4),
                  Tooltip(
                    message: 'Retry this request',
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.primaryActionLabel,
    this.onPrimaryAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: AppTokens.cardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTokens.brandSurface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(icon, color: AppTokens.brand, size: 24),
                ),
                const SizedBox(height: AppTokens.s3),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.s2),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTokens.textSecondary),
                ),
                if (primaryActionLabel != null && onPrimaryAction != null) ...[
                  const SizedBox(height: AppTokens.s4),
                  Tooltip(
                    message: primaryActionLabel!,
                    child: FilledButton(
                      onPressed: onPrimaryAction,
                      child: Text(primaryActionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppInlineMessage extends StatelessWidget {
  const AppInlineMessage._({
    required this.message,
    required this.background,
    required this.borderColor,
    required this.foreground,
    required this.icon,
  });

  factory AppInlineMessage.error({required String message}) {
    const pair = ColorPair(
        bg: AppTokens.dangerSurface, fg: AppTokens.onDangerSurface);
    return AppInlineMessage._(
      message: message,
      background: pair.bg,
      borderColor: AppTokens.danger,
      foreground: pair.fg,
      icon: Icons.error_outline,
    );
  }

  factory AppInlineMessage.warning({required String message}) {
    const pair = ColorPair(
        bg: AppTokens.warningSurface, fg: AppTokens.onWarningSurface);
    return AppInlineMessage._(
      message: message,
      background: pair.bg,
      borderColor: AppTokens.warning,
      foreground: pair.fg,
      icon: Icons.warning_amber_rounded,
    );
  }

  factory AppInlineMessage.success({required String message}) {
    const pair = ColorPair(
        bg: AppTokens.successSurface, fg: AppTokens.onSuccessSurface);
    return AppInlineMessage._(
      message: message,
      background: pair.bg,
      borderColor: AppTokens.success,
      foreground: pair.fg,
      icon: Icons.check_circle_outline,
    );
  }

  final String message;
  final Color background;
  final Color borderColor;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s3, vertical: AppTokens.s2 + 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppTokens.s2),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foreground,
                fontWeight: AppTokens.wSemibold,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
