import 'dart:async';
import 'package:flutter/material.dart';
import 'package:crime_net/services/p2p_mesh_service.dart';
import 'package:crime_net/services/real_bluetooth_service.dart';

class RealP2PStatusWidget extends StatefulWidget {
  const RealP2PStatusWidget({Key? key}) : super(key: key);

  @override
  State<RealP2PStatusWidget> createState() => _RealP2PStatusWidgetState();
}

class _RealP2PStatusWidgetState extends State<RealP2PStatusWidget> {
  final P2PMeshService _p2pService = P2PMeshService();
  final RealBluetoothService _bluetoothService = RealBluetoothService();
  Map<String, dynamic> _networkStats = {};
  bool _isActive = false;
  Timer? _updateTimer;
  List<Map<String, dynamic>> _connectedDeviceList = [];
  List<Map<String, dynamic>> _discoveredDeviceList = [];
  List<Map<String, dynamic>> _messageLog = [];
  String _connectionError = '';
  bool _showDebugInfo = false;
  String _testMessageContent = 'This is a test message from mobile device';
  int _testMessageCount = 1;

  @override
  void initState() {
    super.initState();
    _loadNetworkStats();
    _startUpdateTimer();
    _setupMessageListener();
    _setupConnectionListener();
  }

  void _setupConnectionListener() {
    _p2pService.connectionErrorStream.listen((error) {
      setState(() {
        _connectionError = error;
      });
    });
  }

