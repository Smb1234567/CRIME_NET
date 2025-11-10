import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CrimeNetMap extends StatefulWidget {
  final LatLng? initialCenter;
  final List<MapMarker>? markers;
  final Function(LatLng)? onTap;

  const CrimeNetMap({super.key, this.initialCenter, this.markers, this.onTap});

  @override
  State<CrimeNetMap> createState() => _CrimeNetMapState();
}

class _CrimeNetMapState extends State<CrimeNetMap> {
  late MapController _mapController;
  LatLng? _currentCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = widget.initialCenter ?? const LatLng(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _currentCenter,
        zoom: 13.0,
        onTap: (tapPosition, point) {
          widget.onTap?.call(point);
        },
      ),
      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.crime_net',
        ),
        // Markers
        if (widget.markers != null)
          MarkerLayer(
            markers: widget.markers!
                .map(
                  (marker) => Marker(
                    point: marker.position,
                    builder: (ctx) => marker.builder(ctx),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class MapMarker {
  final LatLng position;
  final WidgetBuilder builder;

  MapMarker({required this.position, required this.builder});
}

// Simple marker widget
class CrimeMarker extends StatelessWidget {
  final Color color;
  final String label;

  const CrimeMarker({super.key, this.color = Colors.red, this.label = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_pin, color: color, size: 40),
        if (label.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
