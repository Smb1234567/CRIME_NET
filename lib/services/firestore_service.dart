import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new crime report
  Future<void> addCrimeReport(CrimeReport report) async {
    await _firestore.collection('reports').doc(report.id).set(report.toMap());
  }

  // Get all reports
  Stream<List<CrimeReport>> getReports() {
    return _firestore
        .collection('reports')
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CrimeReport.fromMap(doc.data()))
            .toList());
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String status) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
    });
  }
}
