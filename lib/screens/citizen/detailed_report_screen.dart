import 'package:flutter/material.dart';
import 'package:crime_net/models/report_model.dart';
import 'package:crime_net/services/offline_service.dart';
import 'package:crime_net/services/local_storage_service.dart';
import 'package:crime_net/services/location_service.dart';
import 'package:crime_net/services/p2p_mesh_service.dart';
import 'package:latlong2/latlong.dart';

class DetailedReportScreen extends StatefulWidget {
  final LatLng? preFillLocation;
  final ReportModel? preFillData;

  const DetailedReportScreen({
    Key? key,
    this.preFillLocation,
    this.preFillData,
  }) : super(key: key);

  @override
  _DetailedReportScreenState createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _witnessController = TextEditingController();
  final _suspectController = TextEditingController();

  final OfflineService _offlineService = OfflineService();
  final LocalStorageService _storageService = LocalStorageService();
  final LocationService _locationService = LocationService();
  final P2PMeshService _p2pService = P2PMeshService();

  String _selectedCategory = 'Suspicious Activity';
  String _selectedPriority = 'Medium';
  String _selectedStatus = 'Pending';
  LatLng? _selectedLocation;
  bool _isAnonymous = true;
  bool _isUrgent = false;
  bool _isLoading = false;

  // Categories for dropdown
  final List<String> _categories = [
    'Suspicious Activity',
    'Theft',
    'Assault',
    'Vandalism',
    'Drug Activity',
    'Harassment',
    'Burglary',
    'Robbery',
    'Vehicle Theft',
    'Domestic Violence',
    'Cyber Crime',
    'Missing Person',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.preFillData != null) {
      _titleController.text = widget.preFillData!.title;
      _descriptionController.text = widget.preFillData!.description;
      _selectedCategory = widget.preFillData!.category;
      _selectedPriority = widget.preFillData!.priority;
      _isAnonymous = widget.preFillData!.isAnonymous;
    } else if (widget.preFillLocation != null) {
      _selectedLocation = widget.preFillLocation;
      _getAddressFromLatLng(widget.preFillLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
      _getAddressFromLatLng(_selectedLocation!);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      final address = await _locationService.getAddressFromLatLng(
        location.latitude,
        location.longitude,
      );
      setState(() {
        _locationController.text = address;
      });
    } catch (e) {
      print('Error getting address: $e');
      _locationController.text = 'Location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final crimeReport = CrimeReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedCategory.toLowerCase().replaceAll(' ', '_'),
        latitude: _selectedLocation?.latitude ?? 0.0,
        longitude: _selectedLocation?.longitude ?? 0.0,
        address: _locationController.text,
        reporterId: _isAnonymous ? 'anonymous' : 'citizen_${DateTime.now().millisecondsSinceEpoch}',
        isAnonymous: _isAnonymous,
        reportedAt: DateTime.now(),
        priority: _convertPriorityToNumber(_selectedPriority),
        status: _selectedStatus.toLowerCase(),
      );

      // Save locally
      await _storageService.saveReport(crimeReport);

      // Share via P2P mesh network
      await _p2pService.shareReport(crimeReport);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Report submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error submitting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _convertPriorityToNumber(String priority) {
    switch (priority) {
      case 'Low':
        return 1;
      case 'Medium':
        return 3;
      case 'High':
        return 4;
      case 'Critical':
        return 5;
      default:
        return 3; // Default to Medium
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Detailed Crime Report'),
        backgroundColor: Colors.grey[800],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.emergency, color: Colors.red),
            onPressed: () {
              setState(() {
                _selectedPriority = 'Critical';
                _isUrgent = true;
                _titleController.text = '🚨 EMERGENCY - Immediate Assistance Required';
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // Report Type & Priority
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Category',
                            _selectedCategory,
                            _categories,
                            (value) => setState(() => _selectedCategory = value!),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Priority',
                            _selectedPriority,
                            ['Low', 'Medium', 'High', 'Critical'],
                            (value) => setState(() => _selectedPriority = value!),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Report Title*',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[800],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Detailed Description*',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[800],
                        hintText: 'Describe what happened, when, where, and any important details...',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[800],
                        suffixIcon: IconButton(
                          icon: Icon(Icons.location_on),
                          onPressed: _getCurrentLocation,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Witness Information
                    TextFormField(
                      controller: _witnessController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Witness Information (Optional)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[800],
                        hintText: 'Number of witnesses, contact information...',
                      ),
                    ),
                    SizedBox(height: 16),

                    // Suspect Description
                    TextFormField(
                      controller: _suspectController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Suspect Description (Optional)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[800],
                        hintText: 'Physical description, clothing, vehicle...',
                      ),
                    ),
                    SizedBox(height: 20),

                    // Options
                    Card(
                      color: Colors.grey[800],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report Options',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 12),
                            SwitchListTile(
                              title: Text(
                                'Anonymous Report',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Your identity will be protected',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              value: _isAnonymous,
                              onChanged: (value) => setState(() => _isAnonymous = value),
                            ),
                            SwitchListTile(
                              title: Text(
                                'Urgent Situation',
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Requires immediate attention',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              value: _isUrgent,
                              onChanged: (value) => setState(() => _isUrgent = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: _submitReport,
                      icon: Icon(Icons.send),
                      label: Text(
                        'SUBMIT CRIME REPORT',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            dropdownColor: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}