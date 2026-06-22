library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/models/user_model.dart';
import 'package:alpaca_mobile/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _wordmarkCtrl;
  late final Animation<double> _wordmarkFade;
  late final Animation<Offset> _wordmarkSlide;

  late final AnimationController _taglineCtrl;
  late final Animation<double> _taglineFade;

  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _wordmarkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _wordmarkFade = CurvedAnimation(parent: _wordmarkCtrl, curve: Curves.easeOut);
    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _wordmarkCtrl, curve: Curves.easeOutCubic));

    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _taglineFade = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn);

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _wordmarkCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _taglineCtrl.forward();
    });

    // Auth resolution
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authVm = context.read<AuthViewModel>();
      final minimumSplashDuration = Future.delayed(const Duration(milliseconds: 2500));

      if (authVm.hasFirebaseSession) {
        authVm.checkAuthStatus();
        
        await Future.wait([
          authVm.waitForAuthResolution(),
          minimumSplashDuration,
        ]);
        
        if (!mounted) return;
        await _navigateBasedOnAuth(authVm);
      } else {
        
        await Future.wait([
          authVm.checkAuthStatus(),
          minimumSplashDuration,
        ]);
        
        if (!mounted) return;
        if (authVm.isAuthenticated) {
          await _navigateBasedOnAuth(authVm);
        } else {
          context.go(RouteNames.login);
        }
      }
    });
  }

  Future<void> _navigateBasedOnAuth(AuthViewModel authVm) async {
    if (authVm.userRole == UserRole.ownerUmkm) {
      final userId = authVm.currentUser?.id;
      if (userId != null) {
        await context.read<LocationViewModel>().getCurrentLocation(userId);
      }
      if (!mounted) return;
      final hasLocation =
          context.read<LocationViewModel>().businessLocation != null;
      context.go(
          hasLocation ? RouteNames.ownerDashboard : RouteNames.businessOnboarding);
    } else {
      context.go(RouteNames.showcase);
    }
  }

  @override
  void dispose() {
    _wordmarkCtrl.dispose();
    _taglineCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _wordmarkFade,
                    child: SlideTransition(
                      position: _wordmarkSlide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: Center(
                              child: Image.asset(
                                'assets/icons/alpaca_icons_clear.png',
                                width: 128,
                                height: 128,
                              ),
                            ),
                          ),
                          Text(
                            'ALPACA',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 52,
                              color: Colors.white,
                              letterSpacing: 6,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'Platform UMKM Agraris Indonesia',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.50),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: _LoadingDots(controller: _dotCtrl),
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;

  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3.0;
            final value = ((controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (value < 0.5)
                ? (value * 2).clamp(0.2, 1.0)
                : ((1.0 - value) * 2).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}