class AppUser {
  final String uid;
  final String email;
  final String role; // 'citizen' or 'police'
  final String displayName;
  final int points;
  final String reputationLevel;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    this.points = 0,
    this.reputationLevel = 'Beginner',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'displayName': displayName,
      'points': points,
      'reputationLevel': reputationLevel,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'citizen',
      displayName: map['displayName'] ?? '',
      points: map['points'] ?? 0,
      reputationLevel: map['reputationLevel'] ?? 'Beginner',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
