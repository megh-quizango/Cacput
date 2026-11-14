import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../services/ad_tab_service.dart';
import '../../services/firebase_remote_config_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

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
                    onTap: () => _openLegalUrl(context, "Privacy Policy",
                        FirebaseRemoteConfigService.instance.getPrivacyPolicyUrl()),
                  ),
                  const Divider(height: 1, indent: 20),
                  _buildLegalTile(
                    title: "Terms of Service",
                    onTap: () => _openLegalUrl(context, "Terms of Service",
                        FirebaseRemoteConfigService.instance.getTermsOfServiceUrl()),
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

  /// Opens a legal page (URL from Firebase Remote Config) in a Chrome Custom Tab.
  Future<void> _openLegalUrl(BuildContext context, String title, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.scheme.startsWith('http')) {
      debugPrint("[Legal] $title URL missing or invalid in Remote Config: '$url'");
      messenger.showSnackBar(SnackBar(content: Text("$title is not available right now")));
      return;
    }
    debugPrint("[Legal] Opening $title: $url");
    final opened = await AdTabService.instance.openUrlInCustomTab(url);
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text("Could not open $title")));
    }
  }
}
