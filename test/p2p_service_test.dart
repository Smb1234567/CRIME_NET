import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crime_net/services/p2p_mesh_service.dart';
import 'package:crime_net/services/real_p2p_mesh_service.dart';
import 'package:crime_net/services/real_bluetooth_service.dart';
import 'package:crime_net/models/report_model.dart';
import 'dart:io';

void main() {
  group('P2P Services Test', () {
    setUp(() async {
      // Initialize Hive for testing
      final dir = await getTemporaryDirectory();
      Hive.init(dir.path);
    });

    test('Can initialize P2P mesh service', () {
      final p2pService = P2PMeshService();
      expect(p2pService, isNotNull);
    });

    test('Can initialize Real P2P mesh service', () {
      final realP2PService = RealP2PMeshService();
      expect(realP2PService, isNotNull);
    });

    test('Can initialize Real Bluetooth service', () {
      final bluetoothService = RealBluetoothService();
      expect(bluetoothService, isNotNull);
    });

    test('Can create crime report and mesh message', () async {
      final report = CrimeReport(
        id: 'test_id',
        title: 'Test Report',
        description: 'Test description',
        type: 'theft',
        latitude: 40.7128,
        longitude: -74.0060,
        address: 'Test Address',
        reporterId: 'test_reporter',
        isAnonymous: true,
        reportedAt: DateTime.now(),
        priority: 3,
        status: 'pending',
      );

      final p2pService = P2PMeshService();
      await p2pService.init();
      
      final meshMessage = await p2pService.createCrimeReportMessage(report);
      expect(meshMessage.type, 'crime_report');
      expect(meshMessage.payload['title'], 'Test Report');
    });

    test('Real P2P service initialization', () {
      final realP2PService = RealP2PMeshService();
      expect(realP2PService, isNotNull);
    });
  });
}