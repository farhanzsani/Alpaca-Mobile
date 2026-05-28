/// Empty state display widget for the ALPACA application.
///
/// Used when a list or section has no data to display,
/// providing visual feedback and optional action.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// A widget that displays an empty state with icon, title, description,
/// and optional action button.
///
/// Example usage:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.inventory_2_outlined,
///   title: 'Belum Ada Produk',
///   description: 'Tambahkan produk pertama Anda untuk mulai berjualan.',
///   actionText: 'Tambah Produk',
///   onAction: () => navigateToAddProduct(),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  /// Creates an [EmptyStateWidget].
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.iconWidget,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconBackgroundColor,
    this.iconSize = 48,
  }) : assert(
         icon != null || iconWidget != null,
         'Either icon or iconWidget must be provided',
       );

  /// The title text displayed below the icon.
  final String title;

  /// Optional description text displayed below the title.
  final String? description;

  /// Icon to display. Ignored if [iconWidget] is provided.
  final IconData? icon;

  /// Custom widget to display instead of the default icon.
  ///
  /// Takes precedence over [icon] if both are provided.
  final Widget? iconWidget;

  /// Text for the optional action button.
  final String? actionText;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// Custom color for the icon.
  final Color? iconColor;

  /// Custom background color for the icon container.
  final Color? iconBackgroundColor;

  /// Size of the icon.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.onSurfaceVariant;
    final effectiveIconBgColor = iconBackgroundColor ??
        AppColors.surfaceVariant.withValues(alpha: 0.5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon or illustration
            iconWidget ??
                Container(
                  width: iconSize + 32,
                  height: iconSize + 32,
                  decoration: BoxDecoration(
                    color: effectiveIconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: effectiveIconColor,
                  ),
                ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action button
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionText!,
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
