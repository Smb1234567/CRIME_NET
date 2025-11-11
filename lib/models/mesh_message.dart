// FILE: lib/models/mesh_message.dart
class MeshMessage {
  final String id;
  final String type; // crime_report, acknowledgment, peer_discovery
  final Map<String, dynamic> payload;
  final String originalSender;
  final String targetReceiver;
  final int hopCount;
  final int maxHops;
  final DateTime createdAt;
  final String signature;

  MeshMessage({
    required this.id,
    required this.type,
    required this.payload,
    required this.originalSender,
    required this.targetReceiver,
    required this.hopCount,
    required this.maxHops,
    required this.createdAt,
    required this.signature,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'originalSender': originalSender,
      'targetReceiver': targetReceiver,
      'hopCount': hopCount,
      'maxHops': maxHops,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'signature': signature,
    };
  }

  factory MeshMessage.fromMap(Map<String, dynamic> map) {
    return MeshMessage(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      originalSender: map['originalSender'] ?? '',
      targetReceiver: map['targetReceiver'] ?? '',
      hopCount: map['hopCount'] ?? 0,
      maxHops: map['maxHops'] ?? 10,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      signature: map['signature'] ?? '',
    );
  }

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      originalSender: json['senderDeviceId'] ?? '',
      targetReceiver: json['targetDeviceId'] ?? '',
      hopCount: json['hopCount'] ?? 0,
      maxHops: json['ttl'] ?? 10,
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
          : DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      signature: json['signature'] ?? '',
    );
  }
}
