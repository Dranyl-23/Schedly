import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm_tone.dart';

class SoundSettingsState {
  final String selectedToneId;
  final String? playingToneId;

  const SoundSettingsState({
    this.selectedToneId = 'crystal_chime',
    this.playingToneId,
  });

  AlarmTone get selectedTone => AlarmTone.fromId(selectedToneId);

  SoundSettingsState copyWith({
    String? selectedToneId,
    String? playingToneId,
    bool clearPlaying = false,
  }) {
    return SoundSettingsState(
      selectedToneId: selectedToneId ?? this.selectedToneId,
      playingToneId: clearPlaying ? null : (playingToneId ?? this.playingToneId),
    );
  }
}

class SoundSettingsNotifier extends StateNotifier<SoundSettingsState> {
  static const String _key = 'default_alarm_tone_id';
  Box? _box;
  AudioPlayer? _player;

  SoundSettingsNotifier() : super(const SoundSettingsState()) {
    _init();
  }

  AudioPlayer get _audioPlayer {
    if (_player == null) {
      _player = AudioPlayer();
      _configureAlarmAudioContext(_player!);
    }
    return _player!;
  }

  void _configureAlarmAudioContext(AudioPlayer player) {
    try {
      final audioContext = AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm, // Routes to Alarm Volume slider (STREAM_ALARM)
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.duckOthers,
          },
        ),
      );
      player.setAudioContext(audioContext);
      AudioPlayer.global.setAudioContext(audioContext);
    } catch (_) {}
  }

  Future<void> _init() async {
    _box = await Hive.openBox('app_settings_box');
    final saved = _box?.get(_key, defaultValue: 'crystal_chime') as String;
    state = state.copyWith(selectedToneId: saved);
  }

  Future<void> selectTone(String id) async {
    _box ??= await Hive.openBox('app_settings_box');
    await _box?.put(_key, id);
    state = state.copyWith(selectedToneId: id);
  }

  Future<void> playPreview(String toneId) async {
    if (state.playingToneId == toneId) {
      stopPreview();
      return;
    }

    state = state.copyWith(playingToneId: toneId);

    try {
      HapticFeedback.mediumImpact();
      final tone = AlarmTone.fromId(toneId);
      if (tone.soundFile != null) {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(tone.soundFile!));
      } else {
        await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }

    // Auto reset playing indicator after preview duration
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && state.playingToneId == toneId) {
        state = state.copyWith(clearPlaying: true);
      }
    });
  }

  void stopPreview() {
    try {
      _player?.stop();
    } catch (_) {}
    state = state.copyWith(clearPlaying: true);
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}

final soundSettingsProvider =
    StateNotifierProvider<SoundSettingsNotifier, SoundSettingsState>((ref) {
  return SoundSettingsNotifier();
});
