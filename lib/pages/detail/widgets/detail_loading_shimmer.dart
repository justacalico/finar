import 'package:flutter/material.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/widgets/widgets.dart';

class DetailLoadingShimmer extends StatelessWidget {
  final double height;

  const DetailLoadingShimmer({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(height: height, borderRadius: AppTheme.radiusMd);
  }
}
