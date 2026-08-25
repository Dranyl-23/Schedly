import 'package:uuid/uuid.dart';
import 'schedule_category.dart';

class ScheduleEntry {
  final String id;
  final String? profileId;    // Linked profile ID (e.g. School, Work, Duty)
  final String title;
  final ScheduleCategory category;
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday (ISO-8601)
  final String startTime;     // "HH:mm" (24-hour format)
  final String endTime;       // "HH:mm" (24-hour format)
  final bool spansNextDay;     // true if shift crosses midnight (e.g. 22:00 -> 06:00)
  final String? location;      // e.g. "Room 302", "Counter 1", "Main Branch"
  final String? notes;         // e.g. "Bring lab gown / submit assignment"
  final String? colorHex;      // Optional custom color override
  final List<int> reminders;   // Lead times in minutes: [15, 60]
  final bool isActive;         // Toggle schedule & notification alarms
  final DateTime createdAt;
  final String? sourceImageId; // Reference to original screenshot if scanned

  ScheduleEntry({
    String? id,
    this.profileId,
    required this.title,
    this.category = ScheduleCategory.custom,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    this.spansNextDay = false,
    this.location,
    this.notes,
    this.colorHex,
    List<int>? reminders,
    this.isActive = true,
    DateTime? createdAt,
    this.sourceImageId,
  })  : id = id ?? const Uuid().v4(),
        reminders = reminders ?? [15],
        createdAt = createdAt ?? DateTime.now();

  ScheduleEntry copyWith({
    String? id,
    String? profileId,
    String? title,
    ScheduleCategory? category,
    List<int>? daysOfWeek,
    String? startTime,
    String? endTime,
    bool? spansNextDay,
    String? location,
    String? notes,
    String? colorHex,
    List<int>? reminders,
    bool? isActive,
    DateTime? createdAt,
    String? sourceImageId,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      category: category ?? this.category,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      spansNextDay: spansNextDay ?? this.spansNextDay,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
      reminders: reminders ?? this.reminders,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      sourceImageId: sourceImageId ?? this.sourceImageId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'title': title,
      'category': category.name,
      'daysOfWeek': daysOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'spansNextDay': spansNextDay,
      'location': location,
      'notes': notes,
      'colorHex': colorHex,
      'reminders': reminders,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'sourceImageId': sourceImageId,
    };
  }

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'] as String?,
      profileId: json['profileId'] as String?,
      title: json['title'] as String? ?? 'Untitled Schedule',
      category: ScheduleCategoryExtension.fromString(json['category'] as String?),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [DateTime.now().weekday],
      startTime: json['startTime'] as String? ?? '08:00',
      endTime: json['endTime'] as String? ?? '09:00',
      spansNextDay: json['spansNextDay'] as bool? ?? false,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      colorHex: json['colorHex'] as String?,
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [15],
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      sourceImageId: json['sourceImageId'] as String?,
    );
  }
}
