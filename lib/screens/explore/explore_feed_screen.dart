import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/route_names.dart';
import '../../providers/template_provider.dart';
import '../../widgets/rounded_pill.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class ExploreFeedScreen extends ConsumerStatefulWidget {
  const ExploreFeedScreen({super.key});

  @override
  ConsumerState<ExploreFeedScreen> createState() => _ExploreFeedScreenState();
}

class _ExploreFeedScreenState extends ConsumerState<ExploreFeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    "All",
    "Trending",
    "Travel",
    "Gaming",
    "Business",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveOrientationHelper.enforce(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final templates = ref.watch(filteredTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Explore", style: AppTypography.displayLarge),
                  const SizedBox(height: 4),
                  Text(
                    "Discover templates for every mood",
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 18),

                  // Search Bar matching Screen 25
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).state = val;
                    },
                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search templates...",
                      hintStyle: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: AppColors.cardSurface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.brandPink, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Category Pills
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = selectedCategory == cat;
                  return RoundedPill(
                    label: cat,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = cat;
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Staggered dual-column grid
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            "No templates found",
                            style: AppTypography.titleMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: templates.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return _buildTemplateCard(context, template);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, template) {
    return GestureDetector(
      onTap: () {
        context.push("${RouteNames.templateDetail}/${template.id}");
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                template.thumbnailAsset,
                fit: BoxFit.cover,
              ),

              // Vignette overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),

              // Top pill with play count badge matching Screen 25 ("31K", "45K", "52K", "67K")
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppColors.brandCyan.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          size: 13, color: AppColors.brandCyan),
                      const SizedBox(width: 3),
                      Text(
                        template.playsFormatted,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandCyan,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Title and Category
              Positioned(
                bottom: 14,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          template.category,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          template.durationText,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.brandPink,
                            fontWeight: FontWeight.w700,
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
  }
}
