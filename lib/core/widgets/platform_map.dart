import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// A cross-platform map widget that uses flutter_map with OpenStreetMap tiles.
class PlatformMap extends StatelessWidget {
  const PlatformMap({
    required this.initialCameraPosition,
    this.onMapCreated,
    this.markers = const [],
    this.mapController,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = true,
    this.mapToolbarEnabled = true,
    this.onTap,
    super.key,
  });

  /// Digunakan untuk zoom level & posisi tengah peta
  final ({LatLng target, double zoom}) initialCameraPosition;
  
  /// Callback dipanggil setelah Map siap (namun flutter_map biasanya di-handle dengan MapController eksternal)
  final void Function(MapController controller)? onMapCreated;
  
  /// External MapController
  final MapController? mapController;
  
  /// Marker flutter_map
  final List<Marker> markers;
  
  // Beberapa pengaturan diabaikan karena ditangani manual oleh flutter_map
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  
  final void Function(LatLng position)? onTap;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCameraPosition.target,
        initialZoom: initialCameraPosition.zoom,
        onTap: (tapPosition, point) {
          if (onTap != null) onTap!(point);
        },
        onMapReady: () {
          if (onMapCreated != null && mapController != null) {
            onMapCreated!(mapController!);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.alpaca_mobile',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: markers,
        ),
        // Tambahan tombol atribusi (wajib untuk OSM)
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),
      ],
    );
  }
}
