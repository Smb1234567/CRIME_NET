import 'package:flutter/material.dart';
import 'package:crime_net/models/report_model.dart';
import 'package:crime_net/utils/constants.dart';

class ReportCard extends StatelessWidget {
  final CrimeReport report;
  final VoidCallback? onTap;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppConstants.priorityColors[report.priority]?.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getReportIcon(report.type),
            color: AppConstants.priorityColors[report.priority],
          ),
        ),
        title: Text(
          report.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(report.description.length > 60 
                ? '${report.description.substring(0, 60)}...' 
                : report.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  report.address.length > 30 
                      ? '${report.address.substring(0, 30)}...' 
                      : report.address,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(report.reportedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'suspicious_vehicle':
        return Icons.directions_car;
      case 'intimidation':
        return Icons.warning;
      case 'theft':
        return Icons.money_off;
      case 'vandalism':
        return Icons.brush;
      case 'disturbance':
        return Icons.volume_up;
      case 'suspicious_person':
        return Icons.person;
      case 'drug_activity':
        return Icons.medical_services;
      default:
        return Icons.report;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'action_taken':
        return Colors.blue;
      case 'false_alarm':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}