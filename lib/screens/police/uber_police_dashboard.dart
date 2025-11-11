import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:latlong2/latlong.dart';
import '../../models/report_model.dart';
import '../../services/local_storage_service.dart';
import '../../services/offline_service.dart';
import '../../widgets/map_widget.dart';
import '../../widgets/real_p2p_status_widget.dart';

class UberPoliceDashboard extends StatefulWidget {
  const UberPoliceDashboard({Key? key}) : super(key: key);

  @override
  State<UberPoliceDashboard> createState() => _UberPoliceDashboardState();
}

class _UberPoliceDashboardState extends State<UberPoliceDashboard> {
  final LocalStorageService _storageService = LocalStorageService();
  final OfflineService _offlineService = OfflineService();
  
  List<CrimeReport> _reports = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  Map<String, dynamic> _meshStats = {};
  final PanelController _panelController = PanelController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final reports = await _storageService.getReports();
      // TODO: Enable when Phase 9 is complete  
      // final stats = await _offlineService.getP2PStats();
      final stats = {'connectedDevices': 0, 'messagesRelayed': 0, 'networkHops': 0};
      
      setState(() {
        _reports = reports;
        _meshStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading police data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<CrimeReport> get _filteredReports {
    if (_filterStatus == 'all') return _reports;
    return _reports.where((report) => report.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: 280,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        panel: _buildBottomPanel(),
        body: _buildMapSection(),
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
                reports: _filteredReports,
                onReportTap: _showReportActions,
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
          // Mesh Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                Icon(Icons.network_check, color: Colors.blue, size: 16),
                SizedBox(width: 6),
                Text(
                  '${_meshStats['active_messages'] ?? 0} ACTIVE',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          Spacer(),
          
          // Sync Button
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: () async {
              // TODO: Enable when Phase 9 is complete
              // await _offlineService.syncMeshNetwork();
              print('🔵 Mesh network sync would start here');
              await _loadData();
            },
          ),
          
          // Filter Button
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Real P2P Status Widget
          RealP2PStatusWidget(),
          
          // Stats Section
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildStatsGrid(),
                SizedBox(height: 16),
                _buildMeshStats(),
              ],
            ),
          ),
          
          // Reports Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _buildReportsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final pending = _reports.where((r) => r.status == 'pending').length;
    final highPriority = _reports.where((r) => r.priority >= 4).length;
    final verified = _reports.where((r) => r.status == 'verified').length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard('Total', _reports.length.toString(), Icons.assignment),
        _buildStatCard('Pending', pending.toString(), Icons.access_time),
        _buildStatCard('High Priority', highPriority.toString(), Icons.warning),
        _buildStatCard('Verified', verified.toString(), Icons.verified),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMeshStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMeshStat('Network Health', '${_meshStats['connected_peers'] ?? 0} Peers'),
          _buildMeshStat('Avg Hops', '${_meshStats['average_hops']?.toStringAsFixed(1) ?? '0'}'),
          _buildMeshStat('Messages', '${_meshStats['active_messages'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildMeshStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.green,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildReportsList() {
    if (_filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, color: Colors.grey[600], size: 50),
            SizedBox(height: 16),
            Text(
              'No reports found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredReports.length,
      itemBuilder: (context, index) {
        final report = _filteredReports[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Priority Indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(report.priority),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'P${report.priority}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatTimeAgo(report.reportedAt),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Details
              Text(
                report.type.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              
              SizedBox(height: 4),
              
              Text(
                report.description.length > 100 
                    ? '${report.description.substring(0, 100)}...'
                    : report.description,
                style: TextStyle(color: Colors.white70),
              ),
              
              SizedBox(height: 12),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(report, 'verified'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('Verify', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(report, 'action_taken'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('Action Taken', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(report, 'false_alarm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text('False Alarm', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportActions(CrimeReport report) {
    _panelController.open();
    // Could scroll to the specific report in the list
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Reports',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('All Reports', 'all'),
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Verified', 'verified'),
                _buildFilterChip('Action Taken', 'action_taken'),
                _buildFilterChip('High Priority', 'high_priority'),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: Colors.white)),
      selected: _filterStatus == value,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? value : 'all';
        });
        Navigator.pop(context);
      },
      backgroundColor: Colors.grey[700],
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
    );
  }

  Future<void> _updateStatus(CrimeReport report, String status) async {
    try {
      await _storageService.updateReportStatus(report.id, status);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report status updated to $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5: return Colors.purple;
      case 4: return Colors.red;
      case 3: return Colors.orange;
      case 2: return Colors.blue;
      default: return Colors.green;
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