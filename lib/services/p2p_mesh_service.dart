// FILE: lib/services/p2p_mesh_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../models/report_model.dart';
import '../models/mesh_message.dart';

class P2PMeshService {
  static final P2PMeshService _instance = P2PMeshService._internal();
  factory P2PMeshService() => _instance;
  P2PMeshService._internal();

  static const String _meshMessagesBox = 'mesh_messages';
  static const String _peerRegistryBox = 'peer_registry';
  final Uuid _uuid = const Uuid();
  bool _isInitialized = false;

  // Police public key (would be hardcoded or fetched from server)
  static const String POLICE_PUBLIC_KEY = "police_master_public_key_xyz789";

  // Message types
  static const String TYPE_CRIME_REPORT = 'crime_report';
  static const String TYPE_ACKNOWLEDGMENT = 'acknowledgment';
  static const String TYPE_PEER_DISCOVERY = 'peer_discovery';

  Future<void> init() async {
    if (!_isInitialized) {
      await Hive.openBox<Map<dynamic, dynamic>>(_meshMessagesBox);
      await Hive.openBox<Map<dynamic, dynamic>>(_peerRegistryBox);
      _isInitialized = true;
    }
  }

  // Encrypt message for police only
  Map<String, dynamic> _encryptForPolice(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    // In real implementation, use RSA/ECC encryption with police public key
    // For now, simulate encryption with hash
    final bytes = utf8.encode(jsonString + POLICE_PUBLIC_KEY);
    final digest = sha256.convert(bytes);

    return {
      'encrypted_data':
          base64Encode(utf8.encode(jsonString)), // Simulated encryption
      'encryption_hash': digest.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ttl': 24 * 60 * 60 * 1000, // 24 hours
    };
  }

  // Create mesh message for crime report
  Future<MeshMessage> createCrimeReportMessage(CrimeReport report) async {
    final encryptedPayload = _encryptForPolice(report.toMap());

    return MeshMessage(
      id: _uuid.v4(),
      type: TYPE_CRIME_REPORT,
      payload: encryptedPayload,
      originalSender: await _getDeviceId(),
      targetReceiver: POLICE_PUBLIC_KEY, // Only police can decrypt
      hopCount: 0,
      maxHops: 10,
      createdAt: DateTime.now(),
      signature: _createSignature(encryptedPayload),
    );
  }

