import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/mesh_message.dart';
import '../models/report_model.dart';

class RealP2PMeshService {
  static final RealP2PMeshService _instance = RealP2PMeshService._internal();
  factory RealP2PMeshService() => _instance;
  RealP2PMeshService._internal();

  // Bluetooth service UUID for CrimeNet mesh
  static const String CRIMENET_SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
  static const String CRIMENET_DATA_CHAR_UUID = "12345678-1234-1234-1234-123456789def";
  
  // State tracking
  bool _isAdvertising = false;
  bool _isScanning = false;
  BluetoothDevice? _advertisingDevice;
  List<BluetoothDevice> _connectedDevices = [];
  Map<String, StreamSubscription> _deviceSubscriptions = {};
  
  // Message queue for outgoing messages
  List<MeshMessage> _outgoingMessageQueue = [];
  
  // Stream for mesh events
  StreamController<Map<String, dynamic>> _meshEventStream = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Device registry for tracking discovered peers
  static const String _deviceRegistryBox = 'p2p_device_registry';
  static const String _deviceIdKey = 'device_id';
  Map<String, Map<String, dynamic>> _discoveredDevices = {};
  bool _isInitialized = false;
  String? _deviceId;
  final Uuid _uuid = const Uuid();
  
  Stream<Map<String, dynamic>> get meshEventStream => _meshEventStream.stream;

  // Initialize the service with device ID and device registry
  Future<void> init() async {
    if (!_isInitialized) {
      await Hive.openBox<Map<dynamic, dynamic>>(_deviceRegistryBox);
      await _ensureDeviceId();
      await _loadDeviceRegistry();
      _isInitialized = true;
    }
  }

  // Load previously discovered devices from storage
  Future<void> _loadDeviceRegistry() async {
    try {
      final registryBox = Hive.box<Map<dynamic, dynamic>>(_deviceRegistryBox);
      final allDevices = registryBox.toMap();
      
      for (final entry in allDevices.entries) {
        _discoveredDevices[entry.key] = Map<String, dynamic>.from(entry.value);
      }
      
      print('📱 [P2P] Loaded ${_discoveredDevices.length} devices from registry');
    } catch (e) {
      print('❌ [P2P] Error loading device registry: $e');
    }
  }

  // Register a discovered device
  Future<void> _registerDiscoveredDevice(BluetoothDevice device, int rssi) async {
    try {
      final deviceId = device.id.id;
      final deviceName = device.name.isNotEmpty ? device.name : 'Unknown Device';
      
      final deviceInfo = {
        'id': deviceId,
        'name': deviceName,
        'rssi': rssi,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
        'type': _getDeviceType(deviceName),
        'isCrimeNetDevice': true,
      };
      
      _discoveredDevices[deviceId] = deviceInfo;
      
      // Persist to storage
      final registryBox = Hive.box<Map<dynamic, dynamic>>(_deviceRegistryBox);
      await registryBox.put(deviceId, deviceInfo);
      
      print('📱 [P2P] Registered discovered device: $deviceName (ID: $deviceId)');
    } catch (e) {
      print('❌ [P2P] Error registering discovered device: $e');
    }
  }

  // Get device type based on name
  String _getDeviceType(String deviceName) {
    if (deviceName.toLowerCase().contains('police')) return 'police';
    if (deviceName.toLowerCase().contains('emergency')) return 'emergency';
    if (deviceName.toLowerCase().contains('community') || deviceName.toLowerCase().contains('watch')) return 'community';
    return 'citizen';
  }

  // Get list of discovered devices
  List<Map<String, dynamic>> getDiscoveredDevices() {
    return _discoveredDevices.values.toList();
  }

  // Verify if a specific device is connected by device ID
  bool isDeviceConnected(String deviceId) {
    return _connectedDevices.any((device) => device.id.id == deviceId);
  }

