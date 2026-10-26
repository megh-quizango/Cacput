import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/route_names.dart';
import '../../providers/ai_studio_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/glowing_action_button.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class AutoCaptionScreen extends ConsumerWidget {
  const AutoCaptionScreen({super.key});

  final List<String> _languages = const [
    "English (US)",
    "Bilingual (English + Hindi)",
    "Español (Spanish)",
    "हिन्दी (Hindi)",
    "Français (French)",
    "Deutsch (German)",
  ];

  final List<String> _audioTracks = const [
    "Original Audio",
    "Voiceover Track",
    "Both Tracks Merged",
  ];

  final List<Map<String, dynamic>> _subtitleStyles = const [
    {"name": "Neon Pop", "color": AppColors.brandPink, "bg": Colors.black54},
    {"name": "Cyber Cyan", "color": AppColors.brandCyan, "bg": Colors.black87},
    {"name": "Classic White", "color": Colors.white, "bg": Colors.black45},
    {"name": "Golden Box", "color": Colors.black, "bg": AppColors.brandGold},
    {"name": "Karaoke Pop", "color": AppColors.brandPinkLight, "bg": Colors.transparent},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ResponsiveOrientationHelper.enforce(context);
    final state = ref.watch(autoCaptionProvider);
    final notifier = ref.read(autoCaptionProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text(
          "Auto Caption",
          style: AppTypography.titleLarge.copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Video Preview with Subtitles Overlay
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        AppConstants.sampleLakeAsset,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        color: Colors.black.withOpacity(0.35),
                      ),

                      // Animated Subtitle Preview Overlay
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.brandPink.withOpacity(0.6),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            state.isCompleted
                                ? "Create cinematic stories in seconds ✨"
                                : "Tap Generate to create dynamic subtitles",
                            style: AppTypography.titleMedium.copyWith(
                              color: state.isCompleted
                                  ? AppColors.brandPink
                                  : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.closed_caption_rounded,
                                  color: AppColors.brandCyan, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                state.selectedLanguage.split(" ").first,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.brandCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. Language Selection Dropdown
              Text(
                "Source Language",
                style: AppTypography.titleMedium.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedLanguage,
                    isExpanded: true,
                    dropdownColor: AppColors.cardSurface,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                    items: _languages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang, style: AppTypography.bodyLarge),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setLanguage(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Audio Track Selector
              Text(
                "Sound Track",
                style: AppTypography.titleMedium.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedAudioTrack,
                    isExpanded: true,
                    dropdownColor: AppColors.cardSurface,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                    items: _audioTracks.map((trk) {
                      return DropdownMenuItem<String>(
                        value: trk,
                        child: Text(trk, style: AppTypography.bodyLarge),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setAudioTrack(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Subtitle Style Preview Carousel
              Text(
                "Subtitle Template Style",
                style: AppTypography.titleMedium.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _subtitleStyles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final style = _subtitleStyles[index];
                    final isSelected = state.selectedStyle == style["name"];
                    return InkWell(
                      onTap: () => notifier.setStyle(style["name"]),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brandPink.withOpacity(0.18)
                              : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brandPink
                                : AppColors.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: style["color"],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              style["name"],
                              style: AppTypography.labelMedium.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // 5. Transcription Progress or Result List
              if (state.isGenerating) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.brandPink.withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "AI Transcription Engine",
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.brandPink,
                            ),
                          ),
                          Text(
                            "${(state.progress * 100).toInt()}%",
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.brandPink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 6,
                          backgroundColor: AppColors.canvasBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.brandPink),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.progressStep,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (state.isCompleted) ...[
                Text(
                  "Generated Captions (${state.generatedCaptions.length})",
                  style: AppTypography.titleMedium.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.generatedCaptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = state.generatedCaptions[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.canvasBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${item["start"]} - ${item["end"]}",
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.brandCyan,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item["text"],
                              style: AppTypography.bodyMedium
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                          const Icon(Icons.edit_rounded,
                              size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.canvasBackground,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: GlowingActionButton(
          label: state.isCompleted
              ? "Apply Captions & Edit Timeline"
              : (state.isGenerating
                  ? "Transcribing..."
                  : "Generate Captions"),
          isLoading: state.isGenerating,
          onTap: () {
            if (state.isCompleted) {
              final project = ref
                  .read(projectProvider.notifier)
                  .createDraftFromTemplate(
                    title: "Auto-Captioned Clip",
                    thumbnailAsset: AppConstants.sampleLakeAsset,
                    aspectRatio: "9:16",
                  );
              ref.read(currentEditingProjectProvider.notifier).state = project;
              context.push(RouteNames.editor);
            } else {
              notifier.simulateCaptionGeneration();
            }
          },
        ),
      ),
    );
  }
}
