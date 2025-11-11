import 'dart:convert';
import 'package:crime_net/models/mesh_message.dart';
import 'package:crime_net/models/report_model.dart';
import 'package:crime_net/services/p2p_mesh_service.dart';
import 'package:crime_net/services/real_p2p_service.dart';

class EnhancedP2PMeshService {
  final RealP2PService _realP2P = RealP2PService();
  final P2PMeshService _meshService = P2PMeshService();
  
  Future<void> initializeMeshNetwork() async {
    print('🔄 Initializing enhanced mesh network...');
    
    // Start both advertising and discovery
    await _realP2P.startAdvertising(_meshService.deviceId);
    await _realP2P.startDiscovery();
    
    print('✅ Enhanced mesh network initialized');
    print('   - Advertising: ${_realP2P.isAdvertising}');
    print('   - Discovering: ${_realP2P.isDiscovering}');
  }
  
  Future<void> sendReportThroughMesh(ReportModel report) async {
    print('📤 Sending report through enhanced mesh: ${report.title}');
    
    // For now, use the existing shareReport method
    await _meshService.shareReport(report);
    
    print('✅ Report sent through enhanced mesh network');
  }
  
  // Get network status for UI
  Map<String, dynamic> getNetworkStatus() {
    final realP2PStatus = _realP2P.getConnectionStatus();
    final meshStatus = _meshService.getMeshStats();
    
    return {
      'realP2P': realP2PStatus,
      'meshNetwork': meshStatus,
      'totalConnectedDevices': realP2PStatus['connectedDevices'],
      'isActive': realP2PStatus['isAdvertising'] || realP2PStatus['isDiscovering'],
    };
  }
}