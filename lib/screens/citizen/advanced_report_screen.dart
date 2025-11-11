import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import '../../models/report_model.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';

class AdvancedReportScreen extends StatefulWidget {
  const AdvancedReportScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedReportScreen> createState() => _AdvancedReportScreenState();
}

class _AdvancedReportScreenState extends State<AdvancedReportScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  LatLng? _currentLocation;
  String _selectedType = 'suspicious_vehicle';
  int _priority = 3;
  bool _isAnonymous = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      // Center map on current location
      _mapController.move(_currentLocation!, 15.0);
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _centerOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  CrimeReport _createReport() {
    return CrimeReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.isNotEmpty 
          ? _titleController.text 
          : AppConstants.reportTypes.firstWhere(
              (type) => type['value'] == _selectedType)['label']!,
      description: _descriptionController.text,
      type: _selectedType,
      latitude: _currentLocation?.latitude ?? 0.0,
      longitude: _currentLocation?.longitude ?? 0.0,
      address: 'Current Location',
      reporterId: 'anonymous',
      isAnonymous: _isAnonymous,
      reportedAt: DateTime.now(),
      priority: _priority,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Incident',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _centerOnLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: _buildMapSection(),
          ),
          // Form Section
          Expanded(
            flex: 3,
            child: _buildFormSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _currentLocation ?? const LatLng(12.9716, 77.5946),
            zoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.crime_net',
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
        // Current Location Button
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _centerOnLocation,
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(Icons.my_location, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Incident Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Incident Type
              _buildTypeSelector(),
              const SizedBox(height: 16),
              
              // Title
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Brief title for the incident',
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  hintText: 'Describe what happened in detail...',
                ),
              ),
              const SizedBox(height: 16),
              
              // Priority
              _buildPrioritySelector(),
              const SizedBox(height: 16),
              
              // Anonymous Toggle
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value ?? true;
                      });
                    },
                  ),
                  const Text('Report Anonymously'),
                ],
              ),
              const SizedBox(height: 20),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please provide a description'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    final report = _createReport();
                    Navigator.pop(context, report);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incident Type *',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.reportTypes.map((type) {
            final isSelected = _selectedType == type['value'];
            return ChoiceChip(
              label: Text(type['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedType = type['value']!;
                });
              },
              backgroundColor: Colors.grey[300],
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Level *',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 3, 4, 5].map((level) {
            final isSelected = _priority == level;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _priority = level;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected 
                        ? AppConstants.priorityColors[level]
                        : Colors.grey[300],
                    foregroundColor: isSelected ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '${AppConstants.priorityLabels[level]}\n($level)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}