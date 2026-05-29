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
          if (product != null) {
            await productVm.updateProduct(savedProduct);
          } else {
            await productVm.addProduct(savedProduct);
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
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
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          if (productVm.products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${productVm.products.length} produk',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(productVm),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }

  Widget _buildBody(ProductViewModel productVm) {
    if (productVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productVm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                productVm.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
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
              Icon(
                Icons.storefront_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada produk',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap tombol tambah untuk menambahkan produk pertama Anda',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadProducts(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.72,
            ),
            itemCount: productVm.products.length,
            itemBuilder: (context, index) {
              final product = productVm.products[index];
              return _ProductCard(
                product: product,
                formattedPrice: _formatPrice(product.price),
                onTap: () => _openProductForm(product: product),
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
  });

  final ProductModel product;
  final String formattedPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                    Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),
                  // Availability badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.isAvailable
                            ? AppColors.success
                            : AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.isAvailable ? 'Tersedia' : 'Habis',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
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
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedPrice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    // Stock info
                    Row(
                      children: [
                        Icon(
                          product.isLowStock
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          size: 12,
                          color: product.isLowStock
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${product.quantity} ${product.unit}',
                            style: TextStyle(
                              fontSize: 10,
                              color: product.isLowStock
                                  ? AppColors.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: product.isLowStock
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
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
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: AppColors.onSurfaceVariant,
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

    final product = ProductModel(
      id: widget.product?.id ?? '',
      productName: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      imageUrl: widget.product?.imageUrl,
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