  void _setupMessageListener() {
    _bluetoothService.messageStream.listen((message) {
      setState(() {
        _messageLog.insert(0, {
          'time': DateTime.now(),
          'type': message['type'],
          'data': message,
        });
        
        // Keep only last 20 messages for better mobile testing
        if (_messageLog.length > 20) {
          _messageLog.removeLast();
        }
      });
    });
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _loadNetworkStats();
    });
  }

  void _loadNetworkStats() async {
    final stats = await _p2pService.getMeshStats();
    setState(() {
      _networkStats = stats;
      // For now, assume active if there are any active messages
      _isActive = _networkStats['active_messages'] != null && _networkStats['active_messages'] > 0;
      _connectedDeviceList = _networkStats['deviceList'] ?? [];
      _discoveredDeviceList = _networkStats['discoveredDeviceList'] ?? [];
    });
  }

  void _startRealP2P() {
    _p2pService.startRealP2P();
    setState(() {
      _connectionError = '';
    });
    _loadNetworkStats();
  }

  void _stopRealP2P() {
    _p2pService.stopRealP2P();
    _loadNetworkStats();
  }

  void _sendTestMessage() {
    final testMessage = {
      'type': 'test_message',
      'content': '$_testMessageContent ($_testMessageCount)',
      'timestamp': DateTime.now().toIso8601String(),
      'sender_device': _bluetoothService.deviceId,
      'test': true,
      'id': DateTime.now().millisecondsSinceEpoch,
    };
    
    _bluetoothService.sendMessage(testMessage);
    
    setState(() {
      _testMessageCount++;
    });
  }

  void _sendBulkTestMessages() {
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        _sendTestMessage();
      });
    }
  }

  void _simulateIncomingMessage() {
    final testMessage = {
      'type': 'crime_report',
      'payload': {
        'title': 'Test Report from Nearby Device',
        'category': 'Suspicious Activity',
        'priority': 'Medium',
        'timestamp': DateTime.now().toIso8601String(),
        'location': {'lat': 40.7128, 'lng': -74.0060}, // Simulated coordinates
        'accuracy': 10.0,
      },
      'sender': 'simulated_neighbor_${DateTime.now().millisecondsSinceEpoch}',
      'test': true,
    };
    
    _bluetoothService.simulateIncomingMessage(testMessage);
  }

  void _simulateNetworkConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Simulate Network Conditions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.signal_wifi_4_bar),
                title: Text('Good Connection'),
                onTap: () {
                  _p2pService.setNetworkQuality('good');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.signal_wifi_0_bar),
                title: Text('Poor Connection'),
                onTap: () {
                  _p2pService.setNetworkQuality('poor');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.bluetooth_connected),
                title: Text('Bluetooth Issues'),
                onTap: () {
                  _p2pService.setNetworkQuality('bluetooth_issues');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _clearMessageLog() {
    setState(() {
      _messageLog.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _isActive ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: _isActive ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  '📱 REAL P2P TESTING',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isActive ? Colors.green : Colors.grey,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(
                    _showDebugInfo ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showDebugInfo = !_showDebugInfo;
                    });
                  },
                ),
              ],
            ),
            
            // Connection Error Display
            if (_connectionError.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connection Error: $_connectionError',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
            
            // Platform and Battery Info
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Platform: ${_networkStats['platform'] ?? 'Unknown'}',
                        style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                      ),
                    ],
                  ),
                  if (_showDebugInfo) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.battery_full, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Battery: ${_networkStats['batteryLevel'] ?? 'N/A'}%',
                          style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),
            
            // Network Status
            _buildStatusRow('Network Status', _isActive ? 'ACTIVE' : 'INACTIVE', 
                _isActive ? Colors.green : Colors.red),
            _buildStatusRow('Connected Devices', '${_connectedDeviceList.length} devices', Colors.blue),
            _buildStatusRow('Discovered Devices', '${_discoveredDeviceList.length} devices', Colors.cyan),
            _buildStatusRow('Messages Relayed', '${_networkStats['messagesRelayed'] ?? 0}', Colors.orange),
            _buildStatusRow('Technology', '${_networkStats['technology'] ?? 'Simulated'}', Colors.purple),
            _buildStatusRow('Signal Strength', '${_networkStats['signalStrength'] ?? 'Unknown'}', Colors.teal),
            
            if (_showDebugInfo) ...[
              _buildStatusRow('Last Update', '${_networkStats['lastUpdate'] ?? 'Never'}', Colors.grey),
              _buildStatusRow('Data Usage', '${_networkStats['dataUsage'] ?? '0'} MB', Colors.amber),
            ],
            
            SizedBox(height: 12),
            
            // Connected Devices List
            if (_connectedDeviceList.isNotEmpty) ...[
              Text('Connected Devices:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              ..._connectedDeviceList.take(5).map((device) => _buildDeviceItem(device)).toList(), // Show up to 5 devices
              if (_connectedDeviceList.length > 5) ...[
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${_connectedDeviceList.length - 5} more connected devices',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
              SizedBox(height: 8),
            ],

            // Discovered Devices List
            if (_discoveredDeviceList.isNotEmpty) ...[
              Text('Discovered Devices:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              ..._discoveredDeviceList.take(5).map((device) => _buildDeviceItem(device)).toList(), // Show up to 5 devices
              if (_discoveredDeviceList.length > 5) ...[
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${_discoveredDeviceList.length - 5} more discovered devices',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
              SizedBox(height: 8),
            ],
            
            // Test Controls
            Text('Testing Controls:', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isActive ? _stopRealP2P : _startRealP2P,
                  icon: Icon(_isActive ? Icons.stop : Icons.play_arrow, size: 16),
                  label: Text(_isActive ? 'Stop' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _sendTestMessage,
                  icon: Icon(Icons.send, size: 16),
                  label: Text('Test Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _simulateIncomingMessage,
                  icon: Icon(Icons.download, size: 16),
                  label: Text('Test Receive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _sendBulkTestMessages,
                  icon: Icon(Icons.send_and_archive, size: 16),
                  label: Text('Bulk Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _simulateNetworkConditions,
                  icon: Icon(Icons.network_check, size: 16),
                  label: Text('Network'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            
            // Custom Message Input
            SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Custom Test Message',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              maxLines: 2,
              onChanged: (value) {
                setState(() {
                  _testMessageContent = value;
                });
              },
              controller: TextEditingController(text: _testMessageContent),
            ),
            
            // Message Log
            if (_messageLog.isNotEmpty) ...[
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Message Log (${_messageLog.length}):', style: TextStyle(fontWeight: FontWeight.w500)),
                  TextButton(
                    onPressed: _clearMessageLog,
                    child: Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _messageLog.length,
                  itemBuilder: (context, index) {
                    final message = _messageLog[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(_getMessageIcon(message['type']), size: 16),
                      title: Text(
                        '${message['type']} - ${message['data']['sender_device'] ?? 'Unknown'}',
                        style: TextStyle(fontSize: 11),
                      ),
                      subtitle: Text(
                        '${message['time'].toString().substring(11, 19)}',
                        style: TextStyle(fontSize: 9),
                      ),
                      trailing: message['data']['test'] == true 
                          ? Icon(Icons.bug_report, size: 12, color: Colors.orange)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getMessageIcon(String type) {
    switch (type) {
      case 'message_received': return Icons.download;
      case 'message_delivered': return Icons.check_circle;
      case 'device_connected': return Icons.person_add;
      case 'crime_report': return Icons.warning;
      case 'test_message': return Icons.bug_report;
      default: return Icons.message;
    }
  }

  Widget _buildDeviceItem(Map<String, dynamic> device) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android, size: 12, color: Colors.green),
          SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device['name'] ?? 'Unknown',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                if (_showDebugInfo && device['rssi'] != null)
                  Text(
                    'RSSI: ${device['rssi']} dBm',
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getDeviceColor(device['type']),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              device['type'] ?? 'user',
              style: TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDeviceColor(String? type) {
    switch (type) {
      case 'police': return Colors.blue;
      case 'emergency': return Colors.red;
      case 'community': return Colors.green;
      case 'test': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12))),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}