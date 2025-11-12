class CrimeReport {
  final String id;
  final String title;
  final String description;
  final String type; // suspicious_vehicle, intimidation, theft, etc.
  final double latitude;
  final double longitude;
  final String address;
  final String reporterId;
  final bool isAnonymous;
  final DateTime reportedAt;
  final String status; // pending, verified, action_taken, false_alarm
  final int priority; // 1-5, with 5 being highest
  final List<String> imageUrls;
  final String? audioUrl;
  final int verificationCount;

  CrimeReport({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.reporterId,
    this.isAnonymous = true,
    required this.reportedAt,
    this.status = 'pending',
    this.priority = 1,
    this.imageUrls = const [],
    this.audioUrl,
    this.verificationCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'reporterId': reporterId,
      'isAnonymous': isAnonymous,
      'reportedAt': reportedAt.millisecondsSinceEpoch,
      'status': status,
      'priority': priority,
      'imageUrls': imageUrls,
      'audioUrl': audioUrl,
      'verificationCount': verificationCount,
    };
  }

  factory CrimeReport.fromMap(Map<String, dynamic> map) {
    return CrimeReport(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'other',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      address: map['address'] ?? '',
      reporterId: map['reporterId'] ?? '',
      isAnonymous: map['isAnonymous'] ?? true,
      reportedAt: DateTime.fromMillisecondsSinceEpoch(map['reportedAt']),
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 1,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      audioUrl: map['audioUrl'],
      verificationCount: map['verificationCount'] ?? 0,
    );
  }
}

class ReportModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final Map<String, dynamic>? location;
  final DateTime timestamp;
  final bool isAnonymous;
  final String userId;
  final Map<String, dynamic>? additionalInfo;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.location,
    required this.timestamp,
    required this.isAnonymous,
    required this.userId,
    this.additionalInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'location': location,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isAnonymous': isAnonymous,
      'userId': userId,
      'additionalInfo': additionalInfo,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? 'Medium',
      status: map['status'] ?? 'Pending',
      location: map['location'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      isAnonymous: map['isAnonymous'] ?? false,
      userId: map['userId'] ?? '',
      additionalInfo: map['additionalInfo'],
    );
  }
}
