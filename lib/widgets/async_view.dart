import '../core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uniform loading / error / data handling for AsyncValue everywhere.
class AsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => builder(value),
      AsyncError(:final error) => ErrorView(
        message: errorMessage ?? 'Something went wrong',
        detail: error.toString(),
        onRetry: onRetry,
      ),
      _ => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: dim(48),
              color: scheme.onSurface.withValues(alpha: 0.4),
            ),
            SizedBox(height: dim(16)),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              SizedBox(height: dim(8)),
              Text(
                detail!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: dim(20)),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: dim(48),
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            SizedBox(height: dim(16)),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: dim(8)),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
