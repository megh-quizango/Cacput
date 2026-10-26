import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../core/constants/app_constants.dart';

class ProjectNotifier extends StateNotifier<List<ProjectModel>> {
  ProjectNotifier()
      : super([
          ProjectModel(
            id: "proj_sample",
            title: "Sample Photo",
            thumbnailAsset: AppConstants.sampleLakeAsset,
            aspectRatio: "9:16",
            lastModified: DateTime.now().subtract(const Duration(hours: 2)),
            durationSeconds: 15,
            resolution: "1080p",
            fps: 60,
          ),
        ]);

  void addProject(ProjectModel project) {
    state = [project, ...state];
  }

  void updateProject(ProjectModel updated) {
    state = state.map((p) => p.id == updated.id ? updated : p).toList();
  }

  void deleteProject(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  ProjectModel createDraftFromTemplate({
    required String title,
    required String thumbnailAsset,
    required String aspectRatio,
  }) {
    final newProj = ProjectModel(
      id: "proj_${DateTime.now().millisecondsSinceEpoch}",
      title: title,
      thumbnailAsset: thumbnailAsset,
      aspectRatio: aspectRatio,
      lastModified: DateTime.now(),
      durationSeconds: 15,
      resolution: "1080p",
      fps: 60,
    );
    addProject(newProj);
    return newProj;
  }
}

final projectProvider =
    StateNotifierProvider<ProjectNotifier, List<ProjectModel>>((ref) {
  return ProjectNotifier();
});

final currentEditingProjectProvider = StateProvider<ProjectModel?>((ref) {
  final projects = ref.watch(projectProvider);
  return projects.isNotEmpty ? projects.first : null;
});
