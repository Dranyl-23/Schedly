class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'urgent', 'promo'
  final bool isActive;
  final String actionLabel;
  final String actionUrl;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isActive,
    this.actionLabel = '',
    this.actionUrl = '',
  });

  factory AnnouncementModel.fromFirestore(Map<String, dynamic> json, String docId) {
    return AnnouncementModel(
      id: docId,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      isActive: json['isActive'] as bool? ?? true,
      actionLabel: json['actionLabel'] as String? ?? '',
      actionUrl: json['actionUrl'] as String? ?? '',
    );
  }
}
