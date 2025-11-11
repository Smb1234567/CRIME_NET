import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/report_model.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/map_widget.dart';

class PoliceMapScreen extends StatefulWidget {
  const PoliceMapScreen({Key? key}) : super(key: key);

  @override
  State<PoliceMapScreen> createState() => _PoliceMapScreenState();
}

class _PoliceMapScreenState extends State<PoliceMapScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<CrimeReport> _reports = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _storageService.getReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading police map data: $e');
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
      appBar: AppBar(
        title: const Text('Police Crime Map'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (status) {
              setState(() {
                _filterStatus = status;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Reports')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'verified', child: Text('Verified')),
              const PopupMenuItem(value: 'action_taken', child: Text('Action Taken')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        _buildFilterChip('Pending', 'pending'),
                        _buildFilterChip('Verified', 'verified'),
                        _buildFilterChip('Action Taken', 'action_taken'),
                        _buildFilterChip('High Priority', 'high_priority'),
                      ],
                    ),
                  ),
                ),
                // Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Total', _reports.length),
                      _buildStatItem('Pending', 
                          _reports.where((r) => r.status == 'pending').length),
                      _buildStatItem('High Priority',
                          _reports.where((r) => r.priority >= 4).length),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: CrimeMapWidget(
                    reports: _filteredReports,
                    onReportTap: _showPoliceReportActions,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadReports,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: _filterStatus == value,
        onSelected: (selected) {
          setState(() {
            _filterStatus = selected ? value : 'all';
          });
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showPoliceReportActions(CrimeReport report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Type: ${report.type.replaceAll('_', ' ')}'),
            Text('Priority: ${report.priority}'),
            Text('Status: ${report.status}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _updateStatus(report, 'verified'),
                  child: const Text('Verify'),
                ),
                ElevatedButton(
                  onPressed: () => _updateStatus(report, 'action_taken'),
                  child: const Text('Action Taken'),
                ),
                ElevatedButton(
                  onPressed: () => _updateStatus(report, 'false_alarm'),
                  child: const Text('False Alarm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(CrimeReport report, String status) async {
    try {
      await _storageService.updateReportStatus(report.id, status);
      Navigator.pop(context); // Close bottom sheet
      await _loadReports(); // Reload data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report status updated to $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
}