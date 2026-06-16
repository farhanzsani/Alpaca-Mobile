/// Products management screen for business owners.
///
/// Displays a grid/list of products with image, name, price, and
/// availability status. Supports adding, editing, and managing
/// product catalog items.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';
import 'package:alpaca_mobile/repositories/media_repository.dart';

/// Screen for managing the product catalog of a business owner.
///
/// Features:
/// - Grid/list of products with image, name, price
/// - FAB to add new product
/// - Each product card shows: image, name, price, availability badge
/// - Tap to edit product
/// - Add/Edit form: name, description, price, category, image upload, availability toggle
class ProductsScreen extends StatefulWidget {
  /// Creates a [ProductsScreen].
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  void _loadProducts() {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId != null) {
      context.read<ProductViewModel>().loadProducts(userId);
    }
  }

  void _openProductForm({ProductModel? product}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProductFormSheet(
        product: product,
        onSave: (savedProduct) async {
          final productVm = context.read<ProductViewModel>();
          final authVm = context.read<AuthViewModel>();
          if (product != null) {
            await productVm.updateProduct(savedProduct);
          } else {
            await productVm.addProduct(savedProduct);
          }
          // Reload products after create/update
          if (authVm.currentUser?.id != null) {
            await productVm.loadProducts(authVm.currentUser!.id);
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${product.productName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<ProductViewModel>().deleteProduct(product.id);
    }
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(productVm),
          Expanded(child: _buildBody(productVm)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(),
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader(ProductViewModel productVm) {
    final totalProducts = productVm.products.length;
    final availableProducts = productVm.products.where((p) => p.isAvailable).length;
    final lowStockProducts = productVm.products.where((p) => p.isLowStock).length;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF86EFAC),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Produk',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Kelola produk Anda',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF86EFAC),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (productVm.products.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${productVm.products.length} produk',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$totalProducts',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Total Produk',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF86EFAC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$availableProducts',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tersedia',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF86EFAC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: lowStockProducts > 0
                            ? const Color(0xFFD97706).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$lowStockProducts',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: lowStockProducts > 0
                                  ? const Color(0xFFFEF3C7)
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stok Rendah',
                            style: TextStyle(
                              fontSize: 11,
                              color: lowStockProducts > 0
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFF86EFAC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ProductViewModel productVm) {
    if (productVm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF22C55E),
        ),
      );
    }

    if (productVm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                productVm.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (productVm.products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 64,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada produk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap tombol tambah untuk menambahkan\nproduk pertama Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF22C55E),
      onRefresh: () async => _loadProducts(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: productVm.products.length,
            itemBuilder: (context, index) {
              final product = productVm.products[index];
              return _ProductCard(
                product: product,
                formattedPrice: _formatPrice(product.price),
                onTap: () => _openProductForm(product: product),
                onDelete: () => _confirmDelete(product),
              );
            },
          );
        },
      ),
    );
  }
}

/// A card widget displaying product information in the grid.
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.formattedPrice,
    required this.onTap,
    required this.onDelete,
  });

  final ProductModel product;
  final String formattedPrice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Future<void> _adjustStock(BuildContext context, int amount) async {
    final productVm = context.read<ProductViewModel>();
    final updatedProduct = product.copyWith(
      quantity: (product.quantity + amount).clamp(0, 999999),
      updatedAt: DateTime.now(),
    );
    
    await productVm.updateProduct(updatedProduct);
    
    // Reload products
    final authVm = context.read<AuthViewModel>();
    if (authVm.currentUser?.id != null) {
      await productVm.loadProducts(authVm.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  // Availability badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        product.isAvailable ? 'Tersedia' : 'Habis',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  // Delete button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: Colors.white,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const Spacer(),
                    // Stock info with adjustment buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.isLowStock
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.isLowStock
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_rounded,
                                  size: 12,
                                  color: product.isLowStock
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF22C55E),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${product.quantity} ${product.unit}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: product.isLowStock
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF22C55E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: product.quantity > 0
                              ? () => _adjustStock(context, -1)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: product.quantity > 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 14,
                              color: product.quantity > 0
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        GestureDetector(
                          onTap: () => _adjustStock(context, 1),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

/// Bottom sheet form for adding or editing a product.
class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({
    this.product,
    required this.onSave,
  });

  final ProductModel? product;
  final Future<void> Function(ProductModel product) onSave;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');

  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategory = 'food';
  bool _isAvailable = true;
  File? _selectedImage;
  bool _isSaving = false;

  static const _categories = ['food', 'beverage', 'handicraft', 'agriculture', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.productName;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _quantityController.text = widget.product!.quantity.toString();
      _minStockController.text = widget.product!.minimumStock.toString();
      _unitController.text = widget.product!.unit;
      _selectedCategory = widget.product!.category;
      _isAvailable = widget.product!.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'food':
        return 'Makanan';
      case 'beverage':
        return 'Minuman';
      case 'handicraft':
        return 'Kerajinan';
      case 'agriculture':
        return 'Pertanian';
      default:
        return 'Lainnya';
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id ?? '';
    final now = DateTime.now();

    String? imageUrl = widget.product?.imageUrl;

    if (_selectedImage != null) {
      final mediaRepo = context.read<MediaRepository>();
      final uploadResult = await mediaRepo.uploadImage(
        _selectedImage!,
        'products',
        userId,
      );

      if (uploadResult.isSuccess) {
        imageUrl = uploadResult.dataOrNull?.imageUrl;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(uploadResult.exceptionOrNull?.message ?? 'Gagal mengunggah gambar.')),
          );
          setState(() => _isSaving = false);
        }
        return;
      }
    }

    final product = ProductModel(
      id: widget.product?.id ?? '',
      productName: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      imageUrl: imageUrl,
      ownerId: userId,
      category: _selectedCategory,
      isAvailable: _isAvailable,
      quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
      minimumStock: int.tryParse(_minStockController.text.trim()) ?? 0,
      unit: _unitController.text.trim().isNotEmpty
          ? _unitController.text.trim()
          : 'pcs',
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );

    await widget.onSave(product);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Center(
                  child: Text(
                    isEditing ? 'Edit Produk' : 'Tambah Produk',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 24),

                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: _buildImagePreview(),
                  ),
                ),
                const SizedBox(height: 16),

                // Product name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk',
                    hintText: 'Masukkan nama produk',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama produk wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Deskripsikan produk Anda',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    hintText: 'Masukkan harga',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harga wajib diisi';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price < 0) {
                      return 'Masukkan harga yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(_selectedCategory)
                      ? _selectedCategory
                      : 'other',
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(_categoryLabel(c)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Availability toggle
                SwitchListTile(
                  title: const Text('Tersedia'),
                  subtitle: Text(
                    _isAvailable
                        ? 'Produk ditampilkan di katalog publik'
                        : 'Produk disembunyikan dari katalog',
                  ),
                  value: _isAvailable,
                  onChanged: (value) {
                    setState(() => _isAvailable = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                // --- Stock Info ---
                const Divider(),
                Text(
                  'Informasi Stok',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Stok',
                    hintText: '0',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (int.tryParse(value.trim()) == null) {
                        return 'Masukkan angka yang valid';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Minimum stock
                TextFormField(
                  controller: _minStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok Minimum',
                    hintText: '0',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (int.tryParse(value.trim()) == null) {
                        return 'Masukkan angka yang valid';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Unit
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    hintText: 'pcs, kg, liter',
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Satuan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Save button
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isEditing ? 'Perbarui Produk' : 'Simpan Produk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    if (widget.product?.imageUrl != null &&
        widget.product!.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.product!.imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap untuk memilih gambar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
