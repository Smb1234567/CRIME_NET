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
  String _currentAddress = "Getting your location...";
  String _locationAccuracy = "Acquiring location...";
  bool _isLocationPermissionGranted = false;
  bool _isLoading = true;
  int _gpsSatellites = 0;
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
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading your safety dashboard...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: _buildEmergencyFAB(), // Use the existing FAB method
      body: Stack(
        children: [
          // Map Widget - use CrimeMapWidget instead of MapWidget
          Stack(
            children: [
              // Crime Map
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
          ),

          // FIXED: Sliding Panel without overflow
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4, // Fixed height
              child: DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.2,
                maxChildSize: 0.7,
                snap: true,
                snapSizes: [0.2, 0.4, 0.7],
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        
                        // Content with fixed height scroll
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            physics: ClampingScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Current Location
                                  _buildLocationSection(),
                                  SizedBox(height: 16),
                                  
                                  // Quick Actions
                                  _buildQuickActionsSection(),
                                  SizedBox(height: 16),
                                  
                                  // Real P2P Status
                                  RealP2PStatusWidget(),
                                  SizedBox(height: 16),
                                  
                                  // Recent Reports
                                  _buildReportsSection(),
                                  SizedBox(height: 20), // Extra bottom padding
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
      return _buildEmptyReports();
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

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.yellow[600]!;
      case 2:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 5:
        return 'CRITICAL';
      case 4:
        return 'HIGH';
      case 3:
        return 'MEDIUM';
      case 2:
        return 'LOW';
      default:
        return 'INFO';
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

  String _calculateLocationAccuracy(double accuracy) {
    if (accuracy <= 5) return "Excellent (≤5m)";
    if (accuracy <= 10) return "Good (≤10m)";
    if (accuracy <= 30) return "Fair (≤30m)";
    if (accuracy <= 50) return "Poor (≤50m)";
    return "Very Poor (>50m)";
  }

  int _getSatelliteCount(double accuracy) {
    // Estimate GPS quality based on accuracy
    if (accuracy <= 5) return 12;
    if (accuracy <= 10) return 10;
    if (accuracy <= 30) return 8;
    if (accuracy <= 50) return 6;
    return 4;
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Location Permission Required', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Emergency reporting requires location access. Please enable location permission in your device settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Open settings to allow user to enable location
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showReportHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        initialChildSize: 0.7,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Your Report History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _reports.isEmpty
                    ? _buildEmptyReports()
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          return _buildReportItem(_reports[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportItem(CrimeReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(report.status),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(report.status),
                  color: Colors.white,
                  size: 12,
                ),
              ),
              const SizedBox(width: 12),
              // Report title
              Expanded(
                child: Text(
                  report.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Timestamp
              Text(
                _formatTimeAgo(report.reportedAt),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Report type and priority
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.type.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(report.priority),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPriorityText(report.priority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Location preview
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.address.length > 50
                      ? '${report.address.substring(0, 50)}...'
                      : report.address,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReports() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.report_problem, color: Colors.grey[400], size: 40),
          SizedBox(height: 12),
          Text(
            'No reports yet',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap "Report Incident" to create your first detailed crime report',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.location_pin, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Location',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _currentAddress,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue, size: 20),
              onPressed: _loadCurrentLocation,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                'Report Incident',
                Icons.report,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdvancedReportScreen(), // Use existing report screen
                    ),
                  ).then((_) => _loadData()); // Use existing data loading method
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildQuickAction(
                'View History',
                Icons.history,
                Colors.purple,
                _showReportHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Reports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _reports.isEmpty
            ? _buildEmptyReports()
            : Column(
                children: _reports
                    .take(3)
                    .map((report) => _buildReportItem(report))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onPressed) {
    return Card(
      color: Colors.grey[800],
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCurrentLocation() async {
    if (_isLocationPermissionGranted) {
      try {
        final position = await _locationService.getCurrentPosition();
        final address = await _locationService.getAddressFromLatLng(
          position.latitude,
          position.longitude
        );

        // Calculate GPS accuracy
        String accuracy = _calculateLocationAccuracy(position.accuracy);
        int satellites = _getSatelliteCount(position.accuracy);

        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _currentAddress = address;
          _locationAccuracy = accuracy;
          _gpsSatellites = satellites;
        });
      } catch (e) {
        print('Error updating location: $e');
      }
    } else {
      _showLocationPermissionDialog();
    }
  }

}