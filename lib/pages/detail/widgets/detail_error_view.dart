import 'package:flutter/material.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';

class DetailErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const DetailErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load details', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(error, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
