/// Product card widget for the ALPACA application.
///
/// Displays product information in a card format suitable for
/// grid or list layouts in the marketplace.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// A card widget that displays product information including image,
/// name, price, category, and availability.
///
/// Example usage:
/// ```dart
/// ProductCard(
///   name: 'Kopi Arabika Gayo',
///   price: 85000,
///   imageUrl: 'https://example.com/kopi.jpg',
///   category: 'Kopi',
///   isAvailable: true,
///   onTap: () => navigateToDetail(productId),
/// )
/// ```
class ProductCard extends StatelessWidget {
  /// Creates a [ProductCard].
  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.imageUrl,
    this.category,
    this.isAvailable = true,
    this.onTap,
    this.width,
    this.height,
  });

  /// The product name.
  final String name;

  /// The product price in Rupiah (as integer).
  final int price;

  /// URL of the product image.
  ///
  /// If null, a placeholder icon is displayed.
  final String? imageUrl;

  /// Product category label.
  final String? category;

  /// Whether the product is currently available.
  final bool isAvailable;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Optional fixed width for the card.
  final double? width;

  /// Optional fixed height for the card.
  final double? height;

  /// Formats an integer price to Indonesian Rupiah format.
  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    var count = 0;

    for (var i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              _buildImage(),

              // Product details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category chip
                      if (category != null) ...[
                        _buildCategoryChip(),
                        const SizedBox(height: 6),
                      ],

                      // Product name
                      Expanded(
                        child: Text(
                          name,
                          style: AppTextStyles.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Price and availability
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _formatRupiah(price),
                              style: AppTextStyles.price.copyWith(
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildAvailabilityBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingPlaceholder();
              },
            )
          else
            _buildPlaceholder(),

          // Unavailable overlay
          if (!isAvailable)
            Container(
              color: AppColors.scrim,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Habis',
                  style: AppTextStyles.badge,
                ),
              ),
            ),
        ],
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

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.shimmerBase,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category!,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onPrimaryContainer,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAvailabilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.successContainer
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAvailable ? 'Tersedia' : 'Habis',
        style: AppTextStyles.badge.copyWith(
          color: isAvailable ? AppColors.success : AppColors.error,
          fontSize: 9,
        ),
      ),
    );
  }
}
