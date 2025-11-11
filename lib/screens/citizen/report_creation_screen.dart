import 'package:flutter/material.dart';
import 'package:crime_net/utils/constants.dart';
import 'package:crime_net/services/location_service.dart';
import 'package:crime_net/services/local_storage_service.dart';
import 'package:crime_net/services/offline_service.dart';

class ReportCreationScreen extends StatefulWidget {
  const ReportCreationScreen({super.key});

  @override
  State<ReportCreationScreen> createState() => _ReportCreationScreenState();
}

class _ReportCreationScreenState extends State<ReportCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();

  String _selectedType = 'suspicious_vehicle';
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isGettingLocation = false;
  double? _currentLat;
  double? _currentLng;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _locationController.text =
            'Near ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location detected successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isGettingLocation = false;
    });
  }

  void _openLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Selection'),
        content: const Text(
          'For now, please use the "Use Current Location" button or type the address manually. Map feature will be added in the next update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submitReport() async {
    // Generate a unique ID for the report
    final reportId = DateTime.now().millisecondsSinceEpoch.toString();

    final report = CrimeReport(
      id: reportId,
      title:
          AppConstants.reportTypes.firstWhere(
            (type) => type['value'] == _selectedType,
          )['label'] ??
          'Incident',
      description: _descriptionController.text,
      type: _selectedType,
      latitude: _currentLat ?? 0.0,
      longitude: _currentLng ?? 0.0,
      address: _locationController.text.isNotEmpty
          ? _locationController.text
          : 'Location not specified',
      reporterId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
      reportedAt: DateTime.now(),
      status: 'pending',
      priority: 1,
      imageUrls: [],
      verificationCount: 0,
    );

    try {
      // Save to local storage
      final storage = LocalStorageService();
      await storage.saveReport(report);

      // Save for offline sync
      final offlineService = OfflineService();
      await offlineService.saveOfflineReport(report);

      // Share via P2P (simulated)
      await offlineService.shareViaP2P(report);

      print('📱 Report saved offline and queued for sync: ${report.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully! (Offline Mode)'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('❌ Error saving report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What happened?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Incident Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: AppConstants.reportTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(type['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Incident Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
              ),

              const SizedBox(height: 16),

              // Location with auto-detect button
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Enter address or use current location',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isGettingLocation
                      ? const CircularProgressIndicator()
                      : IconButton(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          tooltip: 'Use current location',
                        ),
                ],
              ),
              const SizedBox(height: 8),
              if (_currentLat != null && _currentLng != null)
                Text(
                  '📍 Coordinates: ${_currentLat!.toStringAsFixed(4)}, ${_currentLng!.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe what you saw...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _submitReport();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
