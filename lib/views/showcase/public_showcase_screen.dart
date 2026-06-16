/// Modern product showcase screen with exploration-focused design.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';
import 'package:alpaca_mobile/core/enums/view_state.dart';

class PublicShowcaseScreen extends StatefulWidget {
  const PublicShowcaseScreen({super.key});

  @override
  State<PublicShowcaseScreen> createState() => _PublicShowcaseScreenState();
}

class _PublicShowcaseScreenState extends State<PublicShowcaseScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String _searchQuery = '';

  static const _categories = ['food', 'beverage', 'handicraft', 'agriculture', 'lainnya'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadAllProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryLabel(String category) {
    const labels = {
      'food': 'Makanan',
      'beverage': 'Minuman',
      'handicraft': 'Kerajinan',
      'agriculture': 'Pertanian',
      'lainnya': 'Lainnya',
    };
    return labels[category] ?? 'Lainnya';
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var filtered = products.where((p) => p.isAvailable).toList();
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.productName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    return filtered;
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
    final filteredProducts = _filterProducts(productVm.allProducts);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategories(),
            if (productVm.viewState == ViewState.error)
              _buildErrorState(productVm.error, () => context.read<ProductViewModel>().loadAllProducts())
            else if (productVm.isLoading && productVm.allProducts.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF22C55E)),
                      SizedBox(height: 16),
                      Text('Memuat produk...', style: TextStyle(color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              )
            else if (filteredProducts.isEmpty)
              _buildEmptyState()
            else
              _buildProductGrid(filteredProducts),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jelajahi Produk',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14532D),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Temukan produk lokal terbaik',
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFF6B7280).withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              hintStyle: TextStyle(
                color: const Color(0xFF9CA3AF),
                fontSize: 15,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6B7280), size: 22),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildCategoryChip('Semua', _selectedCategory == null, () {
              setState(() => _selectedCategory = null);
            }),
            const SizedBox(width: 8),
            ..._categories.map((category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                _categoryLabel(category),
                _selectedCategory == category,
                () => setState(() => _selectedCategory = category),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF14532D) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(selected ? 0.08 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              onTap: () {
                print('[ProductCard] Tapped product: ${product.id} - ${product.productName}');
                context.push(RouteNames.productDetail(product.id));
              },
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Produk tidak ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci atau kategori lain',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280).withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? errorMessage, VoidCallback onRetry) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal memuat produk',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Terjadi kesalahan saat memuat data',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF6B7280).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  final ProductModel product;
  final VoidCallback onTap;

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  if (product.isLowStock)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          'Stok ${product.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(product.price),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ],
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
        child: Icon(Icons.image_outlined, size: 48, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}
