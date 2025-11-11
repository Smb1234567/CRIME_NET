import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static const String _pendingSyncBox = 'pending_sync';
  static const String _p2pInboxBox = 'p2p_inbox';
  static const String _deviceIdKey = 'device_id';
  final Uuid _uuid = const Uuid();
  bool _isInitialized = false;

  // Initialize offline service
  Future<void> init() async {
    if (!_isInitialized) {
      await Hive.openBox<Map<dynamic, dynamic>>(_pendingSyncBox);
      await Hive.openBox<Map<dynamic, dynamic>>(_p2pInboxBox);
      _isInitialized = true;
      await _ensureDeviceId();
    }
  }

  // Generate or get device ID
  Future<void> _ensureDeviceId() async {
    final prefs = await Hive.openBox('preferences');
    if (!prefs.containsKey(_deviceIdKey)) {
      await prefs.put(_deviceIdKey, _uuid.v4());
    }
  }

  Future<String> getDeviceId() async {
    final prefs = await Hive.openBox('preferences');
    return prefs.get(_deviceIdKey, defaultValue: _uuid.v4());
  }

  // Check connectivity
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Save report for offline sync
  Future<void> saveOfflineReport(CrimeReport report) async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_pendingSyncBox);
    
    final offlineReport = {
      ...report.toMap(),
      'offline_id': '${await getDeviceId()}_${DateTime.now().millisecondsSinceEpoch}',
      'sync_status': 'pending',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    
    await box.put(offlineReport['offline_id'], offlineReport);
    print('📱 Offline report saved: ${offlineReport['offline_id']}');
  }

  // Get all pending sync reports
  Future<List<Map<String, dynamic>>> getPendingSyncReports() async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_pendingSyncBox);
    final pendingReports = box.values.toList();
    
    return pendingReports.map((report) {
      return Map<String, dynamic>.from(report);
    }).toList();
  }

  // Mark report as synced
  Future<void> markAsSynced(String offlineId) async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_pendingSyncBox);
    await box.delete(offlineId);
    print('☁️ Report synced: $offlineId');
  }

  // Simulate P2P message sharing (for demo purposes)
  Future<void> shareViaP2P(CrimeReport report) async {
    await init();
    final p2pBox = Hive.box<Map<dynamic, dynamic>>(_p2pInboxBox);
    
    // Simulate receiving reports from nearby devices
    // In a real app, this would use Bluetooth/WiFi Direct
    final simulatedDevices = [
      'neighbor_device_001',
      'neighbor_device_002', 
      'community_watch_003'
    ];
    
    for (final deviceId in simulatedDevices) {
      final p2pMessage = {
        'type': 'crime_report',
        'data': report.toMap(),
        'from_device': deviceId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': 24 * 60 * 60 * 1000, // 24 hours
      };
      
      await p2pBox.put('${deviceId}_${_uuid.v4()}', p2pMessage);
    }
    
    print('📡 P2P simulation: Shared report with ${simulatedDevices.length} nearby devices');
  }

  // Process incoming P2P messages
  Future<List<CrimeReport>> processP2PMessages() async {
    await init();
    final p2pBox = Hive.box<Map<dynamic, dynamic>>(_p2pInboxBox);
    final messages = p2pBox.values.toList();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    List<CrimeReport> newReports = [];
    
    for (final message in messages) {
      final messageData = Map<String, dynamic>.from(message);
      
      // Check if message is expired
      if (now - (messageData['timestamp'] as int) > (messageData['ttl'] as int)) {
        await p2pBox.delete(p2pBox.keyAt(p2pBox.values.toList().indexOf(message)));
        continue;
      }
      
      // Process crime report messages
      if (messageData['type'] == 'crime_report') {
        try {
          final reportData = Map<String, dynamic>.from(messageData['data']);
          final report = CrimeReport.fromMap(reportData);
          
          // Check if we already have this report
          final localStorage = Hive.box<Map<dynamic, dynamic>>('reports');
          if (!localStorage.containsKey(report.id)) {
            // Save to local storage
            await localStorage.put(report.id, report.toMap());
            newReports.add(report);
            print('🔄 P2P report received: ${report.id} from ${messageData['from_device']}');
          }
          
          // Remove the message after processing
          await p2pBox.delete(p2pBox.keyAt(p2pBox.values.toList().indexOf(message)));
        } catch (e) {
          print('❌ Error processing P2P report: $e');
        }
      }
    }
    
    return newReports;
  }

  // Get P2P network stats
  Future<Map<String, dynamic>> getP2PStats() async {
    await init();
    final p2pBox = Hive.box<Map<dynamic, dynamic>>(_p2pInboxBox);
    final messages = p2pBox.values.toList();
    
    final now = DateTime.now().millisecondsSinceEpoch;
    int activeMessages = 0;
    int expiredMessages = 0;
    
    for (final message in messages) {
      final messageData = Map<String, dynamic>.from(message);
      if (now - (messageData['timestamp'] as int) > (messageData['ttl'] as int)) {
        expiredMessages++;
      } else {
        activeMessages++;
      }
    }
    
    return {
      'active_messages': activeMessages,
      'expired_messages': expiredMessages,
      'total_devices_connected': 3, // Simulated
    };
  }

  // Sync all pending reports when online
  Future<void> syncPendingReports() async {
    if (!await isConnected()) {
      print('🌐 No internet connection for sync');
      return;
    }

    final pendingReports = await getPendingSyncReports();
    if (pendingReports.isEmpty) {
      print('✅ No pending reports to sync');
      return;
    }

    print('🔄 Syncing ${pendingReports.length} pending reports...');

    for (final reportData in pendingReports) {
      try {
        // Simulate cloud sync - in real app, this would be Firebase/API call
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Mark as synced
        await markAsSynced(reportData['offline_id']);
        
        print('✅ Synced: ${reportData['offline_id']}');
      } catch (e) {
        print('❌ Sync failed for ${reportData['offline_id']}: $e');
      }
    }
    
    print('🎉 Sync completed!');
  }

  // Manual trigger for processing P2P messages
  Future<void> manualP2PSync() async {
    print('🔄 Manual P2P sync triggered...');
    final newReports = await processP2PMessages();
    
    if (newReports.isNotEmpty) {
      print('📥 Received ${newReports.length} new reports via P2P');
    } else {
      print('📭 No new P2P reports found');
    }
  }
}
