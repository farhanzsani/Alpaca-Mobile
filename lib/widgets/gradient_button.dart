// Lokasi: lib/widgets/alpaca_gradient_button.dart

import 'package:flutter/material.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';

class AlpacaGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color> gradientColors;
  final Widget? icon;
  final Color textColor;

  const AlpacaGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    required this.gradientColors,
    this.icon,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: (onPressed == null || isLoading)
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,     
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: AppText.ui(
                      size: 14,
                      weight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}