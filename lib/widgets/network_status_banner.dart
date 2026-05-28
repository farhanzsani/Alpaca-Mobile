/// Network status banner widget for the ALPACA application.
///
/// Displays an animated banner when the device is offline,
/// and auto-hides when connectivity is restored.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/middleware/connectivity_middleware.dart';
import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// An animated banner that shows when the device is offline.
///
/// Place this widget at the top of your scaffold body or in a [Stack]
/// to overlay content. It listens to [ConnectivityMiddleware] via Provider.
///
/// Example usage:
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       const NetworkStatusBanner(),
///       Expanded(child: content),
///     ],
///   ),
/// )
/// ```
class NetworkStatusBanner extends StatefulWidget {
  /// Creates a [NetworkStatusBanner].
  const NetworkStatusBanner({
    super.key,
    this.message = 'Tidak ada koneksi internet',
    this.backgroundColor,
    this.textColor,
    this.icon = Icons.wifi_off_rounded,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// Message displayed in the banner.
  final String message;

  /// Background color of the banner.
  ///
  /// Defaults to a red/orange warning color.
  final Color? backgroundColor;

  /// Text and icon color.
  final Color? textColor;

  /// Icon displayed in the banner.
  final IconData icon;

  /// Duration of the show/hide animation.
  final Duration animationDuration;

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateVisibility({required bool isOffline}) {
    if (isOffline) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityMiddleware>();
    final isOffline = !connectivity.isConnected;

    // Trigger animation based on connectivity state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateVisibility(isOffline: isOffline);
    });

    final bgColor = widget.backgroundColor ?? AppColors.error;
    final fgColor = widget.textColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (_animationController.isDismissed) {
          return const SizedBox.shrink();
        }

        return ClipRect(
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value * 50),
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: bgColor,
        elevation: 2,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: fgColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.message,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