  // Store message for relay
  Future<void> storeForRelay(MeshMessage message) async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_meshMessagesBox);

    await box.put(message.id, message.toMap());
    print('📡 Mesh message stored for relay: ${message.id}');
  }

  // Get messages that need to be relayed
  Future<List<MeshMessage>> getPendingRelayMessages() async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_meshMessagesBox);
    final now = DateTime.now().millisecondsSinceEpoch;

    final messages = box.values.where((msgMap) {
      final msg = MeshMessage.fromMap(Map<String, dynamic>.from(msgMap));
      return msg.hopCount < msg.maxHops &&
          (now - msg.createdAt.millisecondsSinceEpoch) < (24 * 60 * 60 * 1000);
    }).toList();

    return messages
        .map((msg) => MeshMessage.fromMap(Map<String, dynamic>.from(msg)))
        .toList();
  }

  // Simulate peer discovery and message exchange
  Future<void> simulatePeerExchange() async {
    await init();
    final pendingMessages = await getPendingRelayMessages();

    if (pendingMessages.isEmpty) {
      print('📭 No messages to relay');
      return;
    }

    // Simulate discovering nearby peers
    final simulatedPeers = await _discoverSimulatedPeers();

    for (final peer in simulatedPeers) {
      print('🔗 Exchanging messages with peer: ${peer['id']}');

      for (final message in pendingMessages) {
        // Increment hop count for relay
        final relayedMessage = MeshMessage(
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

        // Simulate storing on peer device
        await _simulatePeerStorage(peer['id'], relayedMessage);

        // Update our local copy with new hop count
        await _updateMessageHopCount(message.id, message.hopCount + 1);
      }
    }

    print(
        '🔄 Peer exchange completed: ${pendingMessages.length} messages relayed');
  }

  // Process incoming mesh messages
  Future<List<CrimeReport>> processIncomingMeshMessages() async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_meshMessagesBox);
    final messages = box.values.toList();

    List<CrimeReport> newReports = [];

    for (final msgMap in messages) {
      final message = MeshMessage.fromMap(Map<String, dynamic>.from(msgMap));

      // Verify message integrity
      if (!_verifySignature(message)) {
        print('❌ Invalid signature for message: ${message.id}');
        await _removeMessage(message.id);
        continue;
      }

      // Check if expired or max hops reached
      if (_isMessageExpired(message) || message.hopCount >= message.maxHops) {
        await _removeMessage(message.id);
        continue;
      }

      // Process based on message type
      if (message.type == TYPE_CRIME_REPORT) {
        final report = await _processCrimeReportMessage(message);
        if (report != null) {
          newReports.add(report);
        }
      }
    }

    return newReports;
  }

  Future<CrimeReport?> _processCrimeReportMessage(MeshMessage message) async {
    try {
      // Check if we are the intended recipient (police)
      final isPoliceReceiver = await _isPoliceDevice();

      if (isPoliceReceiver) {
        // Decrypt and process the report
        final decryptedData = _decryptPoliceMessage(message.payload);
        final report = CrimeReport.fromMap(decryptedData);

        print('👮 Police received report via mesh: ${report.id}');

        // Generate ACK and propagate back
        await _createAndSendAck(message.originalSender, report.id);

        await _removeMessage(message.id);
        return report;
      } else {
        // We're just a relay node - store for further relay
        print('🔀 Relaying message: ${message.id} (hop ${message.hopCount})');
        return null;
      }
    } catch (e) {
      print('❌ Error processing mesh message: $e');
      return null;
    }
  }

  // Simulate police device check
  Future<bool> _isPoliceDevice() async {
    final authBox = await Hive.openBox('auth');
    final userRole = authBox.get('user_role', defaultValue: 'citizen');
    return userRole == 'police';
  }

  // Public method to check if device is police receiver
  Future<bool> isPoliceDevice() async {
    return await _isPoliceDevice();
  }

  // Helper methods
  Future<String> _getDeviceId() async {
    final prefs = await Hive.openBox('preferences');
    return prefs.get('device_id', defaultValue: _uuid.v4());
  }

  String _createSignature(Map<String, dynamic> payload) {
    final jsonString = jsonEncode(payload);
    return sha256.convert(utf8.encode(jsonString)).toString();
  }

  bool _verifySignature(MeshMessage message) {
    final expectedSignature = _createSignature(message.payload);
    return message.signature == expectedSignature;
  }

  bool _isMessageExpired(MeshMessage message) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - message.createdAt.millisecondsSinceEpoch) >
        (24 * 60 * 60 * 1000);
  }

  Future<void> _removeMessage(String messageId) async {
    final box = Hive.box<Map<dynamic, dynamic>>(_meshMessagesBox);
    await box.delete(messageId);
  }

  Future<void> _updateMessageHopCount(String messageId, int newHopCount) async {
    final box = Hive.box<Map<dynamic, dynamic>>(_meshMessagesBox);
    final msgMap = box.get(messageId);
    if (msgMap != null) {
      msgMap['hopCount'] = newHopCount;
      await box.put(messageId, msgMap);
    }
  }

  // Simulated methods (to be replaced with real P2P)
  Future<List<Map<String, dynamic>>> _discoverSimulatedPeers() async {
    return [
      {'id': 'neighbor_001', 'type': 'citizen', 'distance': 50},
      {'id': 'community_002', 'type': 'citizen', 'distance': 120},
      {'id': 'watch_003', 'type': 'community_watch', 'distance': 200},
    ];
  }

  Future<void> _simulatePeerStorage(String peerId, MeshMessage message) async {
    // In real implementation, this would send via Bluetooth/WiFi Direct
    await Future.delayed(Duration(milliseconds: 100));
    print('    📨 Sent to $peerId: ${message.id} (hop ${message.hopCount})');
  }

  Map<String, dynamic> _decryptPoliceMessage(
      Map<String, dynamic> encryptedPayload) {
    // Simulate decryption - in real app, use police private key
    final encodedData = encryptedPayload['encrypted_data'] as String;
    final jsonString = utf8.decode(base64Decode(encodedData));
    return jsonDecode(jsonString);
  }

  Future<void> _createAndSendAck(String originalSender, String reportId) async {
    final ackMessage = MeshMessage(
      id: _uuid.v4(),
      type: TYPE_ACKNOWLEDGMENT,
      payload: {
        'report_id': reportId,
        'received_at': DateTime.now().millisecondsSinceEpoch,
        'police_station_id': 'station_123',
      },
      originalSender: POLICE_PUBLIC_KEY,
      targetReceiver: originalSender,
      hopCount: 0,
      maxHops: 10,
      createdAt: DateTime.now(),
      signature: _createSignature({'report_id': reportId}),
    );

    await storeForRelay(ackMessage);
    print('✅ ACK generated for report: $reportId');
  }

  // Share report via mesh network
  Future<void> shareReport(CrimeReport report) async {
    await init();
    final meshMessage = await createCrimeReportMessage(report);
    await storeForRelay(meshMessage);
    print('📡 Report shared via mesh: ${report.id}');
  }

  // Get mesh network statistics
  Future<Map<String, dynamic>> getMeshStats() async {
    await init();
    final box = Hive.box<Map<dynamic, dynamic>>(_meshMessagesBox);
    final messages = box.values.toList();

    int crimeReports = 0;
    int acknowledgments = 0;
    int totalHops = 0;
    int messagesRelayed = 0;

    for (final msgMap in messages) {
      final message = MeshMessage.fromMap(Map<String, dynamic>.from(msgMap));
      if (message.type == TYPE_CRIME_REPORT) {
        crimeReports++;
        totalHops += message.hopCount;
      } else if (message.type == TYPE_ACKNOWLEDGMENT) {
        acknowledgments++;
      }
      messagesRelayed++;
    }

    return {
      'active_messages': messages.length,
      'crime_reports': crimeReports,
      'acknowledgments': acknowledgments,
      'average_hops': crimeReports > 0 ? totalHops / crimeReports : 0,
      'connected_peers': 3, // Simulated
      'messagesRelayed': messagesRelayed,
      'totalHops': totalHops,
    };
  }
}
