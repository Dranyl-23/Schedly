import 'package:flutter/material.dart';

class AlarmTone {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String? soundFile;

  const AlarmTone({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.soundFile,
  });

  static const List<AlarmTone> presets = [
    AlarmTone(
      id: 'system_default',
      name: 'System Default',
      description: 'Your device\'s default alarm and ringtone sound',
      icon: Icons.smartphone_rounded,
      color: Color(0xFF2563EB),
      soundFile: null,
    ),
    AlarmTone(
      id: 'crystal_chime',
      name: 'Crystal Chime',
      description: 'Gentle and melodic chimes, perfect for morning classes',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFF10B981),
      soundFile: 'sounds/crystal_chime.wav',
    ),
    AlarmTone(
      id: 'campus_bell',
      name: 'Campus Bell',
      description: 'Classic academic school bell sound',
      icon: Icons.school_rounded,
      color: Color(0xFFF59E0B),
      soundFile: 'sounds/campus_bell.wav',
    ),
    AlarmTone(
      id: 'pulse_radar',
      name: 'Pulse Radar',
      description: 'High-energy digital pulse for urgent duty shifts',
      icon: Icons.radar_rounded,
      color: Color(0xFFEF4444),
      soundFile: 'sounds/pulse_radar.wav',
    ),
    AlarmTone(
      id: 'zen_marimba',
      name: 'Zen Marimba',
      description: 'Peaceful and calm wooden acoustic notes',
      icon: Icons.spa_rounded,
      color: Color(0xFF8B5CF6),
      soundFile: 'sounds/zen_marimba.wav',
    ),
    AlarmTone(
      id: 'digital_beep',
      name: 'Digital Beep',
      description: 'Standard modern digital clock alarm beeps',
      icon: Icons.alarm_rounded,
      color: Color(0xFF06B6D4),
      soundFile: 'sounds/digital_beep.wav',
    ),
  ];

  static AlarmTone fromId(String id) {
    return presets.firstWhere(
      (t) => t.id == id,
      orElse: () => presets.first,
    );
  }
}
