class AccessLog {
  final int id;
  final int userId;
  final String userName;
  final String method;
  final String status;
  final String timestamp;

  AccessLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.method,
    required this.status,
    required this.timestamp,
  });

  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Unknown',
      method: json['method'] ?? '',
      status: json['status'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}
