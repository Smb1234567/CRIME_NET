import 'package:flutter/material.dart';
import 'package:crime_net/services/offline_service.dart';
import 'package:crime_net/services/local_storage_service.dart';
import 'package:crime_net/widgets/report_card.dart';
import 'package:crime_net/widgets/offline_indicator.dart';
import 'report_creation_screen.dart';
import 'map_view_screen.dart';
import 'package:crime_net/models/report_model.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  final LocalStorageService _storageService = LocalStorageService();
  List<CrimeReport> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyReports();
  }

  Future<void> _loadMyReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _storageService.getReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🆕 Mesh network synchronization
  Future<void> _syncMeshNetwork() async {
    final offlineService = OfflineService();
    await offlineService.syncMeshNetwork();
    await _loadMyReports(); // Reload to show any new reports from mesh
  }

  // 🆕 Get mesh network status
  Future<Map<String, dynamic>> _getMeshStatus() async {
    final offlineService = OfflineService();
    return await offlineService.getP2PStats(); // Using the correct method name
  }

  // 🆕 Enhanced report submission with mesh
  Future<void> _submitReportWithMesh(CrimeReport report) async {
    final offlineService = OfflineService();
    
    // Save locally and to mesh network
    await offlineService.saveOfflineReport(report);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📡 Report saved and queued for mesh sharing'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Trigger mesh sync in background
    _syncMeshNetwork();
    
    // Reload reports
    await _loadMyReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Net - Citizen'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // 🆕 Add map navigation button
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CitizenMapScreen()),
              );
            },
            tooltip: 'View Crime Map',
          ),
          // 🆕 Add mesh sync button
          IconButton(
            icon: const Icon(Icons.network_check),
            onPressed: _syncMeshNetwork,
            tooltip: 'Sync Mesh Network',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await OfflineService().manualP2PSync();
              await _loadMyReports();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyReports,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.switch_account),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            tooltip: 'Switch Role',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_gmailerrorred,
                    size: 80,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Reports Yet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first safety report to help your community',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                const OfflineIndicator(), // ADD THIS LINE
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'My Reports (${_reports.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      return ReportCard(
                        report: _reports[index],
                        onTap: () {
                          _showReportDetails(_reports[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportCreationScreen(),
            ),
          );
          if (result != null && result is CrimeReport) {
            await _submitReportWithMesh(result); // 🆕 Use mesh version
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showReportDetails(CrimeReport report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(report.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, report.address),
            _buildDetailRow(
              Icons.calendar_today,
              'Reported on ${_formatDate(report.reportedAt)}',
            ),
            _buildDetailRow(Icons.flag, 'Priority: ${report.priority}'),
            _buildDetailRow(Icons.star, 'Status: ${report.status}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
