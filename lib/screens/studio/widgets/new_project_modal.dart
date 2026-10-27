import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/route_names.dart';
import '../../../providers/project_provider.dart';

class NewProjectModal extends ConsumerWidget {
  const NewProjectModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const NewProjectModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header matching screen 31
              Text(
                "New Project",
                style: AppTypography.titleLarge.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose how you want to start editing",
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Option 1: Browse Templates (Screen 31)
              _buildOptionTile(
                context: context,
                icon: Icons.dashboard_customize_rounded,
                accentColor: AppColors.brandPink,
                title: "Browse Templates",
                subtitle: "Start from a ready-made template",
                onTap: () {
                  Navigator.pop(context);
                  context.go(RouteNames.explore);
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Blank Canvas (Screen 31)
              _buildOptionTile(
                context: context,
                icon: Icons.crop_portrait_rounded,
                accentColor: AppColors.brandCyan,
                title: "Blank Canvas",
                subtitle: "Empty canvas — no gallery needed",
                onTap: () {
                  Navigator.pop(context);
                  final project = ref.read(projectProvider.notifier).createDraftFromTemplate(
                    title: "Blank Project",
                    thumbnailAsset: AppConstants.sampleForestAsset,
                    aspectRatio: "9:16",
                  );
                  ref.read(currentEditingProjectProvider.notifier).state = project;
                  context.push(RouteNames.editor);
                },
              ),
              const SizedBox(height: 12),

              // Option 3: Sample Photo (Screen 31)
              _buildOptionTile(
                context: context,
                icon: Icons.photo_camera_back_rounded,
                accentColor: AppColors.brandGold,
                title: "Sample Photo",
                subtitle: "Try editing with a built-in sample",
                onTap: () {
                  Navigator.pop(context);
                  final project = ref.read(projectProvider.notifier).createDraftFromTemplate(
                    title: "Sample Photo",
                    thumbnailAsset: AppConstants.sampleLakeAsset,
                    aspectRatio: "9:16",
                  );
                  ref.read(currentEditingProjectProvider.notifier).state = project;
                  context.push(RouteNames.editor);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.canvasBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
