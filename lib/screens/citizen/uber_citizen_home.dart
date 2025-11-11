import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../models/report_model.dart';
import '../../services/local_storage_service.dart';
import '../../services/location_service.dart';
import '../../services/offline_service.dart';
import '../../widgets/map_widget.dart';
import '../../widgets/real_p2p_status_widget.dart';
import 'report_creation_screen.dart';
import 'advanced_report_screen.dart';

class UberCitizenHome extends StatefulWidget {
  const UberCitizenHome({Key? key}) : super(key: key);

  @override
  State<UberCitizenHome> createState() => _UberCitizenHomeState();
}

class _UberCitizenHomeState extends State<UberCitizenHome> {
  final LocalStorageService _storageService = LocalStorageService();
  final LocationService _locationService = LocationService();
  final OfflineService _offlineService = OfflineService();
  
  List<CrimeReport> _reports = [];
  LatLng? _currentLocation;
  bool _isLoading = true;
  final PanelController _panelController = PanelController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final reports = await _storageService.getReports();
      final position = await _locationService.getCurrentPosition();
      
      setState(() {
        _reports = reports;
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: 220,
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        parallaxEnabled: true,
        parallaxOffset: 0.5,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        panel: _buildBottomPanel(),
        body: _buildMapSection(),
      ),
      floatingActionButton: _buildEmergencyFAB(),
    );
  }

  Widget _buildMapSection() {
    return Stack(
      children: [
        // Map
        _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : CrimeMapWidget(
                reports: _reports,
                currentLocation: _currentLocation,
              ),
        
        // App Bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: _buildAppBar(),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Network Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              children: [
                Icon(Icons.network_check, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text(
                  'MESH ONLINE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Sync Button
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () async {
              // TODO: Enable when Phase 9 is complete
              // await _offlineService.syncMeshNetwork();
              print('🔵 Mesh network sync would start here');
              await _loadData();
            },
          ),
          
          // Profile/Menu
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Show menu
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Real P2P Status Widget
          RealP2PStatusWidget(),
          
          // Quick Report Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Incident',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quick Report Buttons
                _buildQuickReportGrid(),
                
                const SizedBox(height: 20),
                
                // Full Report Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdvancedReportScreen(),
                        ),
                      );
                      if (result != null && result is CrimeReport) {
                        await _offlineService.saveOfflineReport(result);
                        await _loadData();
                        _panelController.close();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${result.title} reported successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Detailed Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Recent Reports Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _buildRecentReports(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReportGrid() {
    // Define a proper typed structure for quick reports
    final quickReports = <Map<String, dynamic>>[
      {
        'icon': Icons.directions_car,
        'label': 'Suspicious Vehicle',
        'type': 'suspicious_vehicle'
      },
      {
        'icon': Icons.warning,
        'label': 'Harassment', 
        'type': 'intimidation'
      },
      {
        'icon': Icons.money_off,
        'label': 'Theft',
        'type': 'theft'
      },
      {
        'icon': Icons.medical_services,
        'label': 'Drug Activity',
        'type': 'drug_activity'
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: quickReports.length,
      itemBuilder: (context, index) {
        final report = quickReports[index];
        final icon = report['icon'] as IconData;
        final label = report['label'] as String;
        final type = report['type'] as String;
        
        return ElevatedButton(
          onPressed: () => _navigateToQuickReport(type, label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentReports() {
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.grey[600], size: 50),
            const SizedBox(height: 16),
            Text(
              'No reports yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(report.status),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Report Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      report.type.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Time
              Text(
                _formatTimeAgo(report.reportedAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyFAB() {
    return FloatingActionButton(
      onPressed: () {
        _showEmergencyDialog();
      },
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      child: const Icon(Icons.emergency),
    );
  }

  Future<void> _createQuickReport(String type, String label) async {
    final position = await _locationService.getCurrentPosition();
    
    final report = CrimeReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: label,
      description: 'Quick report - $label',
      type: type,
      latitude: position.latitude,
      longitude: position.longitude,
      address: 'Current Location',
      reporterId: 'anonymous',
      isAnonymous: true,
      reportedAt: DateTime.now(),
      priority: type == 'emergency' ? 5 : 3,
    );

    await _offlineService.saveOfflineReport(report);
    await _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label reported successfully'),
        backgroundColor: Colors.green,
      ),
    );
    
    _panelController.close();
  }

  void _navigateToQuickReport(String type, String label) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedReportScreen(),
      ),
    );
    if (result != null && result is CrimeReport) {
      await _offlineService.saveOfflineReport(result);
      await _loadData();
      _panelController.close();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.title} reported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Report', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to nearby police and community members. Use only for immediate threats.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createQuickReport('emergency', 'Emergency Situation');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Report Emergency'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified': return Colors.green;
      case 'action_taken': return Colors.blue;
      case 'false_alarm': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified': return Icons.check;
      case 'action_taken': return Icons.verified;
      case 'false_alarm': return Icons.close;
      default: return Icons.access_time;
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