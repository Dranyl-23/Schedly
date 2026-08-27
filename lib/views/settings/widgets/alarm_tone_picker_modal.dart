import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/alarm_tone.dart';
import '../../../providers/sound_settings_provider.dart';

class AlarmTonePickerModal extends ConsumerWidget {
  const AlarmTonePickerModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AlarmTonePickerModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final soundState = ref.watch(soundSettingsProvider);
    final soundNotifier = ref.read(soundSettingsProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alarm Sound & Tone',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap ▶ to preview or tap card to select tone',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // List of Alarm Tones
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: AlarmTone.presets.map((tone) {
                    final isSelected = soundState.selectedToneId == tone.id;
                    final isPlaying = soundState.playingToneId == tone.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: InkWell(
                        onTap: () {
                          soundNotifier.selectTone(tone.id);
                          soundNotifier.playPreview(tone.id);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                                : (isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Tone Icon Box
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: tone.color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  tone.icon,
                                  color: tone.color,
                                  size: 22,
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Name & Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tone.name,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tone.description,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Play / Preview Action Button
                              IconButton(
                                tooltip: isPlaying ? 'Playing preview...' : 'Play preview',
                                onPressed: () {
                                  soundNotifier.playPreview(tone.id);
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? const Color(0xFF2563EB)
                                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                                    size: 17,
                                    color: isPlaying ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                              ),

                              // Selected Checkmark
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
