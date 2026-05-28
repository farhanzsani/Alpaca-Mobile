/// Confirmation dialog widget for the ALPACA application.
///
/// Provides a reusable dialog with confirm/cancel actions
/// and a destructive action variant.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// A Material 3 confirmation dialog with customizable actions.
///
/// Use the static [show] method for convenient usage:
/// ```dart
/// final confirmed = await ConfirmationDialog.show(
///   context: context,
///   title: 'Hapus Produk?',
///   message: 'Produk ini akan dihapus secara permanen.',
///   confirmText: 'Hapus',
///   isDestructive: true,
/// );
///
/// if (confirmed == true) {
///   deleteProduct();
/// }
/// ```
class ConfirmationDialog extends StatelessWidget {
  /// Creates a [ConfirmationDialog].
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Konfirmasi',
    this.cancelText = 'Batal',
    this.confirmColor,
    this.isDestructive = false,
    this.icon,
  });

  /// The dialog title.
  final String title;

  /// The dialog message/description.
  final String message;

  /// Text for the confirm button.
  final String confirmText;

  /// Text for the cancel button.
  final String cancelText;

  /// Custom color for the confirm button.
  ///
  /// Overrides the default color and [isDestructive] color.
  final Color? confirmColor;

  /// Whether this is a destructive action (shows red confirm button).
  final bool isDestructive;

  /// Optional icon displayed above the title.
  final IconData? icon;

  /// Shows the confirmation dialog and returns `true` if confirmed,
  /// `false` if cancelled, or `null` if dismissed.
  ///
  /// Parameters:
  /// - [context] - Build context for showing the dialog.
  /// - [title] - Dialog title text.
  /// - [message] - Dialog message/description.
  /// - [confirmText] - Text for the confirm button.
  /// - [cancelText] - Text for the cancel button.
  /// - [confirmColor] - Custom confirm button color.
  /// - [isDestructive] - Whether to style as a destructive action.
  /// - [icon] - Optional icon above the title.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Konfirmasi',
    String cancelText = 'Batal',
    Color? confirmColor,
    bool isDestructive = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfirmColor = confirmColor ??
        (isDestructive ? AppColors.error : AppColors.primary);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      icon: icon != null
          ? Icon(
              icon,
              size: 32,
              color: isDestructive ? AppColors.error : AppColors.primary,
            )
          : null,
      title: Text(
        title,
        style: AppTextStyles.titleLarge,
        textAlign: TextAlign.center,
      ),
      content: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          children: [
            // Cancel button
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurfaceVariant,
                  side: const BorderSide(color: AppColors.outlineVariant),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  cancelText,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Confirm button
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveConfirmColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  confirmText,
                  style: AppTextStyles.button.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
