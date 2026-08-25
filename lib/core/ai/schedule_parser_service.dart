import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/schedule_category.dart';
import '../../models/schedule_entry.dart';
import '../utils/time_utils.dart';

class ScheduleParserService {
  static const String _defaultPrompt = '''
You are an expert schedule extraction AI. Analyze the provided schedule image (which could be a university class timetable, a work shift roster, a hospital/security duty roster, or a handwritten schedule).

Extract all schedule events/shifts and output ONLY a valid JSON array matching this exact schema:
[
  {
    "title": "string (subject code, job role, or duty description e.g. IT 101, Cashier Duty)",
    "category": "string (one of: 'class', 'work', 'duty', 'custom')",
    "daysOfWeek": [number (integers 1 to 7 where 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday, 7=Sunday. If an entry is on MWF, output [1, 3, 5]. If TTH, output [2, 4])],
    "startTime": "string (24-hour format HH:mm e.g. 08:30, 14:00, 22:00)",
    "endTime": "string (24-hour format HH:mm e.g. 10:00, 17:30, 06:00)",
    "spansNextDay": boolean (true if shift crosses midnight e.g. 22:00 to 06:00, false otherwise),
    "location": "string or null (room number, branch, station, or building)",
    "notes": "string or null (professor, instructor, shift supervisor, section, or remarks)"
  }
]

Rules:
1. Return ONLY the raw JSON array. Do not include markdown codeblocks (no ```json).
2. Resolve common Philippine/international school day abbreviations: M=1, T=2, W=3, TH/Th=4, F=5, S/Sa=6, Su=7.
3. Convert all 12-hour AM/PM times into 24-hour HH:mm format (e.g. 7:30 AM -> 07:30, 1:00 PM -> 13:00, 5:30 PM -> 17:30).
4. If an entry occurs on multiple days (e.g. Mon, Wed, Fri), group them into a single entry with daysOfWeek: [1, 3, 5].
''';

  /// Parses schedule from image bytes using Gemini Multimodal AI
  Future<List<ScheduleEntry>> parseImage({
    required Uint8List imageBytes,
    required String mimeType,
    String? apiKey,
  }) async {
    // If no API key is supplied, return sample realistic parsed data for testing
    if (apiKey == null || apiKey.trim().isEmpty) {
      debugPrint('No Gemini API key provided. Using realistic demo parsed schedule data.');
      return _generateDemoParsedData();
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey.trim(),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1,
        ),
      );

      final content = [
        Content.multi([
          TextPart(_defaultPrompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final rawText = response.text;

      if (rawText == null || rawText.trim().isEmpty) {
        throw Exception('AI returned an empty response. Please try a clearer screenshot.');
      }

      // Clean response of any accidental markdown backticks
      String cleanedJson = rawText.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.replaceFirst('```json', '');
      }
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.replaceFirst('```', '');
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      cleanedJson = cleanedJson.trim();

      final dynamic decoded = jsonDecode(cleanedJson);
      if (decoded is! List) {
        throw Exception('Expected JSON array of schedules but received a single object.');
      }

      final List<ScheduleEntry> parsedEntries = [];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final title = item['title']?.toString() ?? 'Untitled Schedule';
          final categoryStr = item['category']?.toString();
          final category = ScheduleCategoryExtension.fromString(categoryStr);

          final List<int> days = [];
          if (item['daysOfWeek'] is List) {
            for (final d in item['daysOfWeek']) {
              if (d is num) {
                final intDay = d.toInt();
                if (intDay >= 1 && intDay <= 7) {
                  days.add(intDay);
                }
              }
            }
          }
          if (days.isEmpty) days.add(DateTime.now().weekday);

          final startTime = item['startTime']?.toString() ?? '08:00';
          final endTime = item['endTime']?.toString() ?? '09:00';
          final spansNextDay = item['spansNextDay'] == true ||
              TimeUtils.checkSpansOvernight(startTime, endTime);

          parsedEntries.add(
            ScheduleEntry(
              title: title,
              category: category,
              daysOfWeek: days,
              startTime: startTime,
              endTime: endTime,
              spansNextDay: spansNextDay,
              location: item['location']?.toString(),
              notes: item['notes']?.toString(),
              reminders: [category.defaultReminderLeadMinutes],
            ),
          );
        }
      }

      return parsedEntries;
    } catch (e) {
      debugPrint('Gemini parsing error: $e');
      rethrow;
    }
  }

  /// Demo mock parsed entries for instant offline UI testing
  static List<ScheduleEntry> _generateDemoParsedData() {
    return [
      ScheduleEntry(
        title: 'IT 211 - Data Structures & Algorithms',
        category: ScheduleCategory.classSchedule,
        daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
        startTime: '08:30',
        endTime: '10:00',
        location: 'Computer Lab 3 - Main Bldg',
        notes: 'Prof. Garcia • Bring Flash Drive',
        reminders: [15],
      ),
      ScheduleEntry(
        title: 'ENG 102 - Purposive Communication',
        category: ScheduleCategory.classSchedule,
        daysOfWeek: [2, 4], // Tue, Thu
        startTime: '10:30',
        endTime: '12:00',
        location: 'Room 402 - Arts Bldg',
        notes: 'Speech presentation weekly',
        reminders: [15],
      ),
      ScheduleEntry(
        title: 'Closing Shift - Cashier & Inventory',
        category: ScheduleCategory.workShift,
        daysOfWeek: [5, 6], // Fri, Sat
        startTime: '16:00',
        endTime: '23:00',
        location: 'Branch Station 2',
        notes: 'Supervisor: Mark • Wear black apron',
        reminders: [60, 15],
      ),
      ScheduleEntry(
        title: 'Overnight Duty',
        category: ScheduleCategory.duty,
        daysOfWeek: [7], // Sun
        startTime: '22:00',
        endTime: '06:00',
        spansNextDay: true,
        location: 'Command Center / Desk',
        notes: 'Logbook turnover at 05:45 AM',
        reminders: [60],
      ),
    ];
  }
}
