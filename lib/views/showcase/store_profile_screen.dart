/// Professional store profile with modern storefront design.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/widgets/platform_map.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/models/product_model.dart';
import 'package:alpaca_mobile/services/favorites_service.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';
import 'package:alpaca_mobile/viewmodels/media_view_model.dart';
import 'package:alpaca_mobile/viewmodels/product_view_model.dart';
import 'package:alpaca_mobile/core/enums/view_state.dart';

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key, required this.ownerId});

  final String ownerId;

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  int _currentMediaPage = 0;
  String? _favoriteBusinessId;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();
    print('[StoreProfileScreen] initState - ownerId: ${widget.ownerId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[StoreProfileScreen] postFrameCallback - loading data');
      _loadData();
    });
  }

  void _loadData() async {
    print('[StoreProfileScreen] _loadData start');
    context.read<LocationViewModel>().loadProfileBusiness(widget.ownerId);
    context.read<ProductViewModel>().loadStoreProducts(widget.ownerId);
    context.read<MediaViewModel>().loadMediaByOwner(widget.ownerId);
    print('[StoreProfileScreen] _loadData end');
  }

  Future<void> _loadFavoriteStatus(String businessId) async {
    if (_favoriteBusinessId == businessId) return;

    _favoriteBusinessId = businessId;
    final isFavorite = await _favoritesService.isFavoriteItem(
      businessId,
      'business',
    );

    if (!mounted || _favoriteBusinessId != businessId) return;
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggleFavorite(String businessId) async {
    if (_isFavoriteLoading) return;

    setState(() => _isFavoriteLoading = true);
    final result = await _favoritesService.toggleFavoriteItem(
      businessId,
      'business',
    );

    if (!mounted) return;

    result.when(
      success: (isFavorite) {
        setState(() {
          _isFavorite = isFavorite;
          _isFavoriteLoading = false;
        });
      },
      failure: (exception) {
        setState(() => _isFavoriteLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      },
    );
  }

  void _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedPhone = cleanPhone;
    if (!cleanPhone.startsWith('62')) {
      if (cleanPhone.startsWith('0')) {
        formattedPhone = '62${cleanPhone.substring(1)}';
      } else {
        formattedPhone = '62$cleanPhone';
      }
    }

    final url = 'https://wa.me/$formattedPhone';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationVm = context.watch<LocationViewModel>();
    final productVm = context.watch<ProductViewModel>();
    final business = locationVm.profileBusiness;

    // Handle error state
    if (locationVm.viewState == ViewState.error) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF14532D),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Profil Toko',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF9CA3AF),
              ),
              const SizedBox(height: 16),
              Text(
                locationVm.error ?? 'Gagal memuat data toko',
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadData(),
                child: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Handle loading state
    if (business == null && locationVm.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF14532D),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Profil Toko',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF22C55E)),
              SizedBox(height: 16),
              Text(
                'Memuat data toko...',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    // Handle empty state
    if (business == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF14532D),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Profil Toko',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, size: 64, color: Color(0xFF9CA3AF)),
              SizedBox(height: 16),
              Text(
                'Toko tidak ditemukan',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    _loadFavoriteStatus(business.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, business),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStoreHeader(business),
                const SizedBox(height: 12),
                _buildLocationCard(business),
                const SizedBox(height: 12),
                _buildProductsSection(productVm),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, BusinessLocationModel business) {
    final mediaVm = context.watch<MediaViewModel>();
    final hasMedia = mediaVm.mediaItems.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 280,
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
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1F2937),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              tooltip: _isFavorite ? 'Hapus dari favorit' : 'Tambah ke favorit',
              icon: _isFavoriteLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF22C55E),
                      ),
                    )
                  : Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isFavorite
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF1F2937),
                    ),
              onPressed: () => _toggleFavorite(business.id),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Media carousel or fallback image
            if (hasMedia)
              PageView.builder(
                itemCount: mediaVm.mediaItems.length,
                onPageChanged: (index) {
                  if (mounted) {
                    setState(() => _currentMediaPage = index);
                  }
                },
                itemBuilder: (context, index) {
                  final media = mediaVm.mediaItems[index];
                  return Image.network(
                    media.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildStorePlaceholder(),
                  );
                },
              )
            else if (business.imageUrl != null && business.imageUrl!.isNotEmpty)
              Image.network(
                business.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildStorePlaceholder(),
              )
            else
              _buildStorePlaceholder(),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Page indicator for media carousel
            if (hasMedia && mediaVm.mediaItems.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    mediaVm.mediaItems.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentMediaPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorePlaceholder() {
    return Container(
      color: const Color(0xFF14532D),
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 80,
          color: Color(0xFF86EFAC),
        ),
      ),
    );
  }

  Widget _buildStoreHeader(BusinessLocationModel business) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business.businessName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF14532D),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 20,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  business.address,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (business.description != null &&
              business.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              business.description!,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF4B5563),
                height: 1.6,
              ),
            ),
          ],
          if (business.ownerPhone != null &&
              business.ownerPhone!.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsApp(business.ownerPhone!),
                icon: const Icon(Icons.phone, size: 20),
                label: const Text('Hubungi via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(BusinessLocationModel business) {
    final position = LatLng(business.latitude, business.longitude);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: PlatformMap(
        initialCameraPosition: (target: position, zoom: 16.0),
        markers: [
          Marker(
            point: position,
            width: 80,
            height: 80,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        ],
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }

  Widget _buildProductsSection(ProductViewModel productVm) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produk Toko',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF14532D),
                ),
              ),
              Text(
                '${productVm.storeProducts.length} produk',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (productVm.storeProducts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Belum ada produk',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: productVm.storeProducts.length,
              itemBuilder: (context, index) {
                final product = productVm.storeProducts[index];
                return _ProductCard(
                  product: product,
                  onTap: () =>
                      context.push(RouteNames.productDetail(product.id)),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatPrice(product.price),
                    style: const TextStyle(
                      fontSize: 15,
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
        child: Icon(Icons.image_outlined, size: 40, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}
