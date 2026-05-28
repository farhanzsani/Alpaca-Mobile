/// Statistics card widget for the ALPACA application.
///
/// Compact card for displaying key metrics on dashboard grids.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// The direction of a trend indicator.
enum TrendDirection {
  /// Value is increasing.
  up,

  /// Value is decreasing.
  down,

  /// Value is stable / no change.
  neutral,
}

/// A compact card widget for displaying statistics on a dashboard.
///
/// Example usage:
/// ```dart
/// StatCard(
///   icon: Icons.shopping_bag_outlined,
///   title: 'Total Produk',
///   value: '128',
///   trend: TrendDirection.up,
///   trendValue: '+12%',
///   backgroundColor: AppColors.primaryContainer,
/// )
/// ```
class StatCard extends StatelessWidget {
  /// Creates a [StatCard].
  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.trend,
    this.trendValue,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
  });

  /// Icon displayed in the card.
  final IconData icon;

  /// Title label describing the statistic.
  final String title;

  /// The statistic value (number or formatted text).
  final String value;

  /// Optional trend direction indicator.
  final TrendDirection? trend;

  /// Optional trend value text (e.g., '+12%', '-5%').
  final String? trendValue;

  /// Background color of the card.
  ///
  /// Defaults to surface color if not provided.
  final Color? backgroundColor;

  /// Custom icon color.
  final Color? iconColor;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        Theme.of(context).colorScheme.surface;
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and trend row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: effectiveIconColor,
                    ),
                  ),
                  if (trend != null) _buildTrendIndicator(),
                ],
              ),

              const SizedBox(height: 12),

              // Value
              Text(
                value,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Title
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final Color trendColor;
    final IconData trendIcon;

    switch (trend!) {
      case TrendDirection.up:
        trendColor = AppColors.success;
        trendIcon = Icons.trending_up_rounded;
      case TrendDirection.down:
        trendColor = AppColors.error;
        trendIcon = Icons.trending_down_rounded;
      case TrendDirection.neutral:
        trendColor = AppColors.onSurfaceVariant;
        trendIcon = Icons.trending_flat_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(trendIcon, size: 16, color: trendColor),
        if (trendValue != null) ...[
          const SizedBox(width: 2),
          Text(
            trendValue!,
            style: AppTextStyles.labelSmall.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
