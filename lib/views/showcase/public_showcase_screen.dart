/// PublicShowcaseScreen — Customer home / product discovery screen.
///
/// Redesigned following ALPACA design guidelines:
/// editorial minimalist layout, DM Serif Display headings,
/// Plus Jakarta Sans UI, primary green #2A5C45, amber pricing #C4813A.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_theme.dart';
import 'package:alpaca_mobile/core/theme/app_text_styles.dart';
import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/core/enums/view_state.dart' as vs;
import 'package:alpaca_mobile/widgets/product_card.dart';

class PublicShowcaseScreen extends StatefulWidget {
  const PublicShowcaseScreen({super.key});

  @override
  State<PublicShowcaseScreen> createState() => _PublicShowcaseScreenState();
}

class _PublicShowcaseScreenState extends State<PublicShowcaseScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory; // 'tani', 'umkm', 'agrowisata'
  String _searchQuery = '';

  static const _categories = [
    'tani',
    'umkm',
    'agrowisata',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadAllProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat pagi,';
    } else if (hour < 15) {
      return 'Selamat siang,';
    } else if (hour < 18) {
      return 'Selamat sore,';
    } else {
      return 'Selamat malam,';
    }
  }

  String _categoryLabel(String category) {
    if (category == 'tani') return 'Produk Tani';
    if (category == 'umkm') return 'UMKM Lokal';
    if (category == 'agrowisata') return 'Agrowisata';
    return category;
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var filtered = products.where((p) => p.isAvailable).toList();
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.productName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedCategory != null) {
      if (_selectedCategory == 'tani') {
        filtered = filtered
            .where((p) => p.normalizedCategory == 'agriculture' || p.normalizedCategory == 'food')
            .toList();
      } else if (_selectedCategory == 'umkm') {
        filtered = filtered
            .where((p) => p.normalizedCategory == 'handicraft' || p.normalizedCategory == 'beverage')
            .toList();
      } else if (_selectedCategory == 'agrowisata') {
        filtered = filtered
            .where((p) => p.normalizedCategory == 'other')
            .toList();
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final filteredProducts = _filterProducts(productVm.allProducts);
    
    final fullName = authVm.currentUser?.displayName ?? 'Budi Santoso';
    final firstName = fullName.split(' ').first;

    // Recommendation list: just take first 4 products as mock recommendations
    final recommendations = productVm.allProducts.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Greeting header ───────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(fullName, firstName)),

            // ── Search bar ────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildSearchBar()),

            // ── Category filters ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildCategories()),

            // ── Promo Banner ──────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeroBanner()),

            // ── Rekomendasi Terdekat ──────────────────────────────────────
            if (!productVm.isLoading && recommendations.isNotEmpty && _selectedCategory == null && _searchQuery.isEmpty) ...[
              SliverToBoxAdapter(child: _buildRekomendasiHeader()),
              SliverToBoxAdapter(child: _buildRekomendasiHorizontalList(recommendations)),
            ],

            // ── Section label ─────────────────────────────────────────────
            if (!productVm.isLoading && filteredProducts.isNotEmpty)
              SliverToBoxAdapter(child: _buildSectionLabel(filteredProducts.length)),

            // ── Content ───────────────────────────────────────────────────
            if (productVm.viewState == vs.ViewState.error)
              _buildErrorSliver(productVm.error,
                  () => context.read<ProductViewModel>().loadAllProducts())
            else if (productVm.isLoading && productVm.allProducts.isEmpty)
              _buildLoadingSliver()
            else if (filteredProducts.isEmpty)
              _buildEmptySliver()
            else
              _buildProductGrid(filteredProducts),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(String fullName, String firstName) {
    // Generate initials for Budi Santoso -> BS
    final initials = fullName.isNotEmpty
        ? fullName.trim().split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'BS';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppText.ui(
                    size: 13,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$fullName 👋',
                  style: AppText.display(size: 24),
                ),
              ],
            ),
          ),
          // Profile Avatar Circle - Tapping routes to customer profile
          GestureDetector(
            onTap: () => context.push(RouteNames.customerProfile),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                initials,
                style: AppText.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: AppText.ui(size: 14),
          decoration: InputDecoration(
            hintText: 'Cari produk atau toko...',
            hintStyle: AppText.ui(size: 14, color: AppColors.textTertiary),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        children: [
          AlpacaCategoryPill(
            label: 'Semua',
            selected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ..._categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AlpacaCategoryPill(
                  label: _categoryLabel(cat),
                  selected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                ),
              )),
        ],
      ),
    );
  }

  // ─── Promo Banner ──────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          image: const DecorationImage(
            image: AssetImage('assets/images/hero_agro_banner.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.primaryDark.withValues(alpha: 0.85),
                AppColors.primaryDark.withValues(alpha: 0.2),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'PROMO SPESIAL',
                  style: AppText.micro(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jelajahi Keindahan Alam &\nProduk Lokal Terbaik',
                style: AppText.display(size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Rekomendasi Terdekat ──────────────────────────────────────────────────

  Widget _buildRekomendasiHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.sm),
      child: Text(
        'Rekomendasi Terdekat',
        style: AppText.sectionHeader(),
      ),
    );
  }

  Widget _buildRekomendasiHorizontalList(List<ProductModel> recommendations) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final product = recommendations[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 140,
              child: GestureDetector(
                onTap: () => context.push(RouteNames.productDetail(product.id)),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.lg)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              product.imageUrl != null && product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => _ImagePlaceholder(),
                                    )
                                  : _ImagePlaceholder(),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: AppText.ui(
                                  size: 12,
                                  weight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatRupiah(product.price),
                              style: AppText.price(size: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Section label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            _selectedCategory != null
                ? _categoryLabel(_selectedCategory!)
                : 'Semua Produk',
            style: AppText.sectionHeader(),
          ),
          const Spacer(),
          Text(
            '$count produk',
            style: AppText.label(),
          ),
        ],
      ),
    );
  }

  // ─── Product grid ─────────────────────────────────────────────────────────

  Widget _buildProductGrid(List<ProductModel> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 0,
          AppSpacing.screenH, AppSpacing.xxl),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return ProductCard(
              name: product.productName,
              price: product.price.toInt(),
              imageUrl: product.imageUrl,
              category: _categoryLabel(product.normalizedCategory),
              isAvailable: product.isAvailable,
              onTap: () => context.push(RouteNames.productDetail(product.id)),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  // ─── States ───────────────────────────────────────────────────────────────

  Widget _buildLoadingSliver() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Memuat produk...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySliver() {
    return SliverFillRemaining(
      child: AlpacaEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Produk Tidak Ditemukan',
        subtitle: 'Coba kata kunci atau kategori yang berbeda',
      ),
    );
  }

  Widget _buildErrorSliver(String? message, VoidCallback onRetry) {
    return SliverFillRemaining(
      child: AlpacaEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Gagal Memuat',
        subtitle: message ?? 'Periksa koneksi internet Anda',
        actionLabel: 'Coba Lagi',
        onAction: onRetry,
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 28, color: AppColors.textTertiary),
      ),
    );
  }
}
