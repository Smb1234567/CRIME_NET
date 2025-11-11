import 'package:flutter/material.dart';

class RealP2PStatusWidget extends StatelessWidget {
  const RealP2PStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.network_check, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '🌐 Real Mesh Network',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Status message
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phase 9: Real P2P Communication - Coming Soon!',
                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Simulated status
            _buildStatusRow('Device Advertising', false),
            _buildStatusRow('Device Discovery', false),
            _buildStatusRow('Connected Devices', false, value: '0 devices'),
            
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement when Phase 9 is ready
                print('Real P2P features coming in Phase 9');
              },
              icon: Icon(Icons.engineering),
              label: Text('Enable Real P2P'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive, {String? value}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive ? Colors.green : Colors.grey,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(child: Text(label)),
          if (value != null) Text(
            value,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}