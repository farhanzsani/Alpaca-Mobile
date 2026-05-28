/// A reusable button widget for the ALPACA application.
///
/// Provides filled, outlined, and text button variants with
/// loading state, icon support, and Material 3 styling.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// The visual variant of the button.
enum CustomButtonVariant {
  /// Filled button with primary background color.
  filled,

  /// Outlined button with border and transparent background.
  outlined,

  /// Text-only button with no background or border.
  text,
}

/// A customizable button with multiple variants and states.
///
/// Example usage:
/// ```dart
/// CustomButton(
///   text: 'Submit',
///   onPressed: () => handleSubmit(),
///   isLoading: isSubmitting,
///   icon: Icons.send,
/// )
///
/// CustomButton(
///   text: 'Cancel',
///   variant: CustomButtonVariant.outlined,
///   onPressed: () => Navigator.pop(context),
/// )
/// ```
class CustomButton extends StatelessWidget {
  /// Creates a [CustomButton].
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CustomButtonVariant.filled,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.height = 48,
    this.borderRadius = 12,
    this.elevation,
  });

  /// The button label text.
  final String text;

  /// Callback when the button is pressed.
  ///
  /// If null, the button will appear disabled.
  final VoidCallback? onPressed;

  /// The visual variant of the button.
  final CustomButtonVariant variant;

  /// Whether to show a loading indicator instead of the text.
  final bool isLoading;

  /// Whether the button is disabled.
  final bool isDisabled;

  /// Whether the button should expand to fill available width.
  final bool isFullWidth;

  /// Optional icon displayed before the text.
  final IconData? icon;

  /// Custom background color (overrides variant default).
  final Color? backgroundColor;

  /// Custom foreground/text color (overrides variant default).
  final Color? foregroundColor;

  /// Custom border color for outlined variant.
  final Color? borderColor;

  /// Button height.
  final double height;

  /// Border radius of the button.
  final double borderRadius;

  /// Button elevation (only applies to filled variant).
  final double? elevation;

  bool get _isEnabled => !isDisabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Widget buttonChild = _buildChild(colorScheme);

    final Widget button = switch (variant) {
      CustomButtonVariant.filled => _buildFilledButton(
          colorScheme, buttonChild),
      CustomButtonVariant.outlined => _buildOutlinedButton(
          colorScheme, buttonChild),
      CustomButtonVariant.text => _buildTextButton(
          colorScheme, buttonChild),
    };

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    }

    return SizedBox(height: height, child: button);
  }

  Widget _buildChild(ColorScheme colorScheme) {
    if (isLoading) {
      final indicatorColor = switch (variant) {
        CustomButtonVariant.filled =>
          foregroundColor ?? colorScheme.onPrimary,
        CustomButtonVariant.outlined =>
          foregroundColor ?? colorScheme.primary,
        CustomButtonVariant.text =>
          foregroundColor ?? colorScheme.primary,
      };

      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.button),
        ],
      );
    }

    return Text(text, style: AppTextStyles.button);
  }

  Widget _buildFilledButton(ColorScheme colorScheme, Widget child) {
    return ElevatedButton(
      onPressed: _isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.primary,
        foregroundColor: foregroundColor ?? colorScheme.onPrimary,
        disabledBackgroundColor: AppColors.disabled.withValues(alpha: 0.3),
        disabledForegroundColor: AppColors.disabled,
        elevation: elevation ?? 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: child,
    );
  }

  Widget _buildOutlinedButton(ColorScheme colorScheme, Widget child) {
    return OutlinedButton(
      onPressed: _isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? colorScheme.primary,
        disabledForegroundColor: AppColors.disabled,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        side: BorderSide(
          color: _isEnabled
              ? (borderColor ?? colorScheme.outline)
              : AppColors.disabled.withValues(alpha: 0.5),
        ),
      ),
      child: child,
    );
  }

  Widget _buildTextButton(ColorScheme colorScheme, Widget child) {
    return TextButton(
      onPressed: _isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? colorScheme.primary,
        disabledForegroundColor: AppColors.disabled,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: child,
    );
  }
}
