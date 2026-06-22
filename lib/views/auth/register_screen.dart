/// RegisterScreen - New user registration screen.
///
/// Provides fields for name, email, password, confirm password,
/// and role selection. Uses [AuthViewModel] for registration
/// and [FormValidators] for input validation.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/models/user_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/validators/form_validators.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';

/// Registration screen with form validation and role selection.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.ownerUmkm;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates form and attempts registration via [AuthViewModel].
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();

    await authViewModel.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;
    _showResultMessage(authViewModel);
  }

  /// Handles Google Sign-In flow.
  Future<void> _handleGoogleSignIn() async {
    final authViewModel = context.read<AuthViewModel>();

    await authViewModel.signInWithGoogle();

    if (!mounted) return;
    _showResultMessage(authViewModel);
  }

  /// Shows success or error message.
  /// Navigation on success is handled automatically by GoRouter redirect.
  void _showResultMessage(AuthViewModel authViewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    if (authViewModel.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registrasi berhasil!'),
          backgroundColor: colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else if (authViewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.error ?? 'Registrasi gagal'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Buat Akun Baru',
                    textAlign: TextAlign.center,
                    style: AppText.display(size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bergabung dengan ALPACA untuk digitalisasi usaha agraris Anda',
                    textAlign: TextAlign.center,
                    style: AppText.ui(
                      size: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Registration form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name field
                        _buildFieldLabel('Nama Lengkap'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => FormValidators.required(
                            value,
                            fieldName: 'Nama',
                          ),
                          decoration: _buildInputDecoration(
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        _buildFieldLabel('Email'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.email,
                          decoration: _buildInputDecoration(
                            hint: 'contoh@email.com',
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        _buildFieldLabel('Kata Sandi'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.password,
                          decoration: _buildInputDecoration(
                            hint: 'Minimal 8 karakter',
                            icon: Icons.lock_outlined,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm password field
                        _buildFieldLabel('Konfirmasi Kata Sandi'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          validator: (value) =>
                              FormValidators.confirmPassword(
                            value,
                            _passwordController.text,
                          ),
                          decoration: _buildInputDecoration(
                            hint: 'Ulangi kata sandi',
                            icon: Icons.lock_outlined,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              child: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Role selection
                        _buildFieldLabel('Daftar sebagai:'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleSelector(
                                role: UserRole.ownerUmkm,
                                label: 'Owner UMKM',
                                icon: Icons.storefront_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRoleSelector(
                                role: UserRole.customer,
                                label: 'Customer',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Register button
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: authViewModel.isLoading ? null : _handleRegister,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: authViewModel.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Daftar',
                                    style: AppText.ui(
                                      size: 15,
                                      weight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  const _OrDivider(),
                  const SizedBox(height: 24),

                  // Google Sign-In button
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: authViewModel.isLoading ? null : _handleGoogleSignIn,
                      icon: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        width: 18,
                        height: 18,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.g_mobiledata,
                          size: 24,
                          color: AppColors.error,
                        ),
                      ),
                      label: Text(
                        'Daftar dengan Google',
                        style: AppText.ui(
                          size: 14,
                          weight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: AppText.ui(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => context.go(RouteNames.login),
                        child: Text(
                          'Masuk',
                          style: AppText.ui(
                            weight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppText.ui(
        size: 13,
        weight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRoleSelector({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.successLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppText.ui(
                size: 13,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.ui(size: 14, color: AppColors.textTertiary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child: suffixIcon,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

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
