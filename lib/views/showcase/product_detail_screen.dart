/// ProductDetailScreen — Immersive product detail with sticky WhatsApp CTA.
///
/// Redesigned following ALPACA design guidelines:
/// large hero photo, DM Serif Display product name, amber pricing,
/// flat clean sections, no gradients.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';
import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/services/favorites_service.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  String? _businessName;
  String? _currentOwnerId;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadProductById(widget.productId);
      _loadFavoriteStatus();
    });
  }

  Future<void> _loadFavoriteStatus() async {
    final isFav =
        await _favoritesService.isFavoriteItem(widget.productId, 'product');
    if (!mounted) return;
    setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;
    setState(() => _isFavoriteLoading = true);

    final result = await _favoritesService.toggleFavoriteItem(
        widget.productId, 'product');
    if (!mounted) return;

    result.when(
      success: (isFav) => setState(() {
        _isFavorite = isFav;
        _isFavoriteLoading = false;
      }),
      failure: (e) {
        setState(() => _isFavoriteLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      },
    );
  }

  Future<void> _loadBusinessName(String ownerId) async {
    if (_currentOwnerId != ownerId) {
      setState(() {
        _businessName = null;
        _currentOwnerId = ownerId;
      });
    }
    final name =
        await context.read<LocationViewModel>().getBusinessNameByOwner(ownerId);
    if (mounted && _currentOwnerId == ownerId) {
      setState(() => _businessName = name);
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    final number = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (number.isEmpty) return;
    final wa = '62${number.startsWith('0') ? number.substring(1) : number}';
    final uri = Uri.parse('https://wa.me/$wa');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final product = productVm.selectedProduct;

    if (product != null && _businessName == null) {
      _loadBusinessName(product.ownerId);
    }

    if (product == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(product),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductHeader(product),
                    _buildSectionDivider(),
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      _buildDescription(product),
                      _buildSectionDivider(),
                    ],
                    _buildStockSection(product),
                    _buildSectionDivider(),
                    _buildStoreCard(product),
                    const SizedBox(height: 100), // bottom CTA spacing
                  ],
                ),
              ),
            ],
          ),

          // ── Sticky bottom CTA ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(product),
          ),
        ],
      ),
    );
  }

  // ─── App bar with hero image ──────────────────────────────────────────────

  Widget _buildAppBar(ProductModel product) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _CircleButton(
            icon: _isFavoriteLoading
                ? null
                : _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
            iconColor: _isFavorite ? AppColors.error : AppColors.textPrimary,
            isLoading: _isFavoriteLoading,
            onPressed: _toggleFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_${product.id}',
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 72, color: AppColors.textTertiary),
      ),
    );
  }

  // ─── Product header ───────────────────────────────────────────────────────

  Widget _buildProductHeader(ProductModel product) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              ProductModel.categoryLabel(product.category),
              style: AppText.label(color: AppColors.primary),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Product name
          Text(
            product.productName,
            style: AppText.display(size: 26, height: 1.2),
          ),

          const SizedBox(height: AppSpacing.md),

          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatRupiah(product.price),
                style: AppText.price(size: 28),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${product.unit}',
                style: AppText.ui(size: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Description ──────────────────────────────────────────────────────────

  Widget _buildDescription(ProductModel product) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deskripsi Produk', style: AppText.sectionHeader()),
          const SizedBox(height: AppSpacing.md),
          Text(
            product.description!,
            style: AppText.ui(
                size: 14, color: AppColors.textSecondary, height: 1.7),
          ),
        ],
      ),
    );
  }

  // ─── Stock info ───────────────────────────────────────────────────────────

  Widget _buildStockSection(ProductModel product) {
    final isLow = product.isLowStock;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLow ? AppColors.errorLight : AppColors.successLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isLow
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
              color: isLow ? AppColors.error : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLow ? 'Stok Terbatas' : 'Stok Tersedia',
                style: AppText.ui(
                  size: 14,
                  weight: FontWeight.w700,
                  color: isLow ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${product.quantity} ${product.unit} tersisa',
                style: AppText.ui(size: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Store card ───────────────────────────────────────────────────────────

  Widget _buildStoreCard(ProductModel product) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Penjual', style: AppText.sectionHeader()),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => context.push(RouteNames.storeProfile(product.ownerId)),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _businessName ?? 'Memuat...',
                          style: AppText.ui(
                              size: 14, weight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lihat profil toko',
                          style: AppText.label(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom CTA ───────────────────────────────────────────────────────────

  Widget _buildBottomCTA(ProductModel product) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Favorite icon button
          GestureDetector(
            onTap: _toggleFavorite,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 22,
                color:
                    _isFavorite ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // WhatsApp CTA
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _openWhatsApp(null),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: Text(
                  'Hubungi via WhatsApp',
                  style: AppText.ui(
                    size: 14,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(height: 8, color: AppColors.bg);
  }
}

// ─── Circle action button ─────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _CircleButton({
    this.icon,
    this.iconColor,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: AppShadows.card(),
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            )
          : IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(icon, size: 18,
                  color: iconColor ?? AppColors.textPrimary),
              onPressed: onPressed,
            ),
    );
  }
}
