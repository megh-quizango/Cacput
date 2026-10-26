import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final int defaultFps;
  final String languageCode;
  final String languageName;
  final int cacheSizeMb;
  final bool enableNotifications;
  final bool addEndingWatermark;
  final String defaultResolution;

  const SettingsState({
    this.defaultFps = 60,
    this.languageCode = "EN",
    this.languageName = "English",
    this.cacheSizeMb = 284,
    this.enableNotifications = true,
    this.addEndingWatermark = false,
    this.defaultResolution = "1080p",
  });

  SettingsState copyWith({
    int? defaultFps,
    String? languageCode,
    String? languageName,
    int? cacheSizeMb,
    bool? enableNotifications,
    bool? addEndingWatermark,
    String? defaultResolution,
  }) {
    return SettingsState(
      defaultFps: defaultFps ?? this.defaultFps,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      addEndingWatermark: addEndingWatermark ?? this.addEndingWatermark,
      defaultResolution: defaultResolution ?? this.defaultResolution,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setFps(int fps) {
    state = state.copyWith(defaultFps: fps);
  }

  void setLanguage(String code, String name) {
    state = state.copyWith(languageCode: code, languageName: name);
  }

  Future<void> clearCache() async {
    // Simulate cache clearing delay
    await Future.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(cacheSizeMb: 0);
  }

  void toggleNotifications(bool val) {
    state = state.copyWith(enableNotifications: val);
  }

  void toggleWatermark(bool val) {
    state = state.copyWith(addEndingWatermark: val);
  }

  void setResolution(String res) {
    state = state.copyWith(defaultResolution: res);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
