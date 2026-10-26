import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/route_names.dart';
import '../../providers/template_provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/glowing_action_button.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class TemplateDetailScreen extends ConsumerStatefulWidget {
  final String templateId;

  const TemplateDetailScreen({super.key, required this.templateId});

  @override
  ConsumerState<TemplateDetailScreen> createState() =>
      _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends ConsumerState<TemplateDetailScreen> {
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    ResponsiveOrientationHelper.enforce(context);
    final templates = ref.watch(filteredTemplatesProvider);
    final template = templates.firstWhere(
      (t) => t.id == widget.templateId,
      orElse: () => allTemplatesList.first,
    );

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top Video Preview Viewport matching Screen 28
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppColors.canvasBackground,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_rounded,
                          color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Template link copied to clipboard!"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        template.thumbnailAsset,
                        fit: BoxFit.cover,
                      ),
                      // Top gradient for app bar readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                              AppColors.canvasBackground,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Center play/pause overlay
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPlaying = !_isPlaying;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),

                      // Simulated Audio waveform at bottom of video
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            const Icon(Icons.music_note_rounded,
                                color: AppColors.brandPink, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Original Audio • Lo-Fi Chill Beats",
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Template Details Body matching Screen 28
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        template.title,
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metadata Pills row matching Screen 28
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildDetailPill(
                            icon: Icons.category_rounded,
                            label: template.category,
                            color: AppColors.brandPink,
                          ),
                          _buildDetailPill(
                            icon: Icons.timer_rounded,
                            label: template.durationText,
                            color: AppColors.brandCyan,
                          ),
                          _buildDetailPill(
                            icon: Icons.file_download_outlined,
                            label: template.usesFormatted,
                            color: AppColors.brandGold,
                          ),
                          _buildDetailPill(
                            icon: Icons.aspect_ratio_rounded,
                            label: template.aspectRatio,
                            color: AppColors.brandPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Description Section
                      Text(
                        "Description",
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        template.description,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Included Features Section
                      Text(
                        "Included Features",
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Column(
                        children: template.features.map<Widget>((feat) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppColors.brandPink,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    feat,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Fixed Action Bar with "Use Template & Edit" CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.canvasBackground.withOpacity(0.95),
                border: const Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: GlowingActionButton(
                label: "Use Template & Edit",
                icon: Icons.movie_creation_rounded,
                onTap: () {
                  final newProject = ref
                      .read(projectProvider.notifier)
                      .createDraftFromTemplate(
                        title: template.title,
                        thumbnailAsset: template.thumbnailAsset,
                        aspectRatio: template.aspectRatio,
                      );
                  ref.read(currentEditingProjectProvider.notifier).state =
                      newProject;
                  context.push(RouteNames.editor);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
