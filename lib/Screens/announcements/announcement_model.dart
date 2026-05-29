class AnnouncementModel {
  final String title;
  final String message;
  final String priority;
  final String sender;
  final DateTime timestamp;
  bool isRead;

  AnnouncementModel({
    required this.title,
    required this.message,
    required this.priority,
    required this.sender,
    required this.timestamp,
    this.isRead = false,
  });

  AnnouncementModel copyWith({
    String? title,
    String? message,
    String? priority,
    String? sender,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AnnouncementModel(
      title: title ?? this.title,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
