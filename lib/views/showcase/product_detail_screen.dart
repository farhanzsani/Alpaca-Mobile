/// Product detail screen for the public showcase.
///
/// Displays full product information including image, name,
/// description, price, and owner/business details.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';

/// Screen showing detailed information about a single product.
///
/// Features:
/// - Full product image
/// - Product name, description, price
/// - Owner/business info
/// - Location link
/// - Back button
class ProductDetailScreen extends StatelessWidget {
  /// Creates a [ProductDetailScreen] for the given [productId].
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  /// The ID of the product to display.
  final String productId;

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return 'Rp $formatted';
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

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final product = productVm.allProducts
        .where((p) => p.id == productId)
        .firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Produk tidak ditemukan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Image app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProductImage(product),
            ),
          ),

          // Product details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Chip(
                    label: Text(_categoryLabel(product.category)),
                    avatar: const Icon(Icons.category_outlined, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    product.productName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    _formatPrice(product.price),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),

                  // Availability
                  Row(
                    children: [
                      Icon(
                        product.isAvailable
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 16,
                        color: product.isAvailable
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: product.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    Text(
                      'Deskripsi',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Owner/Business info
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildOwnerSection(context, product),
                  const SizedBox(height: 16),

                  // Location link
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.showcaseMap),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Lihat di Peta'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(ProductModel product) {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 80,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildOwnerSection(BuildContext context, ProductModel product) {
    return InkWell(
      onTap: () => context.push(RouteNames.storeProfile(product.ownerId)),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.secondaryContainer,
            child: const Icon(
              Icons.store_outlined,
              size: 20,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Penjual',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lihat Profil Toko',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
