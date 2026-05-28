/// Error display widget for the ALPACA application.
///
/// Provides compact and full error display variants with
/// optional retry functionality.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// A widget that displays an error state with an icon, message, and retry button.
///
/// Example usage:
/// ```dart
/// // Full variant with retry
/// AppErrorWidget(
///   message: 'Failed to load products',
///   onRetry: () => ref.refresh(productsProvider),
/// )
///
/// // Compact inline variant
/// AppErrorWidget.compact(
///   message: 'Connection error',
///   onRetry: () => retry(),
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  /// Creates a full [AppErrorWidget] with icon, message, and optional retry.
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
    this.retryText = 'Coba Lagi',
  })  : _variant = _ErrorVariant.full;

  /// Creates a compact inline error widget.
  const AppErrorWidget.compact({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.warning_amber_rounded,
    this.retryText = 'Coba Lagi',
  })  : _variant = _ErrorVariant.compact;

  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed.
  ///
  /// If null, the retry button will not be shown.
  final VoidCallback? onRetry;

  /// The icon to display above the error message.
  final IconData icon;

  /// Text for the retry button.
  final String retryText;

  final _ErrorVariant _variant;

  @override
  Widget build(BuildContext context) {
    return switch (_variant) {
      _ErrorVariant.full => _buildFull(context),
      _ErrorVariant.compact => _buildCompact(context),
    };
  }

  Widget _buildFull(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(retryText),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                retryText,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ErrorVariant {
  full,
  compact,
}
