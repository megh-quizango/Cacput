import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/project_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class TimelineEditorScreen extends ConsumerStatefulWidget {
  const TimelineEditorScreen({super.key});

  @override
  ConsumerState<TimelineEditorScreen> createState() =>
      _TimelineEditorScreenState();
}

class _TimelineEditorScreenState extends ConsumerState<TimelineEditorScreen> {
  bool _isPlaying = false;
  double _playheadPosition = 0.25; // 0.0 to 1.0
  Timer? _playbackTimer;
  int _totalDurationSeconds = 15;

  String _activeTool = "Split";
  String _selectedSplitOption = "Half";
  String _selectedFilter = "Normal";
  String _selectedCrop = "9:16";
  double _volumeLevel = 0.8;
  double _playbackSpeed = 1.0;
  String _textOverlay = "";
  final TextEditingController _textController = TextEditingController();

  final List<Map<String, dynamic>> _dockTools = const [
    {"id": "Split", "icon": Icons.content_cut_rounded, "label": "Split"},
    {"id": "Crop", "icon": Icons.crop_rounded, "label": "Crop"},
    {"id": "Filter", "icon": Icons.photo_filter_rounded, "label": "Filter"},
    {"id": "Text", "icon": Icons.text_fields_rounded, "label": "Text"},
    {"id": "Audio", "icon": Icons.music_note_rounded, "label": "Audio"},
    {"id": "Sticker", "icon": Icons.emoji_emotions_rounded, "label": "Sticker"},
    {"id": "Speed", "icon": Icons.speed_rounded, "label": "Speed"},
  ];

  final List<String> _splitOptions = [
    "Half",
    "Quarter",
    "One-Third",
    "Three Quarter",
    "Manual",
  ];

  final List<String> _filters = [
    "Normal",
    "Cinematic",
    "Vintage",
    "B&W",
    "Cyberpunk",
    "Glow",
  ];

