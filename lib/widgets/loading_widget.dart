/// Loading indicator widgets for the ALPACA application.
///
/// Provides centered, full-screen overlay, and inline loading variants.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// A reusable loading indicator widget with multiple display variants.
///
/// Example usage:
/// ```dart
/// // Centered loading with message
/// LoadingWidget(message: 'Loading products...')
///
/// // Full screen overlay
/// LoadingWidget.overlay(message: 'Please wait...')
///
/// // Inline small spinner
/// LoadingWidget.inline()
/// ```
class LoadingWidget extends StatelessWidget {
  /// Creates a centered [LoadingWidget] with an optional message.
  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 40,
  })  : _variant = _LoadingVariant.centered;

  /// Creates a full-screen overlay loading widget.
  const LoadingWidget.overlay({
    super.key,
    this.message,
    this.color,
    this.size = 40,
  })  : _variant = _LoadingVariant.overlay;

  /// Creates a small inline loading indicator.
  const LoadingWidget.inline({
    super.key,
    this.message,
    this.color,
    this.size = 20,
  })  : _variant = _LoadingVariant.inline;

  /// Optional message displayed below the loading indicator.
  final String? message;

  /// Custom color for the loading indicator.
  final Color? color;

  /// Size of the loading indicator.
  final double size;

  final _LoadingVariant _variant;

  @override
  Widget build(BuildContext context) {
    return switch (_variant) {
      _LoadingVariant.centered => _buildCentered(context),
      _LoadingVariant.overlay => _buildOverlay(context),
      _LoadingVariant.inline => _buildInline(context),
    };
  }

  Widget _buildCentered(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).colorScheme.primary;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.scrim,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInline(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

enum _LoadingVariant {
  centered,
  overlay,
  inline,
}
