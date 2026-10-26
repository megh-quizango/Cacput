import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_tool_model.dart';
import '../core/theme/app_colors.dart';

final aiToolsList = <AiToolModel>[
  const AiToolModel(
    id: "auto_caption",
    title: "Auto Caption",
    subtitle: "Auto captions",
    icon: Icons.subtitles_rounded,
    accentColor: AppColors.brandPink,
    route: "/ai/auto-caption",
  ),
  const AiToolModel(
    id: "ai_voice",
    title: "AI Voice",
    subtitle: "Text to voice",
    icon: Icons.record_voice_over_rounded,
    accentColor: AppColors.brandCyan,
    route: "/ai/tool/ai_voice",
  ),
  const AiToolModel(
    id: "background_remove",
    title: "Background Remove",
    subtitle: "Remove background",
    icon: Icons.content_cut_rounded,
    accentColor: AppColors.brandGold,
    route: "/ai/tool/background_remove",
  ),
  const AiToolModel(
    id: "object_remove",
    title: "Object Remove",
    subtitle: "Object removal",
    icon: Icons.healing_rounded,
    accentColor: AppColors.brandPurple,
    route: "/ai/tool/object_remove",
  ),
  const AiToolModel(
    id: "ai_enhance",
    title: "AI Enhance",
    subtitle: "Enhance quality",
    icon: Icons.auto_fix_high_rounded,
    accentColor: AppColors.brandPinkLight,
    route: "/ai/tool/ai_enhance",
  ),
  const AiToolModel(
    id: "video_upscaler",
    title: "Video Upscaler",
    subtitle: "Upscale video",
    icon: Icons.hd_rounded,
    accentColor: AppColors.brandCyanAccent,
    route: "/ai/tool/video_upscaler",
  ),
  const AiToolModel(
    id: "script_gen",
    title: "Script Gen",
    subtitle: "AI scripts",
    icon: Icons.edit_note_rounded,
    accentColor: AppColors.brandGold,
    route: "/ai/tool/script_gen",
  ),
  const AiToolModel(
    id: "ai_translation",
    title: "AI Translation",
    subtitle: "Translate audio",
    icon: Icons.translate_rounded,
    accentColor: AppColors.brandPurple,
    route: "/ai/tool/ai_translation",
  ),
];

class AutoCaptionState {
  final String selectedLanguage;
  final String selectedAudioTrack;
  final String selectedStyle;
  final bool isGenerating;
  final double progress;
  final String progressStep;
  final bool isCompleted;
  final List<Map<String, dynamic>> generatedCaptions;

  const AutoCaptionState({
    this.selectedLanguage = "English (US)",
    this.selectedAudioTrack = "Original Audio",
    this.selectedStyle = "Neon Pop",
    this.isGenerating = false,
    this.progress = 0.0,
    this.progressStep = "Ready",
    this.isCompleted = false,
    this.generatedCaptions = const [
      {"start": "00:01", "end": "00:03", "text": "Welcome to the ultimate video studio"},
      {"start": "00:04", "end": "00:07", "text": "Create cinematic stories in seconds"},
      {"start": "00:08", "end": "00:11", "text": "AI handles captions and transitions"},
      {"start": "00:12", "end": "00:15", "text": "Export in crystal clear 4K ultra HD"},
    ],
  });

  AutoCaptionState copyWith({
    String? selectedLanguage,
    String? selectedAudioTrack,
    String? selectedStyle,
    bool? isGenerating,
    double? progress,
    String? progressStep,
    bool? isCompleted,
    List<Map<String, dynamic>>? generatedCaptions,
  }) {
    return AutoCaptionState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      selectedAudioTrack: selectedAudioTrack ?? this.selectedAudioTrack,
      selectedStyle: selectedStyle ?? this.selectedStyle,
      isGenerating: isGenerating ?? this.isGenerating,
      progress: progress ?? this.progress,
      progressStep: progressStep ?? this.progressStep,
      isCompleted: isCompleted ?? this.isCompleted,
      generatedCaptions: generatedCaptions ?? this.generatedCaptions,
    );
  }
}

class AutoCaptionNotifier extends StateNotifier<AutoCaptionState> {
  AutoCaptionNotifier() : super(const AutoCaptionState());

  void setLanguage(String lang) {
    state = state.copyWith(selectedLanguage: lang);
  }

  void setAudioTrack(String track) {
    state = state.copyWith(selectedAudioTrack: track);
  }

  void setStyle(String style) {
    state = state.copyWith(selectedStyle: style);
  }

  Future<void> simulateCaptionGeneration() async {
    state = state.copyWith(
      isGenerating: true,
      progress: 0.1,
      progressStep: "Extracting acoustic audio stream...",
      isCompleted: false,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      progress: 0.35,
      progressStep: "Transcribing phonemes with deep speech model...",
    );

    await Future.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(
      progress: 0.65,
      progressStep: "Aligning millisecond timecodes...",
    );

    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      progress: 0.90,
      progressStep: "Applying dynamic typography style...",
    );

    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(
      progress: 1.0,
      progressStep: "Captions successfully synchronized!",
      isGenerating: false,
      isCompleted: true,
    );
  }

  void reset() {
    state = state.copyWith(
      isGenerating: false,
      progress: 0.0,
      progressStep: "Ready",
      isCompleted: false,
    );
  }
}

final autoCaptionProvider =
    StateNotifierProvider<AutoCaptionNotifier, AutoCaptionState>((ref) {
  return AutoCaptionNotifier();
});
