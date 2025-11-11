import 'package:hive/hive.dart';
import '../models/report_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _reportsBox = 'reports';
  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      await Hive.openBox<Map<dynamic, dynamic>>(_reportsBox);
      _isInitialized = true;
    }
  }

  // Save a report
  Future<void> saveReport(CrimeReport report) async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_reportsBox);
    await box.put(report.id, report.toMap());
    print('💾 Report saved: ${report.id}');
  }

  // Get all reports
  Future<List<CrimeReport>> getReports() async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_reportsBox);
    final reports = box.values
        .map((data) => CrimeReport.fromMap(Map<String, dynamic>.from(data)))
        .toList();

    // Sort by most recent first
    reports.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    return reports;
  }

  // Get reports by status
  Future<List<CrimeReport>> getReportsByStatus(String status) async {
    final allReports = await getReports();
    return allReports.where((report) => report.status == status).toList();
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String status) async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_reportsBox);
    final reportData = box.get(reportId);

    if (reportData != null) {
      reportData['status'] = status;
      await box.put(reportId, reportData);
      print('📝 Report $reportId updated to: $status');
    }
  }

  // Delete a report
  Future<void> deleteReport(String reportId) async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_reportsBox);
    await box.delete(reportId);
    print('🗑️ Report deleted: $reportId');
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_reportsBox);
    await box.clear();
    print('🧹 All data cleared');
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    final reports = await getReports();
    return {
      'total': reports.length,
      'pending': reports.where((r) => r.status == 'pending').length,
      'verified': reports.where((r) => r.status == 'verified').length,
      'action_taken': reports.where((r) => r.status == 'action_taken').length,
    };
  }
}
