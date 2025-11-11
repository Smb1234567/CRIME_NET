import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/report_model.dart';
import '../../services/local_storage_service.dart';
import '../../services/location_service.dart';
import '../../widgets/map_widget.dart';

class CitizenMapScreen extends StatefulWidget {
  const CitizenMapScreen({Key? key}) : super(key: key);

  @override
  State<CitizenMapScreen> createState() => _CitizenMapScreenState();
}

class _CitizenMapScreenState extends State<CitizenMapScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final LocationService _locationService = LocationService();
  
  List<CrimeReport> _reports = [];
  LatLng? _currentLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load reports
      final reports = await _storageService.getReports();
      
      // Get current location
      final position = await _locationService.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _reports = reports;
        _currentLocation = location;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading map data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CrimeMapWidget(
              reports: _reports,
              currentLocation: _currentLocation,
              onReportTap: _showReportDetails,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _centerOnLocation() {
    // Would implement map controller to center on location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Centering on your location')),
    );
  }

  void _showReportDetails(CrimeReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${report.type}'),
            Text('Priority: ${report.priority}'),
            Text('Status: ${report.status}'),
            const SizedBox(height: 8),
            Text(report.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}