/// LoginScreen - User authentication screen.
///
/// Premium editorial login experience aligned with ALPACA design guidelines.
/// Features a hero photo header with dark green overlay at the top.
/// Typography: DM Serif Display (headings) + Plus Jakarta Sans (UI).
/// Colors: Deep Natural Green #2A5C45, Off-White #F7F5F0, Near Black #1C1917.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/models/user_model.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/validators/form_validators.dart';

import 'package:alpaca_mobile/core/theme/app_theme.dart';

/// Login screen with email/password + Google authentication.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  late final AnimationController _contentCtrl;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentFade =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // ── Handlers ────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (authViewModel.isAuthenticated) {
      if (authViewModel.userRole == UserRole.ownerUmkm) {
        final userId = authViewModel.currentUser?.id;
        if (userId != null) {
          await context.read<LocationViewModel>().getCurrentLocation(userId);
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      _printFirebaseToken();
    } else {
      _showError(
          authViewModel.error ?? 'Login gagal. Periksa kembali data Anda.');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.signInWithGoogle();

    if (!mounted) return;

    if (authViewModel.isAuthenticated) {
      if (authViewModel.userRole == UserRole.ownerUmkm) {
        final userId = authViewModel.currentUser?.id;
        if (userId != null) {
          await context.read<LocationViewModel>().getCurrentLocation(userId);
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      _printFirebaseToken();
    } else {
      _showError(authViewModel.error ?? 'Login Google gagal.');
    }
  }

  Future<void> _printFirebaseToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: $fcmToken');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppText.ui(size: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FadeTransition(
        opacity: _contentFade,
        child: SlideTransition(
          position: _contentSlide,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Photo Section ──────────────────────────────────
                _HeroHeader(),

                // ── Form Content ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Page heading
                      Text(
                        'Selamat\nDatang Kembali',
                        style: AppText.display(
                          size: 32,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk untuk melanjutkan perjalanan\nbisnis agraris Anda.',
                        style: AppText.ui(
                          size: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Login form ─────────────────────────────────
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email
                            const _FieldLabel(label: 'Email'),
                            const SizedBox(height: 8),
                            _AlpacaTextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hint: 'nama@email.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: FormValidators.email,
                              onEditingComplete: () => FocusScope.of(context)
                                  .requestFocus(_passwordFocus),
                            ),

                            const SizedBox(height: 20),

                            // Password
                            const _FieldLabel(label: 'Kata Sandi'),
                            const SizedBox(height: 8),
                            _AlpacaTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hint: '••••••••',
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              validator: FormValidators.password,
                              onEditingComplete: _handleLogin,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Primary CTA
                            AlpacaPrimaryButton(
                              label: 'Masuk',
                              isLoading: authViewModel.isLoading,
                              onPressed: _handleLogin,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Divider ───────────────────────────────────
                      const _OrDivider(),

                      const SizedBox(height: 24),

                      // ── Google Sign-In ────────────────────────────
                      _GoogleButton(
                        isLoading: authViewModel.isLoading,
                        onPressed: _handleGoogleSignIn,
                      ),

                      const SizedBox(height: 36),

                      // ── Register link ─────────────────────────────
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: AppText.ui(
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'Belum punya akun? '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () =>
                                      context.push(RouteNames.register),
                                  child: Text(
                                    'Daftar Sekarang',
                                    style: AppText.ui(
                                      size: 13,
                                      weight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
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

// ─── Hero Header with photo + overlay ───────────────────────────────────────

/// Full-width hero section: agricultural landscape photo with deep green
/// semi-transparent overlay and the ALPACA brand mark on top.
class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: 220 + topPad,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background photo ─────────────────────────────────────────
          Image.asset(
            'assets/images/hero_farm.png',
            fit: BoxFit.cover,
          ),

          // ── Dark green overlay (60% opacity) ─────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E3A2F).withValues(alpha: 0.72),
                  const Color(0xFF2A5C45).withValues(alpha: 0.78),
                ],
              ),
            ),
          ),

          // ── Brand mark on top ─────────────────────────────────────────
          Positioned(
            top: topPad + 20,
            left: 24,
            child: const _BrandMarkWhite(),
          ),

          // ── Tagline at bottom of hero ─────────────────────────────────
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Platform UMKM Agraris\nIndonesia',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terhubung. Berkembang. Berkelanjutan.',
                  style: AppText.ui(
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.70),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared UI Components ────────────────────────────────────────────────────

/// White brand mark for use on dark/photo backgrounds
class _BrandMarkWhite extends StatelessWidget {
  const _BrandMarkWhite();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              'α',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 18,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'ALPACA',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 18,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

/// Field label text
class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppText.ui(
        size: 13,
        weight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      ),
    );
  }
}

/// Custom text field following ALPACA design language
class _AlpacaTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onEditingComplete;
  final Widget? suffixIcon;

  const _AlpacaTextField({
    required this.controller,
    this.focusNode,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onEditingComplete,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onEditingComplete: onEditingComplete,
      style: AppText.ui(
        size: 14,
        color: AppColors.textPrimary,
        weight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.ui(
          size: 14,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        errorStyle: AppText.ui(size: 12, color: AppColors.error),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

/// "atau" divider
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'atau',
            style: AppText.ui(size: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ],
    );
  }
}

/// Google sign-in outlined button
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google G icon (colored)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, height: 1),
                children: [
                  TextSpan(
                      text: 'G',
                      style: TextStyle(color: const Color(0xFF4285F4))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Masuk dengan Google',
              style: AppText.ui(
                size: 14,
                weight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
