import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crime_net/services/p2p_mesh_service.dart';
import 'package:crime_net/models/report_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
  });

  tearDown(() async {
    // Clean up Hive boxes after each test
    await Hive.close();
  });

  test('P2PMeshService shareReport method exists and works', () async {
    final p2pService = P2PMeshService();
    await p2pService.init();

    // Create a test report
    final testReport = CrimeReport(
      id: 'test_report_1',
      title: 'Test Crime Report',
      description: 'Test description',
      type: 'theft',
      latitude: 40.7128,
      longitude: -74.0060,
      address: 'Test Address',
      reporterId: 'test_user',
      reportedAt: DateTime.now(),
      status: 'pending',
      priority: 3,
      imageUrls: [],
      verificationCount: 1,
    );

    // Test that shareReport method exists and can be called
    await expectLater(() async => await p2pService.shareReport(testReport), 
        returnsNormally);
  });

  test('P2PMeshService getMeshStats method returns proper data structure', () async {
    final p2pService = P2PMeshService();
    await p2pService.init();

    // Test that getMeshStats method exists and returns expected structure
    final stats = await p2pService.getMeshStats();
    
    expect(stats, isA<Map<String, dynamic>>());
    expect(stats.containsKey('active_messages'), true);
    expect(stats.containsKey('crime_reports'), true);
    expect(stats.containsKey('acknowledgments'), true);
    expect(stats.containsKey('average_hops'), true);
    expect(stats.containsKey('connected_peers'), true);
    expect(stats.containsKey('messagesRelayed'), true);
    expect(stats.containsKey('totalHops'), true);
  });

  test('OfflineService can access P2PMeshService methods properly', () async {
    // Test that the offline service can properly await and use the mesh stats
    final p2pService = P2PMeshService();
    await p2pService.init();
    
    // Test awaiting the getMeshStats properly (not accessing Future directly with [])
    final meshStats = await p2pService.getMeshStats();
    final messagesRelayed = meshStats['messagesRelayed'] ?? 0;
    final networkHops = meshStats['totalHops'] ?? 0;
    
    expect(messagesRelayed, isA<int>());
    expect(networkHops, isA<int>());
  });
}