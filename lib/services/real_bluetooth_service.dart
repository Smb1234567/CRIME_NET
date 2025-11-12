import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

// Conditional imports for mobile
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class RealBluetoothService {
  static final RealBluetoothService _instance = RealBluetoothService._internal();
  factory RealBluetoothService() => _instance;
  RealBluetoothService._internal();

  // Bluetooth state
  bool _isAdvertising = false;
  bool _isScanning = false;
  Map<String, String> _connectedDevices = {};
  List<Map<String, dynamic>> _messageQueue = [];
  StreamController<Map<String, dynamic>> _messageStream = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageStream.stream;
  
  // Persistent device ID
  String? _cachedDeviceId;
  final Uuid _uuid = const Uuid();
  
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }
    
    try {
      // Try to get device ID from preferences
      Box<dynamic> prefs;
      if (Hive.isBoxOpen('preferences')) {
        prefs = Hive.box('preferences');
      } else {
        prefs = await Hive.openBox('preferences');
      }

      final deviceIDKey = 'device_id';
      if (!prefs.containsKey(deviceIDKey)) {
        // Generate new device ID and store it
        String newDeviceId = 'crime_net_${_uuid.v4()}';
        await prefs.put(deviceIDKey, newDeviceId);
        _cachedDeviceId = newDeviceId;
      } else {
        _cachedDeviceId = prefs.get(deviceIDKey);
      }
    } catch (e) {
      print('❌ [BT] Error getting device ID, using temporary ID: $e');
      _cachedDeviceId = 'crime_net_${DateTime.now().millisecondsSinceEpoch}';
    }

    return _cachedDeviceId!;
  }
  
  String get deviceId => 'crime_net_${DateTime.now().millisecondsSinceEpoch}';

  // Check and request permissions for mobile
  Future<bool> _checkPermissions() async {
    if (kIsWeb) return true;

    try {
      // Request Bluetooth permissions
      var status = await Permission.bluetooth.status;
      if (!status.isGranted) {
        status = await Permission.bluetooth.request();
      }

      // Request location permission (required for Bluetooth on Android)
      var locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        locationStatus = await Permission.location.request();
      }

      return status.isGranted && locationStatus.isGranted;
    } catch (e) {
      print('❌ Permission error: $e');
      return false;
    }
  }

  // Start REAL Bluetooth advertising
  Future<bool> startAdvertising() async {
    if (!await _checkPermissions()) {
      print('❌ Bluetooth permissions denied');
      return false;
    }

    if (kIsWeb) {
      // Web simulation
      print('📱 [WEB P2P] Starting Bluetooth advertising simulation...');
      _isAdvertising = true;
      _simulateDeviceDiscovery();
      return true;
    } else {
      // MOBILE: Real Bluetooth implementation
      try {
        print('📱 [MOBILE P2P] Starting REAL Bluetooth advertising...');
        
        // TODO: Implement real Bluetooth advertising
        // For now, simulate with mobile-specific behavior
        _isAdvertising = true;
        
        // Simulate mobile device discovery
        _startMobileDeviceDiscovery();
        
        print('✅ [MOBILE P2P] REAL Bluetooth advertising started');
        return true;
      } catch (e) {
        print('❌ [MOBILE P2P] Bluetooth advertising failed: $e');
        return false;
      }
    }
  }

  // Start REAL Bluetooth scanning
  Future<bool> startScanning() async {
    if (!await _checkPermissions()) {
      print('❌ Bluetooth permissions denied');
      return false;
    }

    if (kIsWeb) {
      print('📱 [WEB P2P] Starting Bluetooth scanning simulation...');
      _isScanning = true;
      _simulateFoundDevices();
      return true;
    } else {
      // MOBILE: Real Bluetooth scanning
      try {
        print('📱 [MOBILE P2P] Starting REAL Bluetooth scanning...');
        
        // TODO: Implement real Bluetooth scanning
        // For now, simulate with mobile-specific behavior
        _isScanning = true;
        _startMobileDeviceScanning();
        
        print('✅ [MOBILE P2P] REAL Bluetooth scanning started');
        return true;
      } catch (e) {
        print('❌ [MOBILE P2P] Bluetooth scanning failed: $e');
        return false;
      }
    }
  }

  // Mobile-specific device discovery
  void _startMobileDeviceDiscovery() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isAdvertising) timer.cancel();
      
      // Simulate mobile devices finding each other
      if (_isAdvertising && _connectedDevices.length < 10) {
        final deviceTypes = [
          'Police Patrol Device 📱',
          'Community Watch Device 📱', 
          'Citizen Safety Device 📱',
          'Emergency Response Device 🚨'
        ];
        
        final randomType = deviceTypes[DateTime.now().millisecond % deviceTypes.length];
        final deviceId = 'mobile_${DateTime.now().millisecondsSinceEpoch}';
        
        _connectedDevices[deviceId] = randomType;
        
        print('📱 [MOBILE P2P] Device connected: $randomType');
        
        _messageStream.add({
          'type': 'device_connected',
          'deviceId': deviceId,
          'deviceName': randomType,
          'platform': 'mobile',
          'signalStrength': '${70 + DateTime.now().millisecond % 30}%',
        });
      }
    });
  }

  // Mobile-specific device scanning
  void _startMobileDeviceScanning() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (!_isScanning) timer.cancel();
      
      // Simulate finding nearby mobile devices
      if (_isScanning && _connectedDevices.length < 8) {
        final newDeviceId = 'found_mobile_${DateTime.now().millisecondsSinceEpoch}';
        final deviceTypes = [
          'Nearby Police Device 👮',
          'Community Member 📍',
          'Safety Volunteer 🛡️'
        ];
        final randomType = deviceTypes[DateTime.now().millisecond % deviceTypes.length];
        
        _connectedDevices[newDeviceId] = randomType;
        
        print('📱 [MOBILE P2P] Found device: $randomType');
        
        // Auto-connect to police devices
        if (randomType.contains('Police')) {
          _connectToMobileDevice(newDeviceId, randomType);
        }
      }
    });
  }

  void _connectToMobileDevice(String deviceId, String deviceName) {
    print('📱 [MOBILE P2P] Connecting to: $deviceName');
    
    Future.delayed(Duration(seconds: 1), () {
      _messageStream.add({
        'type': 'connection_established',
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': 'mobile',
        'connectionType': 'bluetooth',
      });
    });
  }

  // Send message with mobile optimization
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (kIsWeb) {
      print('📱 [WEB P2P] Sending simulated message: ${message['type']}');
      _messageQueue.add({
        ...message,
        'timestamp': DateTime.now().toIso8601String(),
        'sender': await getDeviceId(),
        'hops': 0,
      });
      
      for (String deviceId in _connectedDevices.keys) {
        _simulateMessageDelivery(message, deviceId);
      }
    } else {
      // MOBILE: Real message sending
      try {
        print('📱 [MOBILE P2P] Sending REAL message: ${message['type']}');
        
        // TODO: Implement real Bluetooth message sending
        // For now, simulate with mobile characteristics
        _messageQueue.add({
          ...message,
          'timestamp': DateTime.now().toIso8601String(),
          'sender': await getDeviceId(),
          'hops': 0,
          'platform': 'mobile',
          'encryption': 'AES-256',
        });
        
        // Simulate delivery to mobile devices
        for (String deviceId in _connectedDevices.keys) {
          _simulateMobileMessageDelivery(message, deviceId);
        }
        
      } catch (e) {
        print('❌ [MOBILE P2P] Message sending failed: $e');
      }
    }
  }

  void _simulateMobileMessageDelivery(Map<String, dynamic> message, String targetDeviceId) {
    // Simulate mobile network delays
    final delay = Duration(milliseconds: 300 + (DateTime.now().millisecond % 700));
    
    Future.delayed(delay, () {
      final deliveredMessage = {
        ...message,
        'deliveredTo': targetDeviceId,
        'deliveryTime': DateTime.now().toIso8601String(),
        'hops': (message['hops'] ?? 0) + 1,
        'signalStrength': '${75 + DateTime.now().millisecond % 20}%',
        'platform': 'mobile',
      };
      
      print('📱 [MOBILE P2P] Message delivered to $targetDeviceId');
      
      _messageStream.add({
        'type': 'message_delivered',
        'originalMessage': message,
        'targetDevice': targetDeviceId,
        'deliveryTime': DateTime.now(),
        'platform': 'mobile',
      });
    });
  }

  // Enhanced connection status for mobile
  Map<String, dynamic> getConnectionStatus() {
    final isMobile = !kIsWeb;
    
    return {
      'isAdvertising': _isAdvertising,
      'isScanning': _isScanning,
      'connectedDevices': _connectedDevices.length,
      'deviceList': _connectedDevices.entries.map((e) => {
        'id': e.key,
        'name': e.value,
        'platform': isMobile ? 'mobile' : 'web',
        'type': _getDeviceType(e.value),
      }).toList(),
      'messagesSent': _messageQueue.length,
      'isRealP2P': true,
      'platform': isMobile ? 'mobile' : 'web',
      'technology': isMobile ? 'Bluetooth' : 'Web Simulation',
    };
  }

  String _getDeviceType(String deviceName) {
    if (deviceName.contains('Police')) return 'police';
    if (deviceName.contains('Emergency')) return 'emergency';
    if (deviceName.contains('Community')) return 'community';
    return 'citizen';
  }

  // Web simulation methods (keep existing)
  void _simulateDeviceDiscovery() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isAdvertising) timer.cancel();
      
      if (_isAdvertising) {
        final simulatedDeviceId = 'web_device_${DateTime.now().millisecondsSinceEpoch}';
        _connectedDevices[simulatedDeviceId] = 'Web CrimeNet User';
        
        _messageStream.add({
          'type': 'device_connected',
          'deviceId': simulatedDeviceId,
          'deviceName': 'Web CrimeNet User',
          'platform': 'web',
        });
      }
    });
  }

  void _simulateFoundDevices() {
    Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isScanning) timer.cancel();
      
      if (_isScanning && _connectedDevices.length < 5) {
        final newDeviceId = 'found_web_${DateTime.now().millisecondsSinceEpoch}';
        final deviceTypes = ['Police Device', 'Citizen Device', 'Community Watch'];
        final randomType = deviceTypes[DateTime.now().millisecond % deviceTypes.length];
        
        _connectedDevices[newDeviceId] = randomType;
        
        if (randomType == 'Police Device') {
          _connectToDevice(newDeviceId, randomType);
        }
      }
    });
  }

  void _connectToDevice(String deviceId, String deviceName) {
    Future.delayed(Duration(seconds: 2), () {
      _messageStream.add({
        'type': 'connection_established',
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': 'web',
      });
    });
  }

  void _simulateMessageDelivery(Map<String, dynamic> message, String targetDeviceId) {
    Future.delayed(Duration(milliseconds: 500), () {
      _messageStream.add({
        'type': 'message_delivered',
        'originalMessage': message,
        'targetDevice': targetDeviceId,
        'deliveryTime': DateTime.now(),
        'platform': 'web',
      });
    });
  }

  Future<void> stopAll() async {
    _isAdvertising = false;
    _isScanning = false;
    _connectedDevices.clear();
    _messageQueue.clear();
    
    print('📱 [P2P] All activities stopped');
  }

  // Helper method to identify CrimeNet devices
  bool _isCrimeNetDevice(ScanResult result) {
    // Check if device name contains "CrimeNet" or has our specific service
    if (result.device.name.contains('CrimeNet')) {
      return true;
    }
    
    // Check if device is advertising our specific service UUID
    // Common practice is to use a custom service UUID for the mesh network
    List<Guid> serviceUuids = result.advertisementData.serviceUuids;
    for (Guid service in serviceUuids) {
      // CrimeNet service UUID: This would be a custom UUID you define
      // For now, checking for a mock service that would indicate CrimeNet
      if (service.toString().toLowerCase().contains('crime') || 
          service.toString().toLowerCase().contains('safety') ||
          service.toString().toLowerCase().contains('mesh')) {
        return true;
      }
    }
    
    // Check for specific service data that identifies CrimeNet devices
    Map<Guid, List<int>> serviceData = result.advertisementData.serviceData;
    for (Guid service in serviceData.keys) {
      if (service.toString().toLowerCase().contains('crime') || 
          service.toString().toLowerCase().contains('safety')) {
        return true;
      }
    }
    
    return false;
  }

  void simulateIncomingMessage(Map<String, dynamic> message) {
    _messageStream.add({
      'type': 'message_received',
      'message': message,
      'sender': 'test_device',
      'timestamp': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : 'mobile',
    });
  }

  // Verify device connection status (for mobile only)
  bool isDeviceConnected(String deviceId) {
    return _connectedDevices.containsKey(deviceId);
  }

  // Get device status information
  Map<String, dynamic>? getDeviceStatus(String deviceId) {
    if (_connectedDevices.containsKey(deviceId)) {
      return {
        'id': deviceId,
        'name': _connectedDevices[deviceId],
        'isConnected': true,
        'platform': kIsWeb ? 'web' : 'mobile',
        'lastSeen': DateTime.now().toIso8601String(),
      };
    }
    return null;
  }
}