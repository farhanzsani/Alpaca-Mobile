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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product image
              _buildImage(),

              // Product details
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Category
                      if (category != null)
                        Text(
                          category!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const Spacer(),

                      // Price
                      Text(
                        _formatRupiah(price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF22C55E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // Availability badge
                      _buildAvailabilityBadge(),
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
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
                color: Colors.black.withValues(alpha: 0.5),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Habis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF22C55E),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0xFF22C55E).withValues(alpha: 0.1)
            : const Color(0xFFDC2626).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 12,
            color: isAvailable ? const Color(0xFF22C55E) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? '100 pcs' : 'Habis',
            style: TextStyle(
              color: isAvailable ? const Color(0xFF22C55E) : const Color(0xFFDC2626),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
