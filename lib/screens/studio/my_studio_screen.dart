import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/route_names.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import '../../widgets/glowing_action_button.dart';
import 'widgets/new_project_modal.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class MyStudioScreen extends ConsumerStatefulWidget {
  const MyStudioScreen({super.key});

  @override
  ConsumerState<MyStudioScreen> createState() => _MyStudioScreenState();
}

class _MyStudioScreenState extends ConsumerState<MyStudioScreen> {
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveOrientationHelper.enforce(context);
    final projects = ref.watch(projectProvider);
    final filteredProjects = projects.where((p) {
      if (_searchFilter.isEmpty) return true;
      return p.title.toLowerCase().contains(_searchFilter.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar matching Screen 30
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Studio",
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${projects.length} ${projects.length == 1 ? "project" : "projects"}",
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Grid / List Toggle Switcher matching original crop
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.grid_view_rounded,
                            size: 18,
                            color: _isGridView
                                ? AppColors.brandPink
                                : AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _isGridView = true),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 18,
                            color: !_isGridView
                                ? AppColors.brandPink
                                : AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _isGridView = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Search Bar matching Screen 30
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchFilter = val;
                  });
                },
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search your projects...",
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
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppColors.brandPink, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Main Content Area (Empty state vs Drafts)
            Expanded(
              child: filteredProjects.isEmpty
                  ? _buildEmptyState(context)
                  : (_isGridView
                      ? _buildProjectsGrid(filteredProjects)
                      : _buildProjectsList(filteredProjects)),
            ),
          ],
        ),
      ),
      floatingActionButton: projects.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => NewProjectModal.show(context),
              backgroundColor: AppColors.brandPink,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  // Exact Empty State matching Screen 30 screenshot
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Squircle with camera icon matching crop
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF161622),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Center(
                child: Icon(
                  Icons.videocam_rounded,
                  color: AppColors.brandPink,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title: "Studio is Empty"
            Text(
              "Studio is Empty",
              style: AppTypography.displayLarge.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle: "Your creative space awaits"
            Text(
              "Your creative space awaits",
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 36),

            // Button: "Create Project"
            GlowingActionButton(
              label: "Create Project",
              icon: Icons.add_rounded,
              onTap: () => NewProjectModal.show(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsGrid(List<ProjectModel> projects) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: projects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectsList(List<ProjectModel> projects) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectListTile(project);
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return GestureDetector(
      onTap: () {
        ref.read(currentEditingProjectProvider.notifier).state = project;
        context.push(RouteNames.editor);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      project.thumbnailAsset,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project.durationFormatted,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${project.aspectRatio} • ${project.resolution}",
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildProjectListTile(ProjectModel project) {
    return GestureDetector(
      onTap: () {
        ref.read(currentEditingProjectProvider.notifier).state = project;
        context.push(RouteNames.editor);
      },
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: Image.asset(
                  project.thumbnailAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    project.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${project.aspectRatio} • ${project.durationFormatted} • ${project.resolution}",
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textMuted),
              onPressed: () {
                _showProjectMenu(project);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectMenu(ProjectModel project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white),
              title: const Text("Open in Editor"),
              onTap: () {
                Navigator.pop(context);
                ref.read(currentEditingProjectProvider.notifier).state = project;
                context.push(RouteNames.editor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              title: const Text("Delete Project",
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                ref.read(projectProvider.notifier).deleteProject(project.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
