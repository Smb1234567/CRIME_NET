import 'package:flutter/material.dart';
import 'package:crime_net/widgets/report_card.dart';
import 'package:crime_net/models/report_model.dart';
import 'package:crime_net/services/local_storage_service.dart';
import 'package:crime_net/services/offline_service.dart';

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard> {
  final LocalStorageService _storageService = LocalStorageService();
  List<CrimeReport> _reports = [];
  String _filterStatus = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
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

  Future<void> _updateReportStatus(CrimeReport report, String newStatus) async {
    try {
      await _storageService.updateReportStatus(report.id, newStatus);
      await _loadReports(); // Reload to reflect changes

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report marked as $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, int>> _getStatistics() async {
    return await _storageService.getStatistics();
  }

  Future<Map<String, dynamic>> _getP2PStats() async {
    final offlineService = OfflineService();
    return await offlineService.getP2PStats();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _filterStatus == 'all'
        ? _reports
        : _reports.where((report) => report.status == _filterStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Net - Police'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Reports')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'verified', child: Text('Verified')),
              const PopupMenuItem(
                  value: 'action_taken', child: Text('Action Taken')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
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
          : Column(
              children: [
                // Statistics Row
                FutureBuilder<Map<String, int>>(
                  future: _getStatistics(),
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? {'total': 0, 'pending': 0, 'verified': 0, 'action_taken': 0};
                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat('Total', stats['total'] ?? 0, Colors.blue),
                              _buildStat('Pending', stats['pending'] ?? 0, Colors.orange),
                              _buildStat('Verified', stats['verified'] ?? 0, Colors.green),
                              _buildStat('Action Taken', stats['action_taken'] ?? 0, Colors.purple),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _getP2PStats(),
                            builder: (context, p2pSnapshot) {
                              final p2pStats = p2pSnapshot.data ?? {};
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat('P2P Active', p2pStats['active_messages'] ?? 0, Colors.cyan),
                                  _buildStat('Devices', p2pStats['total_devices_connected'] ?? 0, Colors.teal),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Reports List
                Expanded(
                  child: filteredReports.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.report_off,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No reports found',
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create reports as a citizen to see them here',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            return ReportCard(
                              report: filteredReports[index],
                              onTap: () {
                                _showReportDetails(filteredReports[index]);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showReportDetails(CrimeReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              report.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, report.address),
            _buildDetailRow(Icons.calendar_today,
                'Reported on ${_formatDate(report.reportedAt)}'),
            _buildDetailRow(Icons.flag, 'Priority: ${report.priority}'),
            _buildDetailRow(Icons.star, 'Status: ${report.status}'),
            const SizedBox(height: 24),

            // Action Buttons
            if (report.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateReportStatus(report, 'verified'),
                      child: const Text('Mark Verified'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _updateReportStatus(report, 'action_taken'),
                      child: const Text('Take Action'),
                    ),
                  ),
                ],
              ),
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
