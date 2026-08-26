import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/schedule_category.dart';
import '../../models/schedule_entry.dart';
import '../config/app_config.dart';

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

  /// Parses schedule from image/PDF bytes using Gemini Multimodal AI
  Future<List<ScheduleEntry>> parseImage({
    required Uint8List imageBytes,
    required String mimeType,
    String? apiKey,
  }) async {
    final effectiveKey = (apiKey != null && apiKey.trim().isNotEmpty)
        ? apiKey.trim()
        : AppConfig.defaultGeminiApiKey;

    if (effectiveKey.isEmpty) {
      throw Exception('Gemini API key is missing. Please configure GEMINI_API_KEY in your .env or Settings.');
    }

    final String normalizedMime;
    if (mimeType.contains('pdf') || mimeType.endsWith('.pdf')) {
      normalizedMime = 'application/pdf';
    } else if (mimeType.contains('png')) {
      normalizedMime = 'image/png';
    } else if (mimeType.contains('webp')) {
      normalizedMime = 'image/webp';
    } else if (mimeType.contains('heic')) {
      normalizedMime = 'image/heic';
    } else {
      normalizedMime = 'image/jpeg';
    }

    // List of verified active model candidates (fastest/cheapest first)
    final modelNames = ['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-1.5-pro'];
    String? rawResponseText;
    String lastErrorMessage = '';

    for (final modelName in modelNames) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: effectiveKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.1,
          ),
        );

        final content = [
          Content.multi([
            TextPart(_defaultPrompt),
            DataPart(normalizedMime, imageBytes),
          ])
        ];

        final response = await model
            .generateContent(content)
            .timeout(const Duration(seconds: 45));

        if (response.text != null && response.text!.trim().isNotEmpty) {
          rawResponseText = response.text;
          debugPrint('ScheduleParserService: Successfully extracted via $modelName');
          break;
        }
      } catch (e) {
        lastErrorMessage = e.toString();
        debugPrint('ScheduleParserService: Model $modelName failed: $e. Trying next candidate...');
      }
    }

    if (rawResponseText == null || rawResponseText.trim().isEmpty) {
      throw Exception('Failed to process image with Gemini AI: ${lastErrorMessage.isNotEmpty ? lastErrorMessage : "No response from AI."}');
    }

    try {
      // Clean response of any accidental markdown backticks
      String cleanedJson = rawResponseText.trim();
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
        throw Exception('AI output was not in the expected schedule format.');
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

          final rawStart = item['startTime']?.toString() ?? '08:00';
          final rawEnd = item['endTime']?.toString() ?? '09:30';
          final spansNextDay = item['spansNextDay'] as bool? ?? false;
          final location = item['location']?.toString();
          final notes = item['notes']?.toString();

          parsedEntries.add(
            ScheduleEntry(
              title: title,
              category: category,
              daysOfWeek: days,
              startTime: rawStart,
              endTime: rawEnd,
              spansNextDay: spansNextDay,
              location: location,
              notes: notes,
              reminders: [15],
              isActive: true,
            ),
          );
        }
      }

      if (parsedEntries.isEmpty) {
        throw Exception('No schedules could be extracted from this image. Please ensure the timetable is clearly visible.');
      }

      return parsedEntries;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to decode extracted schedules: $e');
    }
  }
}
