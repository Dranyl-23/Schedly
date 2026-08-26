import 'package:flutter/material.dart';

enum NotificationType {
  reminder,
  briefing,
  sync,
  system,
}

extension NotificationTypeExtension on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.briefing:
        return 'Daily Briefing';
      case NotificationType.sync:
        return 'Cloud Sync';
      case NotificationType.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.briefing:
        return Icons.wb_sunny_rounded;
      case NotificationType.sync:
        return Icons.cloud_done_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.reminder:
        return const Color(0xFF2563EB); // Royal Blue
      case NotificationType.briefing:
        return const Color(0xFFF59E0B); // Amber Sun
      case NotificationType.sync:
        return const Color(0xFF10B981); // Emerald Green
      case NotificationType.system:
        return const Color(0xFF8B5CF6); // Purple
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedScheduleId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.relatedScheduleId,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? relatedScheduleId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedScheduleId: relatedScheduleId ?? this.relatedScheduleId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'relatedScheduleId': relatedScheduleId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.reminder,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      relatedScheduleId: json['relatedScheduleId'] as String?,
    );
  }
}
