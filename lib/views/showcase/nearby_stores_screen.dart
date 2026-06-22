/// Nearby stores screen — map-first with bottom sheet detail.
///
/// Fetches user's GPS location, calls the nearby endpoint, displays
/// store pins on a Google Map, and shows a bottom-sheet on marker tap.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/widgets/platform_map.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

/// Displays nearby stores on a map with a bottom-sheet info card on tap.
class NearbyStoresScreen extends StatefulWidget {
  const NearbyStoresScreen({super.key});

  @override
  State<NearbyStoresScreen> createState() => _NearbyStoresScreenState();
}

class _NearbyStoresScreenState extends State<NearbyStoresScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  BusinessLocationModel? _selectedStore;
  bool _isLocating = false;
  String? _locationError;

  // Animation controller for bottom sheet slide-in
  late AnimationController _sheetAnimController;
  late Animation<Offset> _sheetSlideAnim;

  static const _defaultCenter = LatLng(-7.5, 110.0); // Tengah Jawa

  @override
  void initState() {
    super.initState();
    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sheetSlideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sheetAnimController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetAnimController.dispose();
    super.dispose();
  }

  // ─── Location & Data ───────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final vm = context.read<LocationViewModel>();
      final pos = await vm.getCurrentDeviceLocation();

      // Animate camera to user's position
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        13,
      );

      // Fetch nearby stores
      await vm.loadNearbyStores(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _locationError = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ─── Markers ───────────────────────────────────────────────────────────────

  List<Marker> _buildMarkers(
    List<BusinessLocationModel> stores,
    BusinessLocationModel? selected,
  ) {
    return stores.map((store) {
      final isSelected = selected?.id == store.id;
      return Marker(
        point: LatLng(store.latitude, store.longitude),
        width: isSelected ? 48 : 36,
        height: isSelected ? 48 : 36,
        child: GestureDetector(
          onTap: () => _onMarkerTap(store),
          child: Icon(
            Icons.location_on,
            size: isSelected ? 48 : 36,
            color: isSelected ? Colors.green : Colors.orange,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
      );
    }).toList();
  }

  void _onMarkerTap(BusinessLocationModel store) {
    setState(() => _selectedStore = store);
    _mapController.move(
      LatLng(store.latitude, store.longitude), 15,
    );
    _sheetAnimController.forward(from: 0);
  }

  void _dismissSheet() {
    _sheetAnimController.reverse().then((_) {
      if (mounted) setState(() => _selectedStore = null);
    });
  }

  // ─── Distance helper ───────────────────────────────────────────────────────

  String _formatDistance(BusinessLocationModel store, LocationViewModel vm) {
    final pos = vm.currentPosition;
    if (pos == null) return '';
    final d = _haversineKm(pos.latitude, pos.longitude, store.latitude, store.longitude);
    if (d < 1) return '${(d * 1000).round()} m';
    return '${d.toStringAsFixed(1)} km';
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * math.pi / 180;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationViewModel>();
    final stores = vm.nearbyStores;
    final pos = vm.currentPosition;

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────────────────
          PlatformMap(
            initialCameraPosition: (
              target: pos != null
                  ? LatLng(pos.latitude, pos.longitude)
                  : _defaultCenter,
              zoom: 13,
            ),
            mapController: _mapController,
            markers: _buildMarkers(stores, _selectedStore),
            onTap: (_) {
              if (_selectedStore != null) _dismissSheet();
            },
          ),

          // ── Top Header Bar ─────────────────────────────────────────────
          _buildTopBar(stores),

          // ── Loading overlay ────────────────────────────────────────────
          if (_isLocating) _buildLoadingOverlay(),

          // ── Error overlay ──────────────────────────────────────────────
          if (_locationError != null && !_isLocating)
            _buildErrorOverlay(_locationError!),

          // ── API error snack (non-blocking) ─────────────────────────────
          if (vm.nearbyError != null && !vm.nearbyLoading && !_isLocating)
            _buildNearbyErrorBanner(vm.nearbyError!),

          // ── Store count badge ──────────────────────────────────────────
          if (!_isLocating && _locationError == null && stores.isNotEmpty)
            _buildStoreBadge(stores.length),

          // ── FAB: My Location ───────────────────────────────────────────
          _buildMyLocationFab(),

          // ── Bottom Sheet Card ──────────────────────────────────────────
          if (_selectedStore != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _sheetSlideAnim,
                child: _StoreBottomSheet(
                  store: _selectedStore!,
                  distance: _formatDistance(_selectedStore!, vm),
                  onClose: _dismissSheet,
                  onViewProfile: () {
                    _dismissSheet();
                    context.push(RouteNames.storeProfile(_selectedStore!.ownerId));
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildTopBar(List<BusinessLocationModel> stores) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Title
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Toko Terdekat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                    ),
                  ),
                  Text(
                    'Tap pin untuk melihat detail toko',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildStoreBadge(int count) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count toko ditemukan',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLocationFab() {
    return Positioned(
      bottom: _selectedStore != null ? 240 : 24,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Refresh button
          _FabButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Perbarui toko terdekat',
            onPressed: _isLocating ? null : _initLocation,
            color: const Color(0xFF14532D),
          ),
          const SizedBox(height: 8),
          // My location button
          _FabButton(
            icon: Icons.my_location_rounded,
            tooltip: 'Ke lokasi saya',
            onPressed: () {
              final pos = context.read<LocationViewModel>().currentPosition;
              if (pos != null) {
                _mapController.move(
                  LatLng(pos.latitude, pos.longitude),
                  14,
                );
              }
            },
            color: const Color(0xFF1E40AF),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF22C55E)),
                SizedBox(height: 16),
                Text(
                  'Mencari lokasi Anda...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Memuat toko terdekat',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(String error) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initLocation,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14532D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyErrorBanner(String error) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 64,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAB Button ─────────────────────────────────────────────────────────────

class _FabButton extends StatelessWidget {
  const _FabButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed == null ? const Color(0xFF9CA3AF) : color,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─── Store Bottom Sheet ───────────────────────────────────────────────────────

class _StoreBottomSheet extends StatelessWidget {
  const _StoreBottomSheet({
    required this.store,
    required this.distance,
    required this.onClose,
    required this.onViewProfile,
  });

  final BusinessLocationModel store;
  final String distance;
  final VoidCallback onClose;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store image / avatar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: store.imageUrl != null && store.imageUrl!.isNotEmpty
                          ? Image.network(
                              store.imageUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildAvatarPlaceholder(),
                            )
                          : _buildAvatarPlaceholder(),
                    ),
                    const SizedBox(width: 14),

                    // Name & address
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.businessName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF14532D),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (distance.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.near_me_rounded,
                                    size: 12,
                                    color: Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    distance,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF9CA3AF),
                      onPressed: onClose,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

                // Description
                if (store.description != null && store.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    store.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 16),

                // View profile button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewProfile,
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Lihat Profil Toko'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14532D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.storefront_rounded, size: 30, color: Color(0xFF16A34A)),
    );
  }
}
