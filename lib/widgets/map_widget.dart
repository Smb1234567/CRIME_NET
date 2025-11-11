import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import '../models/report_model.dart';

class CrimeMapWidget extends StatefulWidget {
  final List<CrimeReport> reports;
  final LatLng? currentLocation;
  final bool showHeatMap;
  final Function(CrimeReport)? onReportTap;

  const CrimeMapWidget({
    Key? key,
    required this.reports,
    this.currentLocation,
    this.showHeatMap = false,
    this.onReportTap,
  }) : super(key: key);

  @override
  State<CrimeMapWidget> createState() => _CrimeMapWidgetState();
}

class _CrimeMapWidgetState extends State<CrimeMapWidget> {
  final PopupController _popupLayerController = PopupController();
  final MapController _mapController = MapController();

  // Default to Bangalore coordinates
  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946);
  static const double _defaultZoom = 12.0;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: widget.currentLocation ?? _defaultCenter,
        zoom: _defaultZoom,
        onTap: (_, __) => _popupLayerController.hideAllPopups(),
      ),
      children: [
        // OpenStreetMap Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.crime_net',
        ),

        // Current Location Marker
        if (widget.currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 40,
                height: 40,
                point: widget.currentLocation!,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ],
          ),

        // Crime Report Markers
        PopupMarkerLayer(
          options: PopupMarkerLayerOptions(
            popupController: _popupLayerController,
            markers: _buildReportMarkers(),
            popupDisplayOptions: PopupDisplayOptions(
              builder: (BuildContext context, Marker marker) {
                return _buildPopupContent(marker);
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Marker> _buildReportMarkers() {
    return widget.reports.map((report) {
      final reportPoint = LatLng(report.latitude, report.longitude);

      return Marker(
        point: reportPoint,
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            if (widget.onReportTap != null) {
              widget.onReportTap!(report);
            }
          },
          child: _buildReportIcon(report),
        ),
      );
    }).toList();
  }

  Widget _buildReportIcon(CrimeReport report) {
    // Different icons based on report type and priority
    Color color;
    IconData icon;

    switch (report.priority) {
      case 5: // Emergency
        color = Colors.purple;
        icon = Icons.warning_amber;
        break;
      case 4: // Urgent
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 3: // High
        color = Colors.orange;
        icon = Icons.error_outline;
        break;
      case 2: // Medium
        color = Colors.blue;
        icon = Icons.info_outline;
        break;
      default: // Low
        color = Colors.green;
        icon = Icons.location_on;
    }

    // Different icons for different crime types
    if (report.type == 'suspicious_vehicle') {
      icon = Icons.directions_car;
    } else if (report.type == 'theft') {
      icon = Icons.money_off;
    } else if (report.type == 'vandalism') {
      icon = Icons.spatial_audio_off;
    } else if (report.type == 'drug_activity') {
      icon = Icons.medical_services;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildPopupContent(Marker marker) {
    // Find the report for this marker
    final report = widget.reports.firstWhere(
      (r) => LatLng(r.latitude, r.longitude) == marker.point,
    );

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            report.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            report.type.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              color: _getPriorityColor(report.priority),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.description.length > 100
                ? '${report.description.substring(0, 100)}...'
                : report.description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatTimeAgo(report.reportedAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.purple;
      case 4:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'action_taken':
        return Colors.blue;
      case 'false_alarm':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
