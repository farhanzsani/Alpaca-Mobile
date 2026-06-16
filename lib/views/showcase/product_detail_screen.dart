import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _businessName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().loadProductById(widget.productId);
    });
  }

  Future<void> _loadBusinessName(String ownerId) async {
    final businessName = await context.read<LocationViewModel>().getBusinessNameByOwner(ownerId);
    if (mounted) {
      setState(() {
        _businessName = businessName;
      });
    }
  }

  String _formatPrice(double price) {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  String _categoryLabel(String category) {
    const labels = {
      'food': 'Makanan',
      'beverage': 'Minuman',
      'handicraft': 'Kerajinan',
      'agriculture': 'Pertanian',
      'other': 'Lainnya',
    };
    return labels[category] ?? 'Lainnya';
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final product = productVm.selectedProduct;

    // Load business name when product is loaded
    if (product != null && _businessName == null) {
      _loadBusinessName(product.ownerId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: product == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
          : CustomScrollView(
              slivers: [
                _buildAppBar(context, product),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductHeader(product),
                      _buildDivider(),
                      _buildDescription(product),
                      if (product.description != null) _buildDivider(),
                      _buildStockInfo(product),
                      _buildDivider(),
                      _buildStoreSection(context, product),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar(BuildContext context, ProductModel product) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: const Color(0xFF14532D),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product_${product.id}',
          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
              ? Image.network(
                  product.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 80, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  Widget _buildProductHeader(ProductModel product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
            ),
            child: Text(
              _categoryLabel(product.category),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF14532D),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.productName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14532D),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(product.price),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14532D),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ ${product.unit}',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF6B7280).withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ProductModel product) {
    if (product.description == null || product.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deskripsi Produk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.description!,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo(ProductModel product) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: product.isLowStock
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              product.isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: product.isLowStock ? const Color(0xFFDC2626) : const Color(0xFF22C55E),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.isLowStock ? 'Stok Terbatas' : 'Stok Tersedia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: product.isLowStock ? const Color(0xFFDC2626) : const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.quantity} ${product.unit} tersedia',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSection(BuildContext context, ProductModel product) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14532D), Color(0xFF166534)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14532D).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(RouteNames.storeProfile(product.ownerId)),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _businessName ?? 'Kunjungi Toko',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _businessName != null ? 'Lihat produk lainnya' : 'Memuat info toko...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF86EFAC),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: const Color(0xFFF8FAFC),
    );
  }
}
