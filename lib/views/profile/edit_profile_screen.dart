import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alpaca_mobile/core/network/api_client.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Sesi berakhir');

      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();

      // Use AuthViewModel to update profile
      final authVm = context.read<AuthViewModel>();
      await authVm.updateProfile(
        displayName: newName.isNotEmpty ? newName : null,
        phoneNumber: newPhone.isNotEmpty ? newPhone : null,
      );

      // Check if there was an error in ViewModel
      if (authVm.error != null) {
        throw Exception(authVm.error);
      }
      
      // Update in Backend (assuming `/users/create` handles upsert)
      final apiClient = context.read<ApiClient>();
      
      final dbUser = authVm.currentUser;
      if (dbUser != null) {
        await apiClient.post(
          '/users/create', 
          {
            'id': dbUser.id,
            'email': dbUser.email,
            'display_name': newName,
            'role': dbUser.role.toJson(),
            'photo_url': dbUser.photoUrl ?? '',
            'phone_number': newPhone.isNotEmpty ? newPhone : null,
            'created_at': dbUser.createdAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          (_) => {},
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;
    
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Edit Profil',
          style: AppText.ui(size: 17, weight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Sesi berakhir'))
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  const SizedBox(height: 10),
                  // Avatar placeholder
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'U',
                          style: AppText.display(
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Email (Read-only)
                  Text(
                    'Email',
                    style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: user.email,
                    readOnly: true,
                    style: AppText.ui(size: 14, color: AppColors.textSecondary),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    'Nama Lengkap',
                    style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: AppText.ui(size: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                      hintText: 'Masukkan nama lengkap',
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone
                  Text(
                    'Nomor Telepon',
                    style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    style: AppText.ui(size: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      hintText: 'Contoh: 081234567890',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 36),
                  
                  // Submit
                  AlpacaPrimaryButton(
                    label: 'Simpan Perubahan',
                    isLoading: _isLoading,
                    onPressed: _saveProfile,
                  ),
                ],
              ),
            ),
    );
  }
}
