import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// A cross-platform map widget that uses Google Maps on Android/iOS/Web
/// and shows a fallback with OpenStreetMap link on Windows (unsupported).
class PlatformMap extends StatelessWidget {
  const PlatformMap({
    required this.initialCameraPosition,
    this.onMapCreated,
    this.markers = const {},
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = true,
    this.mapToolbarEnabled = true,
    this.onTap,
    this.fallbackMarkers = const [],
    super.key,
  });

  final CameraPosition initialCameraPosition;
  final void Function(GoogleMapController controller)? onMapCreated;
  final Set<Marker> markers;
  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final void Function(LatLng position)? onTap;

  /// Extra list of marker positions to show in fallback (if not in [markers]).
  final List<LatLng> fallbackMarkers;

  bool get _isWindows => Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    if (_isWindows) {
      return _WindowsMapFallback(
        initialPosition: initialCameraPosition.target,
        markers: markers,
        fallbackMarkers: fallbackMarkers,
      );
    }
    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      onMapCreated: onMapCreated,
      markers: markers,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      mapToolbarEnabled: mapToolbarEnabled,
      onTap: onTap,
    );
  }
}

class _WindowsMapFallback extends StatelessWidget {
  const _WindowsMapFallback({
    required this.initialPosition,
    required this.markers,
    required this.fallbackMarkers,
  });

  final LatLng initialPosition;
  final Set<Marker> markers;
  final List<LatLng> fallbackMarkers;

  List<LatLng> get _allPositions {
    final positions = <LatLng>{};
    for (final m in markers) {
      positions.add(m.position);
    }
    positions.addAll(fallbackMarkers);
    if (positions.isEmpty) {
      positions.add(initialPosition);
    }
    return positions.toList();
  }

  Future<void> _openInBrowser(LatLng pos) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${pos.latitude}&mlon=${pos.longitude}#map=16/${pos.latitude}/${pos.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final positions = _allPositions;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Peta tidak tersedia di Windows',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Gunakan perangkat Android atau iOS untuk melihat peta interaktif.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (positions.length == 1) ...[
                Text(
                  '${positions.first.latitude.toStringAsFixed(6)}, ${positions.first.longitude.toStringAsFixed(6)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _openInBrowser(positions.first),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Buka di OpenStreetMap'),
                ),
              ] else ...[
                Text(
                  '${positions.length} lokasi tertandai',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                ...positions.map((pos) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: InkWell(
                        onTap: () => _openInBrowser(pos),
                        child: Text(
                          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
