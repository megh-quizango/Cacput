import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/route_names.dart';
import '../../providers/user_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/template_provider.dart';
import '../studio/widgets/new_project_modal.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ResponsiveOrientationHelper.enforce(context);
    final user = ref.watch(userProvider);
    final projects = ref.watch(projectProvider);
    final templates = ref.watch(filteredTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header: "Hey, {name} 👋" + Filter Settings Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Hey, ${user.displayName}",
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "👋",
                            style: TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "What will you create today?",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Top right filter / settings circle button
                  InkWell(
                    onTap: () => context.push(RouteNames.settings),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Hero Action Card: "NEW PROJECT" / "Start Creating"
              _buildHeroProjectCard(context),
              const SizedBox(height: 16),

              // 3. 3 Metrics Counters: "0 Projects", "6 Templates", "4K Export"
              _buildMetricsRow(projects.length),
              const SizedBox(height: 28),

              // 4. Quick Tools Section (stadium capsules with colored borders)
              Text(
                "Quick Tools",
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _buildQuickToolsRow(context, ref),
              const SizedBox(height: 28),

              // 5. Recent Work (Screen 37)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Work",
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(RouteNames.myStudio);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandPink,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "View all",
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.brandPink,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentWorkCard(context, ref, projects),
              const SizedBox(height: 28),

              // 6. Trending Now Section
              Text(
                "Trending Now",
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _buildTrendingGrid(context, templates),
            ],
          ),
        ),
      ),
    );
  }

  // Hero Card matching Screen 19
  Widget _buildHeroProjectCard(BuildContext context) {
    return GestureDetector(
      onTap: () => NewProjectModal.show(context),
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: AppColors.heroPinkGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPink.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ambient curved decorative circle matching original screenshot
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pill Badge: "NEW PROJECT"
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      "NEW PROJECT",
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Start Creating",
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Video, photo & more",
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      // Floating white circle with pink plus icon
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.brandPink,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3 Metrics row: "0 Projects", "6 Templates", "4K Export"
  Widget _buildMetricsRow(int projectsCount) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            count: "$projectsCount",
            label: "Projects",
            countColor: AppColors.brandPink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            count: "6",
            label: "Templates",
            countColor: AppColors.brandCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            count: "4K",
            label: "Export",
            countColor: AppColors.brandGold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String count,
    required String label,
    required Color countColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: AppTypography.displayLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: countColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Tools Row (stadium pills matching Screen 19 crop)
  Widget _buildQuickToolsRow(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // AI Magic (green)
          _buildQuickToolPill(
            icon: Icons.bolt_rounded,
            label: "AI Magic",
            bgColor: AppColors.toolGreenBg,
            borderColor: AppColors.toolGreenBorder,
            textColor: AppColors.brandGreen,
            onTap: () => context.go(RouteNames.aiStudio),
          ),
          const SizedBox(width: 12),

          // Templates (pink)
          _buildQuickToolPill(
            icon: Icons.grid_view_rounded,
            label: "Templates",
            bgColor: AppColors.toolPinkBg,
            borderColor: AppColors.toolPinkBorder,
            textColor: AppColors.brandPink,
            onTap: () => context.go(RouteNames.explore),
          ),
          const SizedBox(width: 12),

          // Blank (gold)
          _buildQuickToolPill(
            icon: Icons.crop_free_rounded,
            label: "Blank",
            bgColor: AppColors.toolGoldBg,
            borderColor: AppColors.toolGoldBorder,
            textColor: AppColors.brandGold,
            onTap: () {
              final project = ref.read(projectProvider.notifier).createDraftFromTemplate(
                title: "Blank Project",
                thumbnailAsset: AppConstants.sampleForestAsset,
                aspectRatio: "9:16",
              );
              ref.read(currentEditingProjectProvider.notifier).state = project;
              context.push(RouteNames.editor);
            },
          ),
          const SizedBox(width: 12),

          // Studio (purple)
          _buildQuickToolPill(
            icon: Icons.video_camera_back_rounded,
            label: "Studio",
            bgColor: AppColors.toolPurpleBg,
            borderColor: AppColors.toolPurpleBorder,
            textColor: AppColors.brandPurple,
            onTap: () => context.go(RouteNames.myStudio),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent Work Card
  Widget _buildRecentWorkCard(
      BuildContext context, WidgetRef ref, List projects) {
    return GestureDetector(
      onTap: () {
        if (projects.isNotEmpty) {
          ref.read(currentEditingProjectProvider.notifier).state = projects.first;
        }
        context.push(RouteNames.editor);
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Thumbnail image with gradient overlay
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: SizedBox(
                width: 100,
                height: 120,
                child: Image.asset(
                  AppConstants.sampleLakeAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    projects.isNotEmpty ? projects.first.title : "Sample Photo",
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tap to edit • 9:16 portrait",
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.brandPink),
                      const SizedBox(width: 4),
                      Text(
                        "Edited 2 hours ago",
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandPink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 18),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textMuted, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Trending Now Horizontal/Grid Cards
  Widget _buildTrendingGrid(BuildContext context, List templates) {
    final trendingTemplates =
        templates.take(4).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trendingTemplates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final item = trendingTemplates[index];
        return GestureDetector(
          onTap: () {
            context.push("${RouteNames.templateDetail}/${item.id}");
          },
          child: Container(
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
                    item.thumbnailAsset,
                    fit: BoxFit.cover,
                  ),
                  // Dark vignette gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                      ),
                    ),
                  ),

                  // "HOT" Badge top-right
                  if (item.isHot)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandPink,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          "HOT",
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),

                  // Bottom Title and Play Count
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.play_arrow_rounded,
                                size: 14, color: AppColors.brandCyan),
                            const SizedBox(width: 2),
                            Text(
                              item.playsFormatted,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.brandCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.durationText,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
