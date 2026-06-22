/// FavoritesScreen — Saved products and stores.
///
/// Redesigned following ALPACA design guidelines:
/// clean flat header, DM Serif Display section titles,
/// horizontal item cards with border, minimal empty state.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/services/favorites_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  List<FavoriteItem> _favorites = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser ??
        await FirebaseAuth.instance.authStateChanges().first;

    if (user == null) {
      if (mounted) {
        setState(() {
          _error = 'Silakan login terlebih dahulu';
          _isLoading = false;
        });
      }
      return;
    }

    final result = await _favoritesService.getFavoriteItems();
    if (!mounted) return;

    result.when(
      success: (favorites) => setState(() {
        _favorites = favorites;
        _isLoading = false;
      }),
      failure: (exception) => setState(() {
        _error = exception.message;
        _isLoading = false;
      }),
    );
  }

  Future<void> _removeFavorite(FavoriteItem favorite) async {
    final result = await _favoritesService.removeFavoriteItem(
        favorite.itemId, favorite.itemType);
    if (!mounted) return;
    result.when(
      success: (_) => _loadFavorites(),
      failure: (e) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _favorites
        .where((f) => f.product != null)
        .map((f) => (favorite: f, product: f.product!))
        .toList();
    final businesses = _favorites
        .where((f) => f.business != null)
        .map((f) => (favorite: f, business: f.business!))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ─────────────────────────────────────────────
            _buildHeader(),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : _error != null
                      ? _buildErrorState()
                      : _favorites.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: _loadFavorites,
                              child: ListView(
                                padding: const EdgeInsets.all(AppSpacing.screenH),
                                children: [
                                  if (products.isNotEmpty) ...[
                                    _buildSectionTitle(
                                        'Produk Favorit', products.length),
                                    const SizedBox(height: AppSpacing.md),
                                    ...products.map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: AppSpacing.md),
                                        child: _ProductFavoriteCard(
                                          product: e.product,
                                          onTap: () => context.push(
                                              RouteNames.productDetail(
                                                  e.product.id)),
                                          onRemove: () =>
                                              _removeFavorite(e.favorite),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (businesses.isNotEmpty) ...[
                                    if (products.isNotEmpty)
                                      const SizedBox(height: AppSpacing.sm),
                                    _buildSectionTitle(
                                        'Toko Favorit', businesses.length),
                                    const SizedBox(height: AppSpacing.md),
                                    ...businesses.map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: AppSpacing.md),
                                        child: _BusinessFavoriteCard(
                                          business: e.business,
                                          onTap: () => context.push(
                                              RouteNames.storeProfile(
                                                  e.business.ownerId)),
                                          onRemove: () =>
                                              _removeFavorite(e.favorite),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disimpan',
            style: AppText.ui(
                size: 12,
                weight: FontWeight.w500,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Favorit Saya', style: AppText.display(size: 26)),
              const Spacer(),
              if (_favorites.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_favorites.length} item',
                    style: AppText.label(color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section title ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Text(title, style: AppText.sectionHeader()),
        const Spacer(),
        Text('$count item', style: AppText.label()),
      ],
    );
  }

  // ─── States ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return AlpacaEmptyState(
      icon: Icons.bookmark_border_rounded,
      title: 'Belum Ada Favorit',
      subtitle:
          'Simpan produk atau toko yang Anda sukai\nuntuk akses cepat di sini',
    );
  }

  Widget _buildErrorState() {
    return AlpacaEmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'Gagal Memuat',
      subtitle: _error ?? 'Terjadi kesalahan',
      actionLabel: 'Coba Lagi',
      onAction: _loadFavorites,
    );
  }
}

// ─── Favorite Cards ───────────────────────────────────────────────────────────

class _ProductFavoriteCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ProductFavoriteCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _FavoriteCardShell(
      onTap: onTap,
      onRemove: onRemove,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 64,
          height: 64,
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) =>
                      const _ImageBox(icon: Icons.image_outlined),
                )
              : const _ImageBox(icon: Icons.image_outlined),
        ),
      ),
      title: product.productName,
      subtitle: '${formatRupiah(product.price)} / ${product.unit}',
      subtitleColor: AppColors.amber,
    );
  }
}

class _BusinessFavoriteCard extends StatelessWidget {
  final BusinessLocationModel business;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _BusinessFavoriteCard({
    required this.business,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _FavoriteCardShell(
      onTap: onTap,
      onRemove: onRemove,
      leading: const _ImageBox(icon: Icons.storefront_outlined),
      title: business.businessName,
      subtitle: business.address,
    );
  }
}

class _FavoriteCardShell extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCardShell({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onRemove,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.ui(size: 14, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppText.ui(
                        size: 13,
                        color: subtitleColor ?? AppColors.textSecondary,
                        weight: subtitleColor != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Remove button
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  final IconData icon;

  const _ImageBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: 28, color: AppColors.textTertiary),
    );
  }
}
