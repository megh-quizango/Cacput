import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../services/ad_tab_service.dart';
import '../../services/connectivity_service.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ResponsiveOrientationHelper.enforce(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final adConfig = ref.watch(adTabConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: AppTypography.titleLarge.copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            // Section 1: GENERAL matching Screen 36
            _buildSectionHeader("GENERAL"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  // Language Selection Tile
                  ListTile(
                    leading: const Icon(Icons.language_rounded,
                        color: AppColors.brandPink),
                    title: const Text("Language"),
                    subtitle: Text(
                      settings.languageName,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandPink.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        settings.languageCode,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.brandPink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    onTap: () => _showLanguageModal(context, ref),
                  ),
                  const Divider(height: 1, indent: 56),

                  // Default Frame Rate Selector
                  ListTile(
                    leading: const Icon(Icons.speed_rounded,
                        color: AppColors.brandCyan),
                    title: const Text("Default Frame Rate"),
                    subtitle: Text(
                      "${settings.defaultFps} FPS",
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: DropdownButton<int>(
                      value: settings.defaultFps,
                      dropdownColor: AppColors.cardSurface,
                      underline: const SizedBox(),
                      items: AppConstants.supportedFrameRates.map((fps) {
                        return DropdownMenuItem<int>(
                          value: fps,
                          child: Text("$fps FPS",
                              style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) notifier.setFps(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: CUSTOM TABS & APP OPEN AD (TESTING)
            _buildSectionHeader("CUSTOM TABS & APP OPEN AD (TESTING)"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  // N Tabs Counter
                  ListTile(
                    leading: const Icon(Icons.tab_rounded, color: AppColors.brandCyan),
                    title: const Text("Tabs to Launch (N)"),
                    subtitle: Text(
                      "${adConfig.tabsCount} Custom Chrome Tabs on click/navigation",
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                          onPressed: adConfig.tabsCount > 1
                              ? () => ref.read(adTabConfigProvider.notifier).setTabsCount(adConfig.tabsCount - 1)
                              : null,
                        ),
                        Text(
                          "${adConfig.tabsCount}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.brandPink),
                          onPressed: adConfig.tabsCount < 10
                              ? () => ref.read(adTabConfigProvider.notifier).setTabsCount(adConfig.tabsCount + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 56),

                  // Auto Launch on Navigation
                  SwitchListTile(
                    secondary: const Icon(Icons.navigation_rounded, color: AppColors.brandPink),
                    title: const Text("Launch on Navigation"),
                    subtitle: Text(
                      "Launch tabs when routes or tabs change",
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    value: adConfig.autoLaunchOnNavigation,
                    activeThumbColor: AppColors.brandPink,
                    onChanged: (val) {
                      ref.read(adTabConfigProvider.notifier).toggleAutoLaunchOnNavigation(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),

                  // Auto Launch on Click
                  SwitchListTile(
                    secondary: const Icon(Icons.touch_app_rounded, color: AppColors.brandGold),
                    title: const Text("Launch on Clicks"),
                    subtitle: Text(
                      "Launch tabs when user taps navigation/actions",
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    value: adConfig.autoLaunchOnClick,
                    activeThumbColor: AppColors.brandPink,
                    onChanged: (val) {
                      ref.read(adTabConfigProvider.notifier).toggleAutoLaunchOnClick(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),

                  // Auto Launch on Back Press / Gesture
                  SwitchListTile(
                    secondary: const Icon(Icons.arrow_back_rounded, color: AppColors.brandPink),
                    title: const Text("Launch on Back Press / Gesture"),
                    subtitle: Text(
                      "Launch tabs when pressing back or swiping back gesture",
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    value: adConfig.autoLaunchOnBack,
                    activeThumbColor: AppColors.brandPink,
                    onChanged: (val) {
                      ref.read(adTabConfigProvider.notifier).toggleAutoLaunchOnBack(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),

                  // Show Ad on App Resume
                  SwitchListTile(
                    secondary: const Icon(Icons.ad_units_rounded, color: AppColors.brandGreen),
                    title: const Text("App Open Ad on Resume"),
                    subtitle: Text(
                      "Display App Open Ad when returning after closing tabs",
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    value: adConfig.showAdOnAppResume,
                    activeThumbColor: AppColors.brandGreen,
                    onChanged: (val) {
                      ref.read(adTabConfigProvider.notifier).toggleShowAdOnAppResume(val);
                    },
                  ),
                  const Divider(height: 1, indent: 56),

                  // Weighted URL Distribution Toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.tune_rounded, color: AppColors.brandCyan),
                    title: const Text("Weighted URL Distribution"),
                    subtitle: Text(
                      "Select Custom Chrome Tab URLs according to assigned weights",
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    value: adConfig.useWeightedUrls,
                    activeThumbColor: AppColors.brandCyan,
                    onChanged: (val) {
                      ref.read(adTabConfigProvider.notifier).toggleUseWeightedUrls(val);
                    },
                  ),

                  // Weighted URLs Configuration Panel
                  if (adConfig.useWeightedUrls) ...[
                    const Divider(height: 1, indent: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white.withOpacity(0.02),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "WEIGHTED URLS (${adConfig.weightedUrls.length})",
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.brandCyan,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                "Total: ${adConfig.weightedUrls.fold<int>(0, (s, w) => s + w.weight)} weight",
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...adConfig.weightedUrls.map((item) {
                            final total = adConfig.weightedUrls.fold<int>(0, (s, w) => s + w.weight);
                            final pct = total > 0 ? ((item.weight / total) * 100).toStringAsFixed(0) : "0";
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.link_rounded, size: 18, color: AppColors.brandCyan),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.url,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "Weight: ${item.weight} ($pct% probability)",
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.textSecondary),
                                    onPressed: item.weight > 5
                                        ? () => ref.read(adTabConfigProvider.notifier).updateUrlWeight(item.id, item.weight - 5)
                                        : null,
                                  ),
                                  Text(
                                    "${item.weight}",
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.brandPink),
                                    onPressed: item.weight < 100
                                        ? () => ref.read(adTabConfigProvider.notifier).updateUrlWeight(item.id, item.weight + 5)
                                        : null,
                                  ),
                                  if (adConfig.weightedUrls.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                      onPressed: () => ref.read(adTabConfigProvider.notifier).removeWeightedUrl(item.id),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.add_link_rounded, size: 18, color: AppColors.brandCyan),
                                label: const Text("Add URL", style: TextStyle(color: AppColors.brandCyan, fontSize: 13)),
                                onPressed: () => _showAddWeightedUrlDialog(context, ref),
                              ),
                              TextButton(
                                child: const Text("Reset Defaults", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                onPressed: () => ref.read(adTabConfigProvider.notifier).resetWeightedUrls(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 1, indent: 20),

                  // Action Buttons: Launch Now & Preview Ad
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.open_in_browser_rounded, size: 16, color: AppColors.brandCyan),
                            label: const Text("Launch N Tabs", style: TextStyle(color: Colors.white, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.brandCyan),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              AdTabService.instance.launchCustomTabs();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.ads_click_rounded, size: 16, color: Colors.white),
                            label: const Text("Preview Ad", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPink,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              AdTabService.instance.showAppOpenAd();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: NETWORK & ORIENTATION STATUS
            _buildSectionHeader("NETWORK & ORIENTATION"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  // Device Orientation Lock Status
                  ListTile(
                    leading: Icon(
                      ResponsiveOrientationHelper.isMobile(context)
                          ? Icons.screen_lock_portrait_rounded
                          : Icons.screen_rotation_rounded,
                      color: AppColors.brandPink,
                    ),
                    title: const Text("Device Screen Type"),
                    subtitle: Text(
                      ResponsiveOrientationHelper.isMobile(context)
                          ? "Mobile Phone • Portrait Locked"
                          : "Tablet / Large Screen • Orientation Unlocked",
                      style: AppTypography.labelSmall.copyWith(
                        color: ResponsiveOrientationHelper.isMobile(context)
                            ? AppColors.brandPink
                            : AppColors.brandGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        "${MediaQuery.sizeOf(context).shortestSide.toInt()} dp",
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),

                  // Network Connection Status
                  ValueListenableBuilder<bool>(
                    valueListenable: ConnectivityService.instance.connectionNotifier,
                    builder: (context, isOnline, _) {
                      return ListTile(
                        leading: Icon(
                          isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          color: isOnline ? AppColors.brandGreen : Colors.redAccent,
                        ),
                        title: const Text("Internet Status"),
                        subtitle: Text(
                          isOnline ? "Connected • Active" : "Disconnected • Offline",
                          style: AppTypography.labelSmall.copyWith(
                            color: isOnline ? AppColors.brandGreen : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: OutlinedButton(
                          onPressed: () {
                            if (isOnline) {
                              ConnectivityService.instance.simulateOffline();
                            } else {
                              ConnectivityService.instance.simulateOnline();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isOnline ? Colors.redAccent : AppColors.brandGreen,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isOnline ? "Simulate Offline" : "Restore Online",
                            style: TextStyle(
                              color: isOnline ? Colors.redAccent : AppColors.brandGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: STORAGE matching Screen 36
            _buildSectionHeader("STORAGE"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListTile(
                leading: const Icon(Icons.cleaning_services_rounded,
                    color: AppColors.brandGold),
                title: const Text("Clear Cache"),
                subtitle: Text(
                  settings.cacheSizeMb > 0
                      ? "${settings.cacheSizeMb} MB • Free up storage space"
                      : "0 MB • Storage cache is clean",
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: ElevatedButton(
                  onPressed: settings.cacheSizeMb > 0
                      ? () => _showClearCacheDialog(context, ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGold,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Clear", style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: LEGAL matching Screen 36
            _buildSectionHeader("LEGAL"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildLegalTile(
                    title: "Privacy Policy",
                    onTap: () => _showLegalDoc(context, "Privacy Policy"),
                  ),
                  const Divider(height: 1, indent: 20),
                  _buildLegalTile(
                    title: "Terms of Service",
                    onTap: () => _showLegalDoc(context, "Terms of Service"),
                  ),
                  const Divider(height: 1, indent: 20),
                  _buildLegalTile(
                    title: "Licenses",
                    onTap: () => _showLegalDoc(context, "Open Source Licenses"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: SUPPORT matching Screen 36
            _buildSectionHeader("SUPPORT"),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.star_outline_rounded,
                        color: AppColors.brandGold),
                    title: const Text("Rate App"),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Thanks for rating 5 stars on Play Store!")),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.mail_outline_rounded,
                        color: AppColors.brandCyan),
                    title: const Text("Send Feedback"),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Opening feedback composer...")),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded,
                        color: AppColors.textSecondary),
                    title: const Text("About"),
                    subtitle: Text(
                      "Version 1.0.0 (Build 2026)",
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLegalTile({required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  void _showLanguageModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: 480,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
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
            const SizedBox(height: 18),
            Text("Select Language", style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: AppConstants.availableLanguages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final lang = AppConstants.availableLanguages[idx];
                  final code = lang.substring(0, 2).toUpperCase();
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: AppColors.canvasBackground,
                    title: Text(lang, style: const TextStyle(color: Colors.white)),
                    trailing: Text(code,
                        style: const TextStyle(
                            color: AppColors.brandPink,
                            fontWeight: FontWeight.w700)),
                    onTap: () {
                      ref.read(settingsProvider.notifier).setLanguage(code, lang);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear Temporary Cache?"),
        content: const Text(
          "This will delete 284 MB of cached video preview proxies and temporary sticker assets. Your saved draft projects will NOT be deleted.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(settingsProvider.notifier).clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cache cleared! 284 MB freed up successfully."),
                  backgroundColor: AppColors.brandGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGold,
            ),
            child: const Text("Clear Cache"),
          ),
        ],
      ),
    );
  }

  void _showLegalDoc(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: 520,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: Column(
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
            const SizedBox(height: 18),
            Text(title, style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "PhotoVideoCourse CapCut Replica terms, conditions, privacy protections and open source licenses.\n\n"
                  "1. User Media & Privacy: All video frames, audio tracks, and images are processed locally on your device. No user video files are uploaded to third-party ad networks.\n\n"
                  "2. AI Features: Features such as Auto-Caption generation, voice synthesis, and video upscaling use on-device accelerated models.\n\n"
                  "3. Open Source Licenses: Flutter framework, Riverpod state management, GoRouter, Google Fonts (Plus Jakarta Sans). Licensed under Apache 2.0 and BSD-3-Clause licenses.",
                  style: AppTypography.bodyMedium.copyWith(height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWeightedUrlDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    int weight = 30;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.brandCyan.withOpacity(0.4)),
            ),
            title: const Text(
              "Add Weighted URL",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Target URL:", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "https://example.com",
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.cardSurfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Weight (1 - 100):", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text("$weight", style: const TextStyle(color: AppColors.brandCyan, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Slider(
                  value: weight.toDouble(),
                  min: 5,
                  max: 100,
                  divisions: 19,
                  activeColor: AppColors.brandCyan,
                  onChanged: (val) {
                    setDialogState(() {
                      weight = val.round();
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final text = urlController.text.trim();
                  if (text.isNotEmpty && (text.startsWith("http://") || text.startsWith("https://"))) {
                    ref.read(adTabConfigProvider.notifier).addWeightedUrl(text, weight);
                    Navigator.pop(dialogCtx);
                  }
                },
                child: const Text("Add", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
