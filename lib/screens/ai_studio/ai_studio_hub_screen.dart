import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/route_names.dart';
import '../../providers/ai_studio_provider.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class AiStudioHubScreen extends ConsumerWidget {
  const AiStudioHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ResponsiveOrientationHelper.enforce(context);
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge matching Screen 22: "AI STUDIO"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.toolGreenBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: AppColors.brandGreen.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  "AI STUDIO",
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header: "AI Magic"
              Text(
                "AI Magic",
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "One tap to transform your content",
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // 8 AI Tools Grid matching Screen 22 / 23
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: aiToolsList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.88,
                ),
                itemBuilder: (context, index) {
                  final tool = aiToolsList[index];
                  return _buildAiToolCard(context, tool);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiToolCard(BuildContext context, tool) {
    return GestureDetector(
      onTap: () {
        if (tool.id == "auto_caption") {
          context.push(RouteNames.autoCaption);
        } else {
          // Show simulated AI tool sheet
          _showToolBottomSheet(context, tool);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161622),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Top border colored glow line matching original crop
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tool.accentColor.withOpacity(0.9),
                        tool.accentColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Squircle Icon container matching original crop
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tool.accentColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        tool.icon,
                        color: tool.accentColor,
                        size: 26,
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tool.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tool.subtitle,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  }

  void _showToolBottomSheet(BuildContext context, tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tool.accentColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tool.icon, color: tool.accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tool.title, style: AppTypography.titleLarge),
                    Text(tool.subtitle, style: AppTypography.bodyMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Select a video to apply ${tool.title}. Our on-device neural network will process frames with low latency and hardware acceleration.",
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(RouteNames.editor);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tool.accentColor,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: const Text("Select Video from Studio"),
            ),
          ],
        ),
      ),
    );
  }
}
