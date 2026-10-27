import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/route_names.dart';
import '../../providers/user_provider.dart';
import '../../providers/project_provider.dart';
import '../../models/user_profile.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ResponsiveOrientationHelper.enforce(context);
    final user = ref.watch(userProvider);
    final projects = ref.watch(projectProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Hero Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  gradient: AppColors.heroPinkGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPink.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar circle with dynamic user initial
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.22),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.6), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.avatarInitial,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Display Name (Dynamic from onboarding input)
                    Text(
                      user.displayName,
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Location & Creator Badges
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                user.country.isNotEmpty
                                    ? user.country
                                    : "Global Creator",
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (user.experience.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 13, color: AppColors.brandGold),
                                const SizedBox(width: 4),
                                Text(
                                  user.experience,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Edit Profile Action Button
                    OutlinedButton.icon(
                      onPressed: () => _showEditProfileModal(context, ref, user),
                      icon: const Icon(Icons.edit_rounded,
                          size: 15, color: Colors.white),
                      label: Text(
                        "Edit Profile Details",
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Stat Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.folder_rounded,
                      iconColor: AppColors.brandPink,
                      count: "${projects.length}",
                      label: "Projects",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.file_download_rounded,
                      iconColor: AppColors.brandCyan,
                      count: "${user.exportsCount}",
                      label: "Exports",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.monetization_on_rounded,
                      iconColor: AppColors.brandGold,
                      count: "${user.coins}",
                      label: "Coins",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatTile(
                      icon: Icons.storage_rounded,
                      iconColor: AppColors.brandGreen,
                      count: "${user.storageUsedMb} MB",
                      label: "Storage",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Onboarding Details: Personal Information Card
              _buildSectionHeader("PERSONAL DETAILS", onEdit: () {
                _showEditProfileModal(context, ref, user);
              }),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.person_rounded,
                      iconColor: AppColors.brandPink,
                      label: "Full Name",
                      value: user.name.isNotEmpty
                          ? user.name
                          : "Not provided",
                      isMuted: user.name.isEmpty,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildDetailRow(
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppColors.brandCyan,
                      label: "Birth Date",
                      value: user.birthDate.isNotEmpty
                          ? user.birthDate
                          : "Not specified",
                      isMuted: user.birthDate.isEmpty,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildDetailRow(
                      icon: Icons.flag_rounded,
                      iconColor: AppColors.brandGold,
                      label: "Country",
                      value: user.country.isNotEmpty
                          ? user.country
                          : "Not specified",
                      isMuted: user.country.isEmpty,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildDetailRow(
                      icon: Icons.wc_rounded,
                      iconColor: AppColors.brandPurple,
                      label: "Gender",
                      value: user.gender.isNotEmpty
                          ? user.gender
                          : "Not specified",
                      isMuted: user.gender.isEmpty,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildDetailRow(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.brandGreen,
                      label: "Editing Experience",
                      value: user.experience.isNotEmpty
                          ? user.experience
                          : "Not selected",
                      isMuted: user.experience.isEmpty,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Onboarding Details: Interests & Niches
              _buildSectionHeader("INTERESTS & TOPICS", onEdit: () {
                _showEditProfileModal(context, ref, user);
              }),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: user.interests.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.interests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.brandPink.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.brandPink.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tag_rounded,
                                    size: 13, color: AppColors.brandPink),
                                const SizedBox(width: 4),
                                Text(
                                  interest,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "No interests chosen in onboarding",
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                          TextButton(
                            onPressed: () =>
                                _showEditProfileModal(context, ref, user),
                            child: const Text("Add Interests"),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // 5. Onboarding Details: Content Focus & AI Tools
              _buildSectionHeader("CREATIVE PREFERENCES", onEdit: () {
                _showEditProfileModal(context, ref, user);
              }),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Favorite Content Formats",
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (user.favoriteContent.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.favoriteContent.map((content) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.brandCyan.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.brandCyan.withOpacity(0.5)),
                            ),
                            child: Text(
                              content,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        "No content formats selected",
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      "Selected AI Creation Tools",
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (user.aiPreferences.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.aiPreferences.map((ai) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.brandGold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.brandGold.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded,
                                    size: 13, color: AppColors.brandGold),
                                const SizedBox(width: 4),
                                Text(
                                  ai,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        "No AI tools selected",
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 6. Settings & General Options
              _buildSectionHeader("APP SETTINGS & SUPPORT"),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      label: "Settings",
                      onTap: () => context.push(RouteNames.settings),
                    ),
                    const Divider(height: 1, indent: 64),
                    _buildMenuItem(
                      icon: Icons.history_rounded,
                      label: "Export History",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("All project export logs synced")),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    _buildMenuItem(
                      icon: Icons.feedback_outlined,
                      label: "Feedback",
                      onTap: () => _showFeedbackModal(context),
                    ),
                    const Divider(height: 1, indent: 64),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: "Help & Support",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "CapCut Help Center • 24/7 Creator Support")),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 64),
                    _buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      label: "About",
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: "PhotoVideoCourse",
                          applicationVersion: "Version 1.0.0",
                          applicationLegalese:
                              "© 2026 RVariety Studio. All rights reserved.",
                        );
                      },
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

  Widget _buildSectionHeader(String title, {VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: Row(
              children: [
                const Icon(Icons.edit_outlined,
                    size: 13, color: AppColors.brandPink),
                const SizedBox(width: 4),
                Text(
                  "Edit",
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.brandPink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMuted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: isMuted ? AppColors.textMuted : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            count,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.canvasBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showFeedbackModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Send Feedback", style: AppTypography.titleLarge),
                const SizedBox(height: 8),
                Text(
                  "Tell us how we can improve your editing workflow",
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Write your feedback or bug report here...",
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.canvasBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Thank you for your feedback!")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPink,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Submit Feedback"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Interactive Edit Profile Bottom Sheet
  void _showEditProfileModal(
      BuildContext context, WidgetRef ref, UserProfile user) {
    final nameCtrl = TextEditingController(text: user.name);
    final countryCtrl = TextEditingController(text: user.country);
    String selectedGender = user.gender;
    String selectedExp = user.experience;
    String birthDate = user.birthDate;

    final availableExperiences = [
      "Beginner",
      "Intermediate",
      "Advanced",
      "Professional"
    ];
    final availableGenders = [
      "Male",
      "Female",
      "Non-Binary",
      "Prefer Not To Say"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: AppColors.canvasBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Handle bar
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
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Edit Profile Details",
                          style: AppTypography.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      children: [
                        // Name Field
                        Text("Creator Name",
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter your name",
                            hintStyle:
                                const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.cardSurface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Country Field
                        Text("Country",
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: countryCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter country or region",
                            hintStyle:
                                const TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.cardSurface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.cardBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Birth Date Selector
                        Text("Birth Date",
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(2000, 1, 1),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.brandPink,
                                      surface: AppColors.cardSurface,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              final months = [
                                "Jan",
                                "Feb",
                                "Mar",
                                "Apr",
                                "May",
                                "Jun",
                                "Jul",
                                "Aug",
                                "Sep",
                                "Oct",
                                "Nov",
                                "Dec"
                              ];
                              setModalState(() {
                                birthDate =
                                    "${picked.day} ${months[picked.month - 1]} ${picked.year}";
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  birthDate.isNotEmpty
                                      ? birthDate
                                      : "Select birth date",
                                  style: TextStyle(
                                    color: birthDate.isNotEmpty
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const Icon(Icons.calendar_today_rounded,
                                    size: 18, color: AppColors.brandPink),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Experience Level Chips
                        Text("Editing Experience",
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableExperiences.map((exp) {
                            final isSelected = selectedExp == exp;
                            return ChoiceChip(
                              label: Text(exp),
                              selected: isSelected,
                              selectedColor: AppColors.brandPink,
                              backgroundColor: AppColors.cardSurface,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (_) {
                                setModalState(() {
                                  selectedExp = exp;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Gender Chips
                        Text("Gender",
                            style: AppTypography.labelMedium
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableGenders.map((g) {
                            final isSelected = selectedGender == g;
                            return ChoiceChip(
                              label: Text(g),
                              selected: isSelected,
                              selectedColor: AppColors.brandCyan,
                              backgroundColor: AppColors.cardSurface,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              onSelected: (_) {
                                setModalState(() {
                                  selectedGender = g;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(userProvider.notifier).updateProfile(
                              name: nameCtrl.text.trim(),
                              country: countryCtrl.text.trim(),
                              birthDate: birthDate,
                              gender: selectedGender,
                              experience: selectedExp,
                            );
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Profile details updated!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPink,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }
}
