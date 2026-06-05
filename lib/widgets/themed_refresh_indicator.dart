import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ThemedRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const ThemedRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      onRefresh: onRefresh,
      child: child,
    );
  }
}