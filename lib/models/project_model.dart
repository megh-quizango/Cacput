class ProjectModel {
  final String id;
  final String title;
  final String thumbnailAsset;
  final String aspectRatio;
  final DateTime lastModified;
  final int durationSeconds;
  final String resolution;
  final int fps;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.thumbnailAsset,
    this.aspectRatio = "9:16",
    required this.lastModified,
    this.durationSeconds = 15,
    this.resolution = "1080p",
    this.fps = 60,
  });

  String get durationFormatted {
    final mins = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (durationSeconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? thumbnailAsset,
    String? aspectRatio,
    DateTime? lastModified,
    int? durationSeconds,
    String? resolution,
    int? fps,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      lastModified: lastModified ?? this.lastModified,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
    );
  }
}
