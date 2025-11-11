import 'package:flutter/foundation.dart';

class MeshNetworkState {
  final int connectedDevices;
  final int messagesRelayed;
  final bool isAdvertising;
  final bool isDiscovering;
  final List<String> discoveredDevices;

  MeshNetworkState({
    this.connectedDevices = 0,
    this.messagesRelayed = 0,
    this.isAdvertising = false,
    this.isDiscovering = false,
    this.discoveredDevices = const [],
  });

  MeshNetworkState copyWith({
    int? connectedDevices,
    int? messagesRelayed,
    bool? isAdvertising,
    bool? isDiscovering,
    List<String>? discoveredDevices,
  }) {
    return MeshNetworkState(
      connectedDevices: connectedDevices ?? this.connectedDevices,
      messagesRelayed: messagesRelayed ?? this.messagesRelayed,
      isAdvertising: isAdvertising ?? this.isAdvertising,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
    );
  }
}