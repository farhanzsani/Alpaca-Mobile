import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';
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
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _favoritesService.getFavoriteItems();

    if (!mounted) return;
    result.when(
      success: (favorites) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      },
      failure: (exception) {
        setState(() {
          _error = exception.message;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _removeFavorite(FavoriteItem favorite) async {
    final result = await _favoritesService.removeFavoriteItem(
      favorite.itemId,
      favorite.itemType,
    );

    if (!mounted) return;
    result.when(
      success: (_) => _loadFavorites(),
      failure: (exception) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _favorites
        .where((favorite) => favorite.product != null)
        .map((favorite) => (favorite: favorite, product: favorite.product!))
        .toList();
    final businesses = _favorites
        .where((favorite) => favorite.business != null)
        .map((favorite) => (favorite: favorite, business: favorite.business!))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(_favorites.length),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF22C55E)),
                  )
                : _error != null
                ? _buildErrorState()
                : _favorites.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFF22C55E),
                    onRefresh: _loadFavorites,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (products.isNotEmpty) ...[
                          _buildSectionTitle('Produk Favorit', products.length),
                          const SizedBox(height: 12),
                          ...products.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProductFavoriteCard(
                                product: entry.product,
                                onTap: () => context.push(
                                  RouteNames.productDetail(entry.product.id),
                                ),
                                onRemove: () => _removeFavorite(entry.favorite),
                              ),
                            ),
                          ),
                        ],
                        if (businesses.isNotEmpty) ...[
                          _buildSectionTitle('Toko Favorit', businesses.length),
                          const SizedBox(height: 12),
                          ...businesses.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BusinessFavoriteCard(
                                business: entry.business,
                                onTap: () => context.push(
                                  RouteNames.storeProfile(
                                    entry.business.ownerId,
                                  ),
                                ),
                                onRemove: () => _removeFavorite(entry.favorite),
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
    );
  }

  Widget _buildHeader(int count) {
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
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
                      'Favorit',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Produk dan toko yang Anda simpan',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86EFAC),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count item',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF14532D),
              ),
            ),
          ),
          Text(
            '$count item',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Gagal memuat favorit',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 72,
              color: Color(0xFF22C55E),
            ),
            SizedBox(height: 20),
            Text(
              'Belum ada favorit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Simpan produk atau toko favorit Anda\nuntuk akses cepat di sini',
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
}

class _ProductFavoriteCard extends StatelessWidget {
  const _ProductFavoriteCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  String _formatPrice(double price) {
    final formatted = price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return _FavoriteCardShell(
      onTap: onTap,
      onRemove: onRemove,
      leading: product.imageUrl != null && product.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                errorBuilder: (_, _, _) => _IconBox(icon: Icons.image_outlined),
              ),
            )
          : _IconBox(icon: Icons.image_outlined),
      title: product.productName,
      subtitle: '${_formatPrice(product.price)} / ${product.unit}',
    );
  }
}

class _BusinessFavoriteCard extends StatelessWidget {
  const _BusinessFavoriteCard({
    required this.business,
    required this.onTap,
    required this.onRemove,
  });

  final BusinessLocationModel business;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _FavoriteCardShell(
      onTap: onTap,
      onRemove: onRemove,
      leading: const _IconBox(icon: Icons.store_rounded),
      title: business.businessName,
      subtitle: business.address,
    );
  }
}

class _FavoriteCardShell extends StatelessWidget {
  const _FavoriteCardShell({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onRemove,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.favorite_rounded),
                color: const Color(0xFFDC2626),
                iconSize: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF22C55E), size: 28),
    );
  }
}