  final List<String> _cropRatios = ["9:16", "16:9", "1:1", "4:5"];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() {
          _playheadPosition += (0.1 / _totalDurationSeconds) * _playbackSpeed;
          if (_playheadPosition >= 1.0) {
            _playheadPosition = 0.0;
            _isPlaying = false;
            _playbackTimer?.cancel();
          }
        });
      });
    } else {
      _playbackTimer?.cancel();
    }
  }

  String get _formattedTimecode {
    final currentSec = (_playheadPosition * _totalDurationSeconds).toInt();
    final curMins = (currentSec ~/ 60).toString().padLeft(2, '0');
    final curSecs = (currentSec % 60).toString().padLeft(2, '0');
    final totMins = (_totalDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final totSecs = (_totalDurationSeconds % 60).toString().padLeft(2, '0');
    return "$curMins:$curSecs / $totMins:$totSecs";
  }

  ColorFilter? get _activeColorFilter {
    switch (_selectedFilter) {
      case "B&W":
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case "Vintage":
        return const ColorFilter.matrix(<double>[
          0.9, 0.0, 0.0, 0, 30,
          0.0, 0.8, 0.0, 0, 15,
          0.0, 0.0, 0.6, 0, -20,
          0, 0, 0, 1, 0,
        ]);
      case "Cyberpunk":
        return const ColorFilter.matrix(<double>[
          1.2, 0.0, 0.2, 0, 20,
          0.0, 0.9, 0.2, 0, -10,
          0.2, 0.0, 1.3, 0, 30,
          0, 0, 0, 1, 0,
        ]);
      case "Cinematic":
        return const ColorFilter.matrix(<double>[
          0.95, 0.0, 0.0, 0, 10,
          0.0, 1.05, 0.0, 0, 10,
          0.0, 0.0, 1.15, 0, 20,
          0, 0, 0, 1, 0,
        ]);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveOrientationHelper.enforce(context);
    final currentProject = ref.watch(currentEditingProjectProvider);
    final thumbnail = currentProject?.thumbnailAsset ?? AppConstants.sampleLakeAsset;
    final title = currentProject?.title ?? "Sample Photo";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: Colors.white, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Undo split action"), duration: Duration(milliseconds: 900)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, color: Colors.white, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Redo split action"), duration: Duration(milliseconds: 900)),
              );
            },
          ),
          const SizedBox(width: 4),
          // "Export" button matching Screen 32
          TextButton(
            onPressed: () => _showExportSheet(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandPink,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(
              "Export",
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.brandPink,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Center Viewport: 9:16 portrait video preview matching Screen 32
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _selectedCrop == "16:9"
                      ? 16 / 9
                      : (_selectedCrop == "1:1"
                          ? 1 / 1
                          : (_selectedCrop == "4:5" ? 4 / 5 : 9 / 16)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColorFiltered(
                            colorFilter: _activeColorFilter ??
                                const ColorFilter.mode(
                                    Colors.transparent, BlendMode.multiply),
                            child: Image.asset(
                              thumbnail,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Text Subtitle overlay if added
                          if (_textOverlay.isNotEmpty)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _textOverlay,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: AppColors.brandPink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),

                          // Play / Pause central trigger
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              color: Colors.transparent,
                              child: Center(
                                child: AnimatedOpacity(
                                  opacity: _isPlaying ? 0.0 : 0.85,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.65),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 38,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom timecode tag on viewport
                          Positioned(
                            bottom: 10,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formattedTimecode,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Scrubber Track matching Screen 32
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box != null) {
                          setState(() {
                            _playheadPosition = (_playheadPosition +
                                    details.primaryDelta! / 300)
                                .clamp(0.0, 1.0);
                          });
                        }
                      },
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.brandPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            // White vertical cursor playhead line
                            Positioned(
                              left: _playheadPosition * 260,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 3,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Horizontal Tool Dock matching Screen 32
            Container(
              height: 74,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF111119),
                border: Border(
                  top: BorderSide(color: Color(0xFF222230)),
                  bottom: BorderSide(color: Color(0xFF222230)),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dockTools.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tool = _dockTools[index];
                  final isSelected = _activeTool == tool["id"];

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _activeTool = tool["id"];
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 68,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandPink.withOpacity(0.2)
                            : const Color(0xFF1B1B2A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandPink
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tool["icon"],
                            size: 20,
                            color: isSelected
                                ? AppColors.brandPink
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tool["label"],
                            style: AppTypography.labelSmall.copyWith(
                              color: isSelected
                                  ? AppColors.brandPink
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Sub-dock Options Bar matching Screen 32
            Container(
              height: 90,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: const Color(0xFF0C0C14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeTool,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildSubToolBar(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubToolBar() {
    switch (_activeTool) {
      case "Split":
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _splitOptions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, idx) {
            final opt = _splitOptions[idx];
            final isSelected = _selectedSplitOption == opt;
            return InkWell(
              onTap: () {
                setState(() => _selectedSplitOption = opt);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPink.withOpacity(0.2)
                      : const Color(0xFF1B1B2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPink
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  opt,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        );

      case "Filter":
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, idx) {
            final f = _filters[idx];
            final isSelected = _selectedFilter == f;
            return InkWell(
              onTap: () {
                setState(() => _selectedFilter = f);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPink.withOpacity(0.2)
                      : const Color(0xFF1B1B2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPink
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  f,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        );

      case "Crop":
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _cropRatios.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, idx) {
            final ratio = _cropRatios[idx];
            final isSelected = _selectedCrop == ratio;
            return InkWell(
              onTap: () {
                setState(() => _selectedCrop = ratio);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandCyan.withOpacity(0.2)
                      : const Color(0xFF1B1B2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandCyan
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  ratio,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        );

      case "Text":
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Add text title...",
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF1B1B2A),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _textOverlay = _textController.text;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Apply", style: TextStyle(fontSize: 12)),
            ),
          ],
        );

      case "Audio":
        return Row(
          children: [
            const Icon(Icons.volume_down_rounded,
                color: AppColors.brandCyan, size: 20),
            Expanded(
              child: Slider(
                value: _volumeLevel,
                min: 0.0,
                max: 1.0,
                activeColor: AppColors.brandCyan,
                inactiveColor: const Color(0xFF1B1B2A),
                onChanged: (val) {
                  setState(() => _volumeLevel = val);
                },
              ),
            ),
            Text(
              "${(_volumeLevel * 100).toInt()}%",
              style: AppTypography.labelSmall.copyWith(color: Colors.white),
            ),
          ],
        );

      case "Speed":
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [0.5, 1.0, 1.5, 2.0].map((s) {
            final isSelected = _playbackSpeed == s;
            return InkWell(
              onTap: () {
                setState(() => _playbackSpeed = s);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandGold.withOpacity(0.2)
                      : const Color(0xFF1B1B2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandGold
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  "${s}x",
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        );

      default:
        return const Center(child: Text("Ready to apply adjustments"));
    }
  }

  // Export Modal Sheet with 720p / 1080p / 2K
  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ExportModalContent(),
    );
  }
}

class _ExportModalContent extends ConsumerStatefulWidget {
  const _ExportModalContent();

  @override
  ConsumerState<_ExportModalContent> createState() =>
      _ExportModalContentState();
}

class _ExportModalContentState extends ConsumerState<_ExportModalContent> {
  String _selectedRes = "1080p (Full HD - 1920x1080)";
  int _selectedFps = 60;
  bool _isExporting = false;
  double _exportProgress = 0.0;
  bool _isFinished = false;

  void _startExport() {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.05;
    });

    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _exportProgress += 0.08;
        if (_exportProgress >= 1.0) {
          _exportProgress = 1.0;
          _isExporting = false;
          _isFinished = true;
          timer.cancel();
          ref.read(userProvider.notifier).incrementExports();
          ref.read(userProvider.notifier).updateStorageUsed(42);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

          if (!_isFinished) ...[
            Text("Export Resolution", style: AppTypography.titleLarge),
            const SizedBox(height: 6),
            Text(
              "Select render quality and frame rate for your video",
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Resolution Radios
            ...AppConstants.supportedResolutions.map((res) {
              final isSelected = _selectedRes == res;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.brandPink
                          : AppColors.cardBorder,
                    ),
                  ),
                  tileColor: AppColors.canvasBackground,
                  title: Text(res, style: const TextStyle(fontSize: 14)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.brandPink)
                      : null,
                  onTap: () => setState(() => _selectedRes = res),
                ),
              );
            }),

            const SizedBox(height: 12),
            Text("Frame Rate", style: AppTypography.titleMedium.copyWith(fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [30, 60].map((fps) {
                final isSelected = _selectedFps == fps;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text("${fps} FPS"),
                    selected: isSelected,
                    selectedColor: AppColors.brandPink,
                    backgroundColor: AppColors.canvasBackground,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (_) => setState(() => _selectedFps = fps),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            if (_isExporting) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Rendering video frames...",
                          style: AppTypography.labelMedium),
                      Text("${(_exportProgress * 100).toInt()}%",
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.brandPink)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _exportProgress,
                      minHeight: 6,
                      backgroundColor: AppColors.canvasBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.brandPink),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _startExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPink,
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: const Text("Start 4K Rendering"),
              ),
            ],
          ] else ...[
            // Finished State
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandGreen.withOpacity(0.18),
                      border: Border.all(color: AppColors.brandGreen, width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.brandGreen, size: 40),
                  ),
                  const SizedBox(height: 18),
                  Text("Export Complete!", style: AppTypography.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    "Video saved at ${_selectedRes.split(" ").first} • ${_selectedFps} FPS (42.4 MB)",
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.cardBorder),
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text("Done"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final box = context.findRenderObject() as RenderBox?;
                            final origin = box != null
                                ? box.localToGlobal(Offset.zero) & box.size
                                : null;
                            Navigator.pop(context);
                            try {
                              await SharePlus.instance.share(
                                ShareParams(
                                  text: "Check out this video",
                                  sharePositionOrigin: origin,
                                ),
                              );
                            } catch (e) {
                              debugPrint("Error sharing video: $e");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPink,
                            minimumSize: const Size(0, 50),
                          ),
                          child: const Text("Share Video"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);
  }
}
