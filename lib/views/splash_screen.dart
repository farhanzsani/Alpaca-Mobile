/// SplashScreen - Entry point of the ALPACA app.
///
/// Displays the app logo, subtitle, and a loading indicator.
/// Navigation is handled by GoRouter's redirect logic in RouteGuard.
/// Once AuthViewModel resolves auth state, the router automatically
/// redirects to the appropriate screen.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/models/user_model.dart';

/// Splash screen shown on app launch.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Trigger auth check — once resolved, GoRouter redirect will navigate.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authVm = context.read<AuthViewModel>();
      await authVm.checkAuthStatus();
      
      // If authenticated as owner, load location BEFORE router redirect
      if (mounted && authVm.isAuthenticated && authVm.userRole == UserRole.ownerUmkm) {
        final userId = authVm.currentUser?.id;
        if (userId != null) {
          // Wait for location to finish loading
          await context.read<LocationViewModel>().getCurrentLocation(userId);
        }
      }
      
      // Force rebuild after location loaded so router can redirect correctly
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Dark green
              Color(0xFF4CAF50), // Medium green
              Color(0xFF81C784), // Light green
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // App name
              const Text(
                'ALPACA',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Digitalisasi UMKM Agraris',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 64),

              // Loading indicator
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
