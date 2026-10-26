class TemplateModel {
  final String id;
  final String title;
  final String category;
  final String durationText;
  final String usesFormatted;
  final String aspectRatio;
  final String description;
  final List<String> features;
  final String thumbnailAsset;
  final bool isHot;
  final String playsFormatted;

  const TemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.durationText,
    required this.usesFormatted,
    required this.aspectRatio,
    required this.description,
    required this.features,
    required this.thumbnailAsset,
    this.isHot = false,
    required this.playsFormatted,
  });
}
