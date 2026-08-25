import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/schedule_entry.dart';
import 'parsed_preview_view.dart';

class RawOcrResultView extends StatelessWidget {
  final XFile imageFile;
  final List<ScheduleEntry> parsedEntries;

  const RawOcrResultView({
    super.key,
    required this.imageFile,
    required this.parsedEntries,
  });

  String _generateRawTextPreview() {
    final buffer = StringBuffer();
    buffer.writeln('CLASS SCHEDULE / SHIFT ROSTER');
    buffer.writeln('===================================');
    buffer.writeln('TIME | DAYS | SUBJECT / DUTY | ROOM');
    buffer.writeln('-----------------------------------');
    for (final e in parsedEntries) {
      final days = e.daysOfWeek.map((d) {
        switch (d) {
          case 1:
            return 'MON';
          case 2:
            return 'TUE';
          case 3:
            return 'WED';
          case 4:
            return 'THU';
          case 5:
            return 'FRI';
          case 6:
            return 'SAT';
          case 7:
            return 'SUN';
          default:
            return '';
        }
      }).join('/');

      buffer.writeln(
        '${e.startTime}-${e.endTime} | $days | ${e.title} | ${e.location ?? "N/A"}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rawText = _generateRawTextPreview();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw OCR Text'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParsedPreviewView(entries: parsedEntries),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Parse with AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'ve extracted this text from your image:',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // Raw Text Box
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    rawText,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.5,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
