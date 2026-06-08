/// Business map screen for the public showcase.
///
/// Displays all registered business locations on a Google Map
/// with markers and an optional list view toggle.
library;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';

import 'package:alpaca_mobile/core/routes/route_names.dart';
import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/core/widgets/platform_map.dart';
import 'package:alpaca_mobile/models/business_location_model.dart';
import 'package:alpaca_mobile/viewmodels/location_view_model.dart';

/// Screen showing all business locations on a map.
///
/// Features:
/// - Google Maps showing all business locations as markers
/// - Tap marker to see business info
/// - List view toggle showing businesses as cards
/// - Uses LocationViewModel (loadAllBusinesses)
class BusinessMapScreen extends StatefulWidget {
  /// Creates a [BusinessMapScreen].
  const BusinessMapScreen({super.key});

  @override
  State<BusinessMapScreen> createState() => _BusinessMapScreenState();
}

class _BusinessMapScreenState extends State<BusinessMapScreen> {
  GoogleMapController? _mapController;
  bool _showListView = false;
  BusinessLocationModel? _selectedBusiness;

  /// Default center position (Indonesia).
  static const _defaultCenter = LatLng(-2.5489, 118.0149);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationViewModel>().loadAllBusinesses();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<BusinessLocationModel> businesses) {
    return businesses.map((business) {
      return Marker(
        markerId: MarkerId(business.id),
        position: LatLng(business.latitude, business.longitude),
        infoWindow: InfoWindow(
          title: business.businessName,
          snippet: business.address,
        ),
        onTap: () {
          setState(() => _selectedBusiness = business);
        },
      );
    }).toSet();
  }

  void _animateToLocation(BusinessLocationModel business) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(business.latitude, business.longitude),
        16,
      ),
    );
    setState(() {
      _selectedBusiness = business;
      _showListView = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationVm = context.watch<LocationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Bisnis'),
        actions: [
          IconButton(
            icon: Icon(
              _showListView ? Icons.map_outlined : Icons.list_outlined,
            ),
            tooltip: _showListView ? 'Tampilan Peta' : 'Tampilan Daftar',
            onPressed: () {
              setState(() => _showListView = !_showListView);
            },
          ),
        ],
      ),
      body: _buildBody(locationVm),
    );
  }

  Widget _buildBody(LocationViewModel locationVm) {
    if (locationVm.isLoading && locationVm.allBusinesses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (locationVm.error != null && locationVm.allBusinesses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                locationVm.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => locationVm.loadAllBusinesses(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (locationVm.allBusinesses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada bisnis terdaftar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Lokasi bisnis UMKM lokal akan ditampilkan di peta ini',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showListView) {
      return _buildListView(locationVm.allBusinesses);
    }

    return _buildMapView(locationVm.allBusinesses);
  }

  Widget _buildMapView(List<BusinessLocationModel> businesses) {
    // Calculate initial camera position based on businesses
    final initialTarget = businesses.isNotEmpty
        ? LatLng(businesses.first.latitude, businesses.first.longitude)
        : _defaultCenter;

    return Stack(
      children: [
        PlatformMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: businesses.length == 1 ? 14 : 5,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            // Fit all markers in view if multiple businesses
            if (businesses.length > 1) {
              _fitAllMarkers(businesses);
            }
          },
          markers: _buildMarkers(businesses),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onTap: (_) {
            setState(() => _selectedBusiness = null);
          },
        ),

        // Selected business info card
        if (_selectedBusiness != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _BusinessInfoCard(
              business: _selectedBusiness!,
              onClose: () {
                setState(() => _selectedBusiness = null);
              },
            ),
          ),

        // Business count badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.store, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${businesses.length} bisnis',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _fitAllMarkers(List<BusinessLocationModel> businesses) {
    if (businesses.isEmpty) return;

    double minLat = businesses.first.latitude;
    double maxLat = businesses.first.latitude;
    double minLng = businesses.first.longitude;
    double maxLng = businesses.first.longitude;

    for (final business in businesses) {
      if (business.latitude < minLat) minLat = business.latitude;
      if (business.latitude > maxLat) maxLat = business.latitude;
      if (business.longitude < minLng) minLng = business.longitude;
      if (business.longitude > maxLng) maxLng = business.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 60),
      );
    });
  }

  Widget _buildListView(List<BusinessLocationModel> businesses) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: businesses.length,
      itemBuilder: (context, index) {
        final business = businesses[index];
        return _BusinessListCard(
          business: business,
          onTap: () => _animateToLocation(business),
        );
      },
    );
  }
}

/// Card showing business info when a marker is tapped.
class _BusinessInfoCard extends StatelessWidget {
  const _BusinessInfoCard({
    required this.business,
    required this.onClose,
  });

  final BusinessLocationModel business;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: business.imageUrl != null
                      ? NetworkImage(business.imageUrl!)
                      : null,
                  child: business.imageUrl == null
                      ? const Icon(
                          Icons.store,
                          size: 20,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.businessName,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        business.address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (business.description != null &&
                business.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                business.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => context.push(
                  RouteNames.storeProfile(business.ownerId),
                ),
                icon: const Icon(Icons.storefront_outlined, size: 16),
                label: const Text('Lihat Toko'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A list card for the list view toggle.
class _BusinessListCard extends StatelessWidget {
  const _BusinessListCard({
    required this.business,
    required this.onTap,
  });

  final BusinessLocationModel business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryContainer,
          backgroundImage: business.imageUrl != null
              ? NetworkImage(business.imageUrl!)
              : null,
          child: business.imageUrl == null
              ? const Icon(
                  Icons.store_outlined,
                  color: AppColors.primary,
                )
              : null,
        ),
        title: Text(
          business.businessName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    business.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (business.description != null &&
                business.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                business.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
