/// A reusable text input field widget for the ALPACA application.
///
/// Provides a Material 3 styled text field with support for labels,
/// hints, icons, validation, and various input configurations.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// A customizable text field with Material 3 styling and rounded borders.
///
/// Example usage:
/// ```dart
/// CustomTextField(
///   label: 'Email',
///   hint: 'Enter your email',
///   prefixIcon: Icons.email_outlined,
///   keyboardType: TextInputType.emailAddress,
///   validator: (value) => value?.isEmpty == true ? 'Required' : null,
/// )
/// ```
class CustomTextField extends StatelessWidget {
  /// Creates a [CustomTextField].
  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.focusNode,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  /// Controller for the text field.
  final TextEditingController? controller;

  /// Label text displayed above the field.
  final String? label;

  /// Hint text displayed inside the field when empty.
  final String? hint;

  /// Icon displayed at the start of the field.
  final IconData? prefixIcon;

  /// Icon displayed at the end of the field.
  final IconData? suffixIcon;

  /// Callback when the suffix icon is tapped.
  final VoidCallback? onSuffixIconTap;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// Validation function that returns an error string or null.
  final String? Function(String?)? validator;

  /// The type of keyboard to display.
  final TextInputType? keyboardType;

  /// Whether the field is enabled for input.
  final bool enabled;

  /// Error text to display below the field.
  ///
  /// When provided, this overrides the validator error message.
  final String? errorText;

  /// Maximum number of lines for the field.
  final int? maxLines;

  /// Minimum number of lines for the field.
  final int? minLines;

  /// Maximum character length.
  final int? maxLength;

  /// Callback when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// The action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Focus node for managing focus.
  final FocusNode? focusNode;

  /// Autofill hints for the field.
  final Iterable<String>? autofillHints;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelMedium.copyWith(
              color: enabled
                  ? AppColors.onSurface
                  : AppColors.disabled,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction,
          focusNode: focusNode,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          style: AppTextStyles.input.copyWith(
            color: enabled ? AppColors.onSurface : AppColors.disabled,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 22)
                : null,
            suffixIcon: suffixIcon != null
                ? GestureDetector(
                    onTap: onSuffixIconTap,
                    child: Icon(suffixIcon, size: 22),
                  )
                : null,
            filled: true,
            fillColor: enabled
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : AppColors.disabled.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.disabled.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}
