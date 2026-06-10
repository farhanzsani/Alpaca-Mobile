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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Buat Akun Baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bergabung dengan ALPACA untuk digitalisasi usaha Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
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
                            label: 'Nama Lengkap',
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.email,
                          decoration: _buildInputDecoration(
                            label: 'Email',
                            hint: 'contoh@email.com',
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          validator: FormValidators.password,
                          decoration: _buildInputDecoration(
                            label: 'Password',
                            hint: 'Minimal 8 karakter',
                            icon: Icons.lock_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm password field
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
                            label: 'Konfirmasi Password',
                            hint: 'Ulangi password',
                            icon: Icons.lock_outlined,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Role selection
                        Text(
                          'Daftar sebagai:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<UserRole>(
                          segments: const [
                            ButtonSegment<UserRole>(
                              value: UserRole.ownerUmkm,
                              label: Text('Owner UMKM'),
                              icon: Icon(Icons.store_outlined),
                            ),
                            ButtonSegment<UserRole>(
                              value: UserRole.customer,
                              label: Text('Customer'),
                              icon: Icon(Icons.person_outlined),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (Set<UserRole> selection) {
                            setState(() => _selectedRole = selection.first);
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return colorScheme.primary
                                    .withValues(alpha: 0.12);
                              }
                              return null;
                            }),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Register button
                        FilledButton(
                          onPressed:
                              authViewModel.isLoading ? null : _handleRegister,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authViewModel.isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: colorScheme.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'atau',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colorScheme.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google Sign-In button
                  OutlinedButton.icon(
                    onPressed:
                        authViewModel.isLoading ? null : _handleGoogleSignIn,
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.g_mobiledata,
                        size: 24,
                        color: Colors.red,
                      ),
                    ),
                    label: const Text(
                      'Daftar dengan Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: colorScheme.outline),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(RouteNames.login),
                        child: Text(
                          'Masuk',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds consistent [InputDecoration] for form fields.
  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    );
  }
}