  // Get connection status for a specific device
  Map<String, dynamic>? getDeviceStatus(String deviceId) {
    // Check if device is currently connected
    BluetoothDevice? connectedDevice;
    try {
      connectedDevice = _connectedDevices.firstWhere(
        (device) => device.id.id == deviceId,
      );
    } on Error {
      connectedDevice = null; // Device not found in connected devices
    }

    // Get device info from registry
    final deviceInfo = _discoveredDevices[deviceId];

    if (deviceInfo == null && connectedDevice == null) {
      return null; // Device not discovered or connected
    }

    return {
      'id': deviceId,
      'isConnected': connectedDevice != null,
      'deviceInfo': deviceInfo,
      'lastSeen': deviceInfo?['lastSeen'],
      'rssi': deviceInfo?['rssi'],
      'type': deviceInfo?['type'],
      'name': connectedDevice?.name ?? deviceInfo?['name'] ?? 'Unknown',
    };
  }

  // Verify connection with device exchange
  Future<bool> verifyConnectionWithDevice(BluetoothDevice device) async {
    try {
      // In a real implementation, we would exchange a verification message with the device
      // For now, we'll just check if the service exists and is responsive

      // Discover services again to ensure the device is still responsive
      List<BluetoothService> services = await device.discoverServices();

      // Check for CrimeNet service
      bool hasCrimeNetService = false;
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == CRIMENET_SERVICE_UUID.toLowerCase()) {
          hasCrimeNetService = true;
          break;
        }
      }

      if (hasCrimeNetService) {
        // Send a verification message and wait for response
        // For now, we'll just send a simple verification message
        for (BluetoothService service in services) {
          if (service.uuid.toString().toLowerCase() == CRIMENET_SERVICE_UUID.toLowerCase()) {
            for (BluetoothCharacteristic characteristic in service.characteristics) {
              if (characteristic.uuid.toString().toLowerCase() == CRIMENET_DATA_CHAR_UUID.toLowerCase()) {
                if (characteristic.properties.write) {
                  // Send verification request
                  final verificationMessage = {
                    'type': 'verification_request',
                    'sender_id': await getDeviceId(),
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                    'version': '1.0',
                  };
                  
                  String messageStr = jsonEncode(verificationMessage);
                  List<int> messageBytes = utf8.encode(messageStr);
                  
                  await characteristic.write(messageBytes, withoutResponse: false);
                  
                  // In a real implementation, we'd wait for a response
                  // For now, assume verification is successful if we can send the message
                  return true;
                }
              }
            }
          }
        }
      }

