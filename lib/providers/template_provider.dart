import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/template_model.dart';
import '../core/constants/app_constants.dart';

final allTemplatesList = <TemplateModel>[
  const TemplateModel(
    id: "temp_travel",
    title: "Travel Vlog",
    category: "Travel",
    durationText: "15s",
    usesFormatted: "12.5K uses",
    aspectRatio: "9:16",
    description:
        "Capture your adventures with cinematic transitions, map overlays, and upbeat background music. Perfect for travel reels and vacation highlights.",
    features: [
      "Cinematic Transitions",
      "Map Overlay",
      "Travel Music",
      "Text Titles",
    ],
    thumbnailAsset: AppConstants.sampleCoffeeAsset,
    isHot: true,
    playsFormatted: "31K",
  ),
  const TemplateModel(
    id: "temp_gaming",
    title: "Gaming Intro",
    category: "Gaming",
    durationText: "10s",
    usesFormatted: "45K uses",
    aspectRatio: "16:9",
    description:
        "High-energy neon glitches, bass-boosted sound effects, and 3D gamer tag reveals. Ideal for stream intros and montages.",
    features: [
      "Glitch FX",
      "Bass Boost Audio",
      "Animated Logos",
      "RGB Chromatic",
    ],
    thumbnailAsset: AppConstants.sampleWheelAsset,
    isHot: true,
    playsFormatted: "45K",
  ),
  const TemplateModel(
    id: "temp_business",
    title: "Business Promo",
    category: "Business",
    durationText: "30s",
    usesFormatted: "52K uses",
    aspectRatio: "1:1",
    description:
        "Clean, corporate typography, kinetic statistic charts, and smooth brand color accents built for professional social marketing.",
    features: [
      "Kinetic Text",
      "Brand Color Accent",
      "Chart Animations",
      "Outro CTA",
    ],
    thumbnailAsset: AppConstants.sampleForestAsset,
    isHot: true,
    playsFormatted: "52K",
  ),
  const TemplateModel(
    id: "temp_wedding",
    title: "Wedding Highlights",
    category: "Trending",
    durationText: "60s",
    usesFormatted: "67K uses",
    aspectRatio: "9:16",
    description:
        "Soft light leaks, vintage film grain, elegant serif titles, and sentimental acoustic music for romantic memories.",
    features: [
      "Film Grain",
      "Light Leaks",
      "Serif Typography",
      "Slow-Motion Ramps",
    ],
    thumbnailAsset: AppConstants.sampleLakeAsset,
    isHot: true,
    playsFormatted: "67K",
  ),
  const TemplateModel(
    id: "temp_tiktok",
    title: "TikTok Trend Beat",
    category: "Trending",
    durationText: "12s",
    usesFormatted: "89K uses",
    aspectRatio: "9:16",
    description:
        "Ultra-fast velocity cuts snapped directly to the kick-drum beat with screen shakes and flash transitions.",
    features: [
      "Auto Beat Sync",
      "Velocity Curves",
      "Flash Impact",
      "Zoom Blur",
    ],
    thumbnailAsset: AppConstants.sampleCoffeeAsset,
    isHot: false,
    playsFormatted: "89K",
  ),
  const TemplateModel(
    id: "temp_youtube",
    title: "YouTube Intro",
    category: "Trending",
    durationText: "08s",
    usesFormatted: "38K uses",
    aspectRatio: "16:9",
    description:
        "Modern subscribe button animation, social handle badges, and audio chime soundscape.",
    features: [
      "Subscribe Stamp",
      "Social Badges",
      "Bell Notification FX",
      "Minimalist Wave",
    ],
    thumbnailAsset: AppConstants.sampleForestAsset,
    isHot: false,
    playsFormatted: "38K",
  ),
];

final selectedCategoryProvider = StateProvider<String>((ref) => "All");

final searchQueryProvider = StateProvider<String>((ref) => "");

final filteredTemplatesProvider = Provider<List<TemplateModel>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return allTemplatesList.where((t) {
    final matchesCategory = category == "All" || t.category == category;
    final matchesQuery = query.isEmpty ||
        t.title.toLowerCase().contains(query) ||
        t.category.toLowerCase().contains(query) ||
        t.description.toLowerCase().contains(query);
    return matchesCategory && matchesQuery;
  }).toList();
});
