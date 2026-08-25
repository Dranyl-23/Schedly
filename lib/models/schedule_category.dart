import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum ScheduleCategory {
  classSchedule,
  workShift,
  duty,
  custom,
}

extension ScheduleCategoryExtension on ScheduleCategory {
  String get displayName {
    switch (this) {
      case ScheduleCategory.classSchedule:
        return 'Class / Subject';
      case ScheduleCategory.workShift:
        return 'Work Shift';
      case ScheduleCategory.duty:
        return 'Duty Roster';
      case ScheduleCategory.custom:
        return 'Custom / Other';
    }
  }

  String get shortLabel {
    switch (this) {
      case ScheduleCategory.classSchedule:
        return 'Class';
      case ScheduleCategory.workShift:
        return 'Shift';
      case ScheduleCategory.duty:
        return 'Duty';
      case ScheduleCategory.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleCategory.classSchedule:
        return Icons.school_rounded;
      case ScheduleCategory.workShift:
        return Icons.work_rounded;
      case ScheduleCategory.duty:
        return Icons.badge_rounded;
      case ScheduleCategory.custom:
        return Icons.event_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ScheduleCategory.classSchedule:
        return AppColors.categoryClass;
      case ScheduleCategory.workShift:
        return AppColors.categoryWork;
      case ScheduleCategory.duty:
        return AppColors.categoryDuty;
      case ScheduleCategory.custom:
        return AppColors.categoryCustom;
    }
  }

  int get defaultReminderLeadMinutes {
    switch (this) {
      case ScheduleCategory.classSchedule:
        return 15; // 15 min before class
      case ScheduleCategory.workShift:
        return 60; // 1 hour before shift to prepare/travel
      case ScheduleCategory.duty:
        return 30; // 30 min before duty
      case ScheduleCategory.custom:
        return 15;
    }
  }

  static ScheduleCategory fromString(String? value) {
    if (value == null) return ScheduleCategory.custom;
    switch (value.toLowerCase()) {
      case 'class':
      case 'classschedule':
      case 'school':
      case 'subject':
      case 'course':
        return ScheduleCategory.classSchedule;
      case 'work':
      case 'workshift':
      case 'shift':
      case 'job':
        return ScheduleCategory.workShift;
      case 'duty':
      case 'dutyroster':
      case 'station':
      case 'hospital':
        return ScheduleCategory.duty;
      default:
        return ScheduleCategory.custom;
    }
  }
}