      return hasCrimeNetService;
    } catch (e) {
      print('❌ [P2P] Verification failed for device ${device.name}: $e');
      return false;
    }
  }

  // Generate or get persistent device ID
  Future<void> _ensureDeviceId() async {
    try {
      // Try to open preferences box, create if doesn't exist
      Box<dynamic> prefs;
      if (Hive.isBoxOpen('preferences')) {
        prefs = Hive.box('preferences');
      } else {
        prefs = await Hive.openBox('preferences');
      }

      // Check if device ID exists
      if (!prefs.containsKey(_deviceIdKey)) {
        // Generate new device ID
        String newDeviceId = 'crime_net_${_uuid.v4()}';
        await prefs.put(_deviceIdKey, newDeviceId);
        _deviceId = newDeviceId;
        print('📱 [P2P] New persistent device ID generated: $newDeviceId');
      } else {
        // Use existing device ID
        _deviceId = prefs.get(_deviceIdKey);
        print('📱 [P2P] Using existing device ID: $_deviceId');
      }
    } catch (e) {
      print('❌ [P2P] Error initializing device ID: $e');
      // Fallback to temporary device ID
      _deviceId = 'crime_net_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Get the persistent device ID
  Future<String> getDeviceId() async {
    if (_deviceId == null) {
      await _ensureDeviceId();
    }
    return _deviceId ?? 'crime_net_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Check and request Bluetooth permissions
  Future<bool> _checkPermissions() async {
    try {
      // Bluetooth permissions
      var bluetoothStatus = await Permission.bluetoothConnect.status;
      if (!bluetoothStatus.isGranted) {
        bluetoothStatus = await Permission.bluetoothConnect.request();
      }
      
      var bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.status;
      if (!bluetoothAdvertiseStatus.isGranted) {
        bluetoothAdvertiseStatus = await Permission.bluetoothAdvertise.request();
      }
      
      // Location permission (required for Bluetooth on Android)
      var locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        locationStatus = await Permission.location.request();
      }
      
      return bluetoothStatus.isGranted && 
             bluetoothAdvertiseStatus.isGranted && 
             locationStatus.isGranted;
    } catch (e) {
      print('❌ [P2P] Permission error: $e');
      return false;
    }
  }

  // Start advertising this device as a CrimeNet mesh node
  Future<bool> startAdvertising() async {
    if (!await _checkPermissions()) {
      print('❌ [P2P] Permissions not granted for advertising');
      return false;
    }

    try {
      print('📱 [P2P] Starting CrimeNet mesh advertising...');
      
      // In a real implementation, we would set up a GATT server to advertise our service
      // For now, we'll track our advertising status
      _isAdvertising = true;
      
      // Start scanning for other CrimeNet devices to form the mesh
      await startScanning();
      
      _meshEventStream.add({
        'type': 'advertising_started',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      print('✅ [P2P] CrimeNet mesh advertising started');
      return true;
    } catch (e) {
      print('❌ [P2P] Error starting advertising: $e');
      return false;
    }
  }

  // Start scanning for other CrimeNet devices
  Future<bool> startScanning() async {
    if (!await _checkPermissions()) {
      print('❌ [P2P] Permissions not granted for scanning');
      return false;
    }

    try {
      print('📱 [P2P] Starting CrimeNet mesh scanning...');
      
      _isScanning = true;
      
      // Start scanning for devices advertising the CrimeNet service
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 30),
        withServices: [Guid(CRIMENET_SERVICE_UUID)], // Only scan for CrimeNet services
      );

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
        for (ScanResult result in results) {
          _processScanResult(result);
        }
      });

      _meshEventStream.add({
        'type': 'scanning_started',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      print('✅ [P2P] CrimeNet mesh scanning started');
      return true;
    } catch (e) {
      print('❌ [P2P] Error starting scanning: $e');
      return false;
    }
  }

  // Process a scan result to see if it's a CrimeNet device
  void _processScanResult(ScanResult result) {
    String deviceId = result.device.id.id;
    String deviceName = result.device.name.isNotEmpty 
        ? result.device.name 
        : 'CrimeNet-${deviceId.substring(deviceId.length - 4)}';
    
    print('📱 [P2P] Found potential CrimeNet device: $deviceName (${result.rssi} dBm)');
    
    // Connect to the device to verify it's a CrimeNet node
    _attemptConnection(result.device);
  }

  // Attempt to connect to a discovered device
  Future<void> _attemptConnection(BluetoothDevice device) async {
    try {
      String deviceId = device.id.id;
      
      // Check if already connected
      if (_connectedDevices.any((d) => d.id.id == deviceId)) {
        return;
      }
      
      print('🔗 [P2P] Connecting to CrimeNet device: ${device.name}');
      
      // Connect to the device
      await device.connect(
        timeout: Duration(seconds: 10),
        autoConnect: false,
      );
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      // Look for the CrimeNet service
      BluetoothService? crimeNetService;
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == CRIMENET_SERVICE_UUID.toLowerCase()) {
          crimeNetService = service;
          break;
        }
      }
      
      if (crimeNetService != null) {
        print('✅ [P2P] Connected to CrimeNet device: ${device.name}');
        
        // Add to connected devices
        // Register in our persistent device registry
         final rssi = await _getDeviceRssi(device);
         _registerDiscoveredDevice(device, rssi);
        _connectedDevices.add(device);
        
        // Set up characteristic notifications
        await _setupCharacteristicNotifications(device, crimeNetService);
        
        _meshEventStream.add({
          'type': 'device_connected',
          'deviceId': deviceId,
          'deviceName': device.name,
          'rssi': await _getDeviceRssi(device),
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // Send any queued messages to the new device
        await _sendQueuedMessages(device);
      } else {
        print('⚠️ [P2P] Device is not a CrimeNet node: ${device.name}');
        await device.disconnect();
      }
    } catch (e) {
      print('❌ [P2P] Failed to connect to device ${device.name}: $e');
      
      _meshEventStream.add({
        'type': 'connection_failed',
        'deviceId': device.id.id,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // Set up characteristic notifications for data exchange
  Future<void> _setupCharacteristicNotifications(BluetoothDevice device, BluetoothService service) async {
    try {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        // Look for the data exchange characteristic
        if (characteristic.uuid.toString().toLowerCase() == CRIMENET_DATA_CHAR_UUID.toLowerCase()) {
          // Enable notifications to receive data from this device
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            
            // Create a subscription to listen for incoming data
            StreamSubscription<List<int>> subscription = characteristic.value.listen(
              (data) => _processReceivedMessage(device, data),
              onError: (error) => print('❌ [P2P] Error receiving data from ${device.name}: $error'),
            );
            
            // Store the subscription to manage it later
            _deviceSubscriptions[device.id.id] = subscription;
          }
        }
      }
    } catch (e) {
      print('❌ [P2P] Error setting up characteristic notifications: $e');
    }
  }

  // Process a received message from a connected device
  void _processReceivedMessage(BluetoothDevice device, List<int> data) {
    try {
      // Decode the received message
      String messageStr = String.fromCharCodes(data);
      Map<String, dynamic> messageJson = jsonDecode(messageStr);
      
      print('📥 [P2P] Received message from ${device.name}: ${messageJson['type']}');
      
      // Create a MeshMessage from the received data
      MeshMessage receivedMessage = MeshMessage.fromJson(messageJson);
      
      _meshEventStream.add({
        'type': 'message_received',
        'message': receivedMessage.toMap(),
        'senderDeviceId': device.id.id,
        'senderDeviceName': device.name,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // If this is a crime report, process it further
      if (receivedMessage.type == 'crime_report') {
        _processCrimeReportMessage(receivedMessage);
      }
      
      // If this message needs to be relayed further (mesh functionality)
      if (receivedMessage.hopCount < receivedMessage.maxHops) {
        // Relay to other connected devices (but not back to sender)
        _relayMessageToOtherDevices(receivedMessage, device.id.id);
      }
    } catch (e) {
      print('❌ [P2P] Error processing received message: $e');
    }
  }

  // Process a received crime report message
  void _processCrimeReportMessage(MeshMessage message) {
    try {
      // Extract the crime report from the payload
      Map<String, dynamic> reportData = message.payload;
      
      // Create a CrimeReport object from the received data
      CrimeReport report = CrimeReport.fromMap(reportData);
      
      print('👮 [P2P] Processing received crime report: ${report.title}');
      
      // Add to local storage or process as needed
      _meshEventStream.add({
        'type': 'crime_report_received',
        'report': report.toMap(),
        'messageId': message.id,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ [P2P] Error processing crime report: $e');
    }
  }

  // Relay a message to other connected devices (except the sender)
  Future<void> _relayMessageToOtherDevices(MeshMessage message, String senderId) async {
    // Create a new message with incremented hop count
    MeshMessage relayedMessage = MeshMessage(
      id: message.id,
      type: message.type,
      payload: message.payload,
      originalSender: message.originalSender,
      targetReceiver: message.targetReceiver,
      hopCount: message.hopCount + 1,
      maxHops: message.maxHops,
      createdAt: message.createdAt,
      signature: message.signature,
    );

    // Send to all connected devices except the sender
    for (BluetoothDevice device in _connectedDevices) {
      if (device.id.id != senderId) {
        await _sendMessageToDevice(device, relayedMessage);
      }
    }
    
    print('🔄 [P2P] Relayed message to ${_connectedDevices.length - 1} other device(s)');
  }

  // Send a mesh message to connected devices
  Future<void> sendMessage(MeshMessage message) async {
    print('📤 [P2P] Sending mesh message: ${message.type} to ${_connectedDevices.length} device(s)');
    
    // Send to all connected devices
    for (BluetoothDevice device in _connectedDevices) {
      await _sendMessageToDevice(device, message);
    }
    
    _meshEventStream.add({
      'type': 'message_sent',
      'messageId': message.id,
      'deviceCount': _connectedDevices.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send a message to a specific device
  Future<void> _sendMessageToDevice(BluetoothDevice device, MeshMessage message) async {
    try {
      // Find the CrimeNet service and data characteristic
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == CRIMENET_SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == CRIMENET_DATA_CHAR_UUID.toLowerCase()) {
              if (characteristic.properties.write) {
                // Encode the message as JSON string bytes
                String messageStr = jsonEncode(message.toMap());
                List<int> messageBytes = utf8.encode(messageStr);
                
                // Send the message
                await characteristic.write(messageBytes, withoutResponse: false);
                
                print('✅ [P2P] Message sent to ${device.name}');
                
                return; // Exit after sending
              }
            }
          }
        }
      }
      
      print('⚠️ [P2P] Could not find data characteristic on ${device.name}');
    } catch (e) {
      print('❌ [P2P] Error sending message to ${device.name}: $e');
      
      _meshEventStream.add({
        'type': 'send_failed',
        'deviceId': device.id.id,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // Send queued messages to a newly connected device
  Future<void> _sendQueuedMessages(BluetoothDevice device) async {
    for (MeshMessage message in _outgoingMessageQueue) {
      await _sendMessageToDevice(device, message);
    }
  }

  // Get RSSI (signal strength) for a device
  Future<int> _getDeviceRssi(BluetoothDevice device) async {
    try {
      int? rssi = await device.readRssi();
      return rssi ?? -100; // Default value if reading fails
    } catch (e) {
      print('⚠️ [P2P] Could not read RSSI for ${device.name}: $e');
      return -100;
    }
  }

  // Get current mesh network status
  Map<String, dynamic> getMeshStatus() {
    return {
      'isAdvertising': _isAdvertising,
      'isScanning': _isScanning,
      'connectedDevices': _connectedDevices.length,
      'discoveredDevices': getDiscoveredDevices().length,
      'deviceList': _connectedDevices.map((device) => {
        'id': device.id.id,
        'name': device.name,
        'type': 'CrimeNet Node',
        'connected': true,
      }).toList(),
      'discoveredDeviceList': getDiscoveredDevices().map((deviceInfo) => {
        ...deviceInfo, // spread all device properties
        'connected': _connectedDevices.any((d) => d.id.id == deviceInfo['id']),
      }).toList(),
      'queuedMessages': _outgoingMessageQueue.length,
      'isRealP2P': true,
      'technology': 'Bluetooth LE',
      'activeNodes': _connectedDevices.length,
    };
  }

  // Stop all P2P activities
  Future<void> stopAll() async {
    print('🛑 [P2P] Stopping all mesh activities...');
    
    // Disconnect from all devices
    for (BluetoothDevice device in _connectedDevices) {
      try {
        await device.disconnect();
      } catch (e) {
        print('⚠️ [P2P] Error disconnecting from ${device.name}: $e');
      }
    }
    
    // Cancel all subscriptions
    for (StreamSubscription subscription in _deviceSubscriptions.values) {
      await subscription.cancel();
    }
    
    // Stop scanning
    await FlutterBluePlus.stopScan();
    
    // Reset state
    _isAdvertising = false;
    _isScanning = false;
    _connectedDevices.clear();
    _deviceSubscriptions.clear();
    _outgoingMessageQueue.clear();
    
    _meshEventStream.add({
      'type': 'mesh_stopped',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    print('✅ [P2P] All mesh activities stopped');
  }

  // Queue a message for sending (when devices connect)
  void queueMessage(MeshMessage message) {
    _outgoingMessageQueue.add(message);
  }

  // Send a crime report through the mesh network
  Future<void> sendCrimeReport(CrimeReport report) async {
    // Create a mesh message for the crime report
    MeshMessage message = MeshMessage(
      id: report.id,
      type: 'crime_report',
      payload: report.toMap(),
      originalSender: await _getDeviceId(),
      targetReceiver: 'police_network', // Target police receivers
      hopCount: 0,
      maxHops: 5, // Limit hops to prevent infinite loops
      createdAt: DateTime.now(),
      signature: _createMessageSignature(report.toMap()),
    );
    
    // Send through the mesh
    await sendMessage(message);
  }

  // Helper to get a unique device ID
  Future<String> _getDeviceId() async {
    return await getDeviceId();
  }

  // Create a simple signature for message integrity
  String _createMessageSignature(Map<String, dynamic> payload) {
    // In a real implementation, you'd use cryptographic signing
    // For now, we'll use a simple hash
    return payload.hashCode.toString();
  }
}