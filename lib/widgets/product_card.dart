/// Product card widget for the ALPACA application.
///
/// Displays product information in an elegant, modern minimalist card format.
library;

import 'package:flutter/material.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';

/// A card widget that displays product information including image,
/// name, price, category, and availability.
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product image
                _buildImage(),

                // Product details
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product name
                            Text(
                              name,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),

                            // Category
                            if (category != null)
                              Text(
                                category!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price
                            Text(
                              _formatRupiah(price),
                              style: AppTextStyles.price.copyWith(
                                color: AppColors.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Availability badge
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
              color: Colors.black.withValues(alpha: 0.4),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Habis',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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
          size: 32,
          color: AppColors.disabled,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.primaryContainer
            : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 10,
            color: isAvailable ? AppColors.primary : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Tersedia' : 'Habis',
            style: AppTextStyles.labelSmall.copyWith(
              color: isAvailable ? AppColors.primary : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
