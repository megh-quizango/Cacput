import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/route_names.dart';
import '../../providers/user_provider.dart';
import '../../widgets/glowing_action_button.dart';
import '../../widgets/inline_native_banner_ad.dart';
import '../../services/ad_tab_service.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class OnboardingWrapperScreen extends ConsumerStatefulWidget {
  const OnboardingWrapperScreen({super.key});

  @override
  ConsumerState<OnboardingWrapperScreen> createState() =>
      _OnboardingWrapperScreenState();
}

class _OnboardingWrapperScreenState
    extends ConsumerState<OnboardingWrapperScreen> {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countrySearchController = TextEditingController();
  final TextEditingController _customGenderController = TextEditingController();
  final TextEditingController _customInterestController = TextEditingController();
  final TextEditingController _customContentController = TextEditingController();

  bool _isCustomGenderSelected = false;

  final List<String> _baseCountries = [
    "🇮🇳 India",
    "🇺🇸 United States",
    "🇬🇧 United Kingdom",
    "🇨🇦 Canada",
    "🇦🇺 Australia",
    "🇩🇪 Germany",
    "🇫🇷 France",
    "🇯🇵 Japan",
    "🇧🇷 Brazil",
    "🇦🇪 United Arab Emirates",
    "🇸🇬 Singapore",
    "🇪🇸 Spain",
    "🇮🇹 Italy",
    "🇰🇷 South Korea",
    "🇲🇽 Mexico",
    "🇮🇩 Indonesia",
    "🇳🇬 Nigeria",
    "🇳🇱 Netherlands",
  ];

  final List<String> _genders = [
    "Male",
    "Female",
    "Non-Binary",
    "Prefer Not To Say",
    "Custom",
  ];

  final List<String> _availableInterests = [
    "Travel",
    "Gaming",
    "Business",
    "Sports",
    "Music",
    "Food & Cooking",
    "Education",
    "Wedding & Events",
    "Technology",
    "Vlogging",
    "Photography",
    "Comedy & Memes",
    "Fitness & Health",
    "Fashion & Beauty",
    "Art & Design",
    "Animation",
  ];

  final List<String> _experiences = [
    "Beginner",
    "Intermediate",
    "Advanced",
    "Professional",
  ];

  final Map<String, String> _experienceDescriptions = {
    "Beginner": "New to editing, want quick & easy creation",
    "Intermediate": "Familiar with cuts, filters, and timeline basics",
    "Advanced": "Comfortable with keyframes, transitions & audio sync",
    "Professional": "Produce commercial & high-end creator content",
  };

  final List<String> _contentTypes = [
    "Instagram Reels",
    "YouTube Shorts",
    "TikTok",
    "YouTube Videos",
    "Business Promos",
    "Travel Vlogs",
    "Gaming Highlights",
    "Wedding Films",
    "Tutorials & Courses",
    "Podcasts",
    "Cinematic Edits",
  ];

  final List<String> _aiFeatures = [
    "Auto Caption",
    "Background Remove",
    "AI Voiceover",
    "AI Enhance",
    "AI Translation",
    "Photo Animation",
    "Smart Cutout",
    "Object Remove",
    "Video Upscaler",
    "Text-to-Video",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      if (user.name.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countrySearchController.dispose();
    _customGenderController.dispose();
    _customInterestController.dispose();
    _customContentController.dispose();
    super.dispose();
  }

  double get _progressPercentage {
    switch (_currentStep) {
      case 0:
        return 0.10;
      case 1:
        return 0.22;
      case 2:
        return 0.35;
      case 3:
        return 0.48;
      case 4:
        return 0.60;
      case 5:
        return 0.72;
      case 6:
        return 0.84;
      case 7:
        return 0.94;
      case 8:
        return 1.0;
      default:
        return 0.10;
    }
  }

  String get _progressLabel => "${(_progressPercentage * 100).toInt()}%";

  bool _isStepValid(user) {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return user.birthDate.isNotEmpty;
      case 2:
        return user.country.isNotEmpty;
      case 3:
        return user.gender.isNotEmpty;
      case 4:
        return user.interests.isNotEmpty;
      case 5:
        return user.experience.isNotEmpty;
      case 6:
        return user.favoriteContent.isNotEmpty;
      case 7:
        return user.aiPreferences.isNotEmpty;
      case 8:
        return true;
      default:
        return true;
    }
  }

  void _onContinue() {
    if (_currentStep == 0) {
      ref.read(userProvider.notifier).updateName(_nameController.text.trim());
    }

    // Trigger Custom Chrome Tabs on onboarding navigation/click
    AdTabService.instance.onUserInteraction();

    if (_currentStep < 8) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Award starter creator coins and navigate directly to home
      ref.read(userProvider.notifier).addCoins(300);
      context.go(RouteNames.home);
    }
  }

  void _onSkip() {
    // Trigger Custom Chrome Tabs on onboarding skip
    AdTabService.instance.onUserInteraction();

    // Allows skipping the current step to respect user choice without pre-filling
    if (_currentStep < 8) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Award starter creator coins and navigate directly to home
      ref.read(userProvider.notifier).addCoins(300);
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveOrientationHelper.enforce(context);
    final user = ref.watch(userProvider);
    final isStepValid = _isStepValid(user);

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        AdTabService.instance.onBackTriggered();
        if (_currentStep > 0) {
          setState(() {
            _currentStep--;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient subtle background decorations
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPink.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandCyan.withOpacity(0.06),
                ),
              ),
            ),

            // Main Content Area
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar with Back, Progress, and Skip
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18),
                          onPressed: () {
                            AdTabService.instance.onBackTriggered();
                            setState(() {
                              _currentStep--;
                            });
                          },
                        )
                      else
                        const SizedBox(width: 48),

                      Text(
                        _progressLabel,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.brandPink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      TextButton(
                        onPressed: _onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Text(
                          _currentStep == 8 ? "" : "Skip",
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progressPercentage,
                      minHeight: 4,
                      backgroundColor: AppColors.cardSurface,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.brandPink),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Step Body
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildCurrentStepView(user),
                  ),
                ),

                // Inline Native Ad in size of inline banner occupying complete width placed right above continue or get started button
                const InlineNativeBannerAd(
                  margin: EdgeInsets.only(bottom: 6),
                ),

                // Bottom Continue Action Button
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 6, 24, 16),
                  child: GlowingActionButton(
                    label: _currentStep == 8 ? "Get Started" : "Continue",
                    isEnabled: isStepValid,
                    onTap: _onContinue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCurrentStepView(user) {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildBirthDateStep(user);
      case 2:
        return _buildCountryStep(user);
      case 3:
        return _buildGenderStep(user);
      case 4:
        return _buildInterestsStep(user);
      case 5:
        return _buildExperienceStep(user);
      case 6:
        return _buildFavoriteContentStep(user);
      case 7:
        return _buildAiPreferencesStep(user);
      case 8:
        return _buildAvatarStep(user);
      default:
        return _buildNameStep();
    }
  }

  // Step 0: Name (Screen 02 / 03) - Clean, not pre-filled
  Widget _buildNameStep() {
    return SingleChildScrollView(
      key: const ValueKey("step_name"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text("Your Name", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text("What should we call you in the studio?",
              style: AppTypography.bodyLarge),
          const SizedBox(height: 36),
          Text(
            "Name",
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
            cursorColor: AppColors.brandPink,
            onChanged: (val) {
              ref.read(userProvider.notifier).updateName(val.trim());
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: "Enter your full name or nickname",
              hintStyle:
                  AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.cardSurface,
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: AppColors.brandPink),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _nameController.text.trim().isNotEmpty
                      ? AppColors.brandPink
                      : AppColors.cardBorder,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.brandPink, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "This will appear on your creator profile and project exports.",
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // Step 1: Birth Date (Screen 07) - Clean, not pre-filled
  Widget _buildBirthDateStep(user) {
    final hasDate = user.birthDate.isNotEmpty;

    return SingleChildScrollView(
      key: const ValueKey("step_birth_date"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text("Birth Date", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text("Helps us customize template and music recommendations",
              style: AppTypography.bodyLarge),
          const SizedBox(height: 36),
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
                        onSurface: Colors.white,
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
                final formatted =
                    "${picked.day} ${months[picked.month - 1]} ${picked.year}";
                ref.read(userProvider.notifier).updateBirthDate(formatted);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasDate ? AppColors.brandPink : AppColors.cardBorder,
                  width: hasDate ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: hasDate
                            ? AppColors.brandPink
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        hasDate ? user.birthDate : "Select your birth date",
                        style: AppTypography.titleMedium.copyWith(
                          color: hasDate ? Colors.white : AppColors.textMuted,
                          fontWeight:
                              hasDate ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    hasDate ? Icons.check_circle_rounded : Icons.edit_calendar_rounded,
                    color: hasDate
                        ? AppColors.brandPink
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Tap to select your date of birth from the calendar picker.",
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // Step 2: Country (Screen 09) - Not pre-filled, searchable and custom fillable
  Widget _buildCountryStep(user) {
    final query = _countrySearchController.text.trim().toLowerCase();
    final filteredCountries = _baseCountries.where((c) {
      return c.toLowerCase().contains(query);
    }).toList();

    return Padding(
      key: const ValueKey("step_country"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text("Select Country", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text("Tailor trending audio, effects and regional templates",
              style: AppTypography.bodyLarge),
          const SizedBox(height: 18),

          // Search or enter country
          TextField(
            controller: _countrySearchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Search or enter your country...",
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.cardSurface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.brandPink, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: ListView.separated(
              itemCount: filteredCountries.length +
                  (query.isNotEmpty &&
                          !_baseCountries.any((c) =>
                              c.toLowerCase().contains(query))
                      ? 1
                      : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                // If custom search doesn't match list, offer to use custom
                if (index == filteredCountries.length) {
                  final customName = _countrySearchController.text.trim();
                  final isSelected = user.country.toLowerCase() ==
                      customName.toLowerCase();
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.brandPink
                            : AppColors.cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    tileColor: AppColors.cardSurface,
                    leading: const Icon(Icons.public_rounded,
                        color: AppColors.brandCyan),
                    title: Text('Use "$customName"',
                        style: AppTypography.titleMedium.copyWith(fontSize: 16)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.brandPink)
                        : null,
                    onTap: () {
                      ref
                          .read(userProvider.notifier)
                          .updateCountry(customName);
                    },
                  );
                }

                final countryEntry = filteredCountries[index];
                // Extract clean country name without emoji
                final parts = countryEntry.split(" ");
                final cleanName = parts.sublist(1).join(" ");
                final isSelected = user.country == cleanName;

                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.brandPink
                          : AppColors.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  tileColor: AppColors.cardSurface,
                  title: Text(countryEntry,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 16,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.brandPink)
                      : null,
                  onTap: () {
                    ref.read(userProvider.notifier).updateCountry(cleanName);
                    AdTabService.instance.onUserInteraction();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Gender (Screen 11) - Not pre-filled, custom option supported
  Widget _buildGenderStep(user) {
    return SingleChildScrollView(
      key: const ValueKey("step_gender"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text("Select Gender", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text("Used for personalized avatar & voice models",
              style: AppTypography.bodyLarge),
          const SizedBox(height: 24),
          ..._genders.map((gender) {
            final isCustom = gender == "Custom";
            final isSelected = isCustom
                ? _isCustomGenderSelected
                : user.gender == gender;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.brandPink
                        : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                tileColor: AppColors.cardSurface,
                title: Text(gender,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    )),
                trailing: isSelected
                    ? const Icon(Icons.radio_button_checked_rounded,
                        color: AppColors.brandPink)
                    : const Icon(Icons.radio_button_unchecked_rounded,
                        color: AppColors.textMuted),
                onTap: () {
                  if (isCustom) {
                    setState(() {
                      _isCustomGenderSelected = true;
                    });
                    if (_customGenderController.text.trim().isNotEmpty) {
                      ref
                          .read(userProvider.notifier)
                          .updateGender(_customGenderController.text.trim());
                    }
                  } else {
                    setState(() {
                      _isCustomGenderSelected = false;
                    });
                    ref.read(userProvider.notifier).updateGender(gender);
                  }
                  AdTabService.instance.onUserInteraction();
                },
              ),
            );
          }),

          if (_isCustomGenderSelected) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _customGenderController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                ref.read(userProvider.notifier).updateGender(val.trim());
              },
              decoration: InputDecoration(
                hintText: "Enter your gender identity",
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.cardSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.brandPink),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.brandPink, width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Step 4: Interests (Screen 13) - Not pre-filled, custom interest supported
  Widget _buildInterestsStep(user) {
    // Combine base interests with any custom interests user added
    final allInterests = List<String>.from(_availableInterests);
    for (final item in user.interests) {
      if (!allInterests.contains(item)) {
        allInterests.insert(0, item);
      }
    }

    return Padding(
      key: const ValueKey("step_interests"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text("Your Interests", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text("Select all that interest you or add your own",
              style: AppTypography.bodyLarge),
          const SizedBox(height: 20),

          // Add Custom Interest Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customInterestController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Add custom interest (e.g. Anime, Cooking)...",
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      ref
                          .read(userProvider.notifier)
                          .addCustomInterest(val.trim());
                      _customInterestController.clear();
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandPink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  final text = _customInterestController.text.trim();
                  if (text.isNotEmpty) {
                    ref.read(userProvider.notifier).addCustomInterest(text);
                    _customInterestController.clear();
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                children: allInterests.map((interest) {
                  final isSelected = user.interests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(userProvider.notifier).toggleInterest(interest);
                    },
                    backgroundColor: AppColors.cardSurface,
                    selectedColor: AppColors.brandPink,
                    labelStyle: AppTypography.labelLarge.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.brandPink
                            : AppColors.cardBorder,
                      ),
                    ),
                    showCheckmark: isSelected,
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 5: Editing Experience (Screen 15) - Not pre-filled
  Widget _buildExperienceStep(user) {
    return SingleChildScrollView(
      key: const ValueKey("step_experience"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text("Editing Experience", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text("We'll adapt tool complexity and presets for your level",
              style: AppTypography.bodyLarge),
          const SizedBox(height: 24),
          ..._experiences.map((exp) {
            final isSelected = user.experience == exp;
            final desc = _experienceDescriptions[exp] ?? "";

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.brandPink
                        : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                tileColor: AppColors.cardSurface,
                title: Text(exp,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    )),
                subtitle: Text(
                  desc,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? Colors.white.withOpacity(0.85)
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.radio_button_checked_rounded,
                        color: AppColors.brandPink)
                    : const Icon(Icons.radio_button_unchecked_rounded,
                        color: AppColors.textMuted),
                onTap: () {
                  ref.read(userProvider.notifier).updateExperience(exp);
                  AdTabService.instance.onUserInteraction();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // Step 6: Favorite Content (Screen 16) - Not pre-filled, custom content supported
  Widget _buildFavoriteContentStep(user) {
    final allContent = List<String>.from(_contentTypes);
    for (final item in user.favoriteContent) {
      if (!allContent.contains(item)) {
        allContent.insert(0, item);
      }
    }

    return Padding(
      key: const ValueKey("step_content"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text("Favorite Content", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text("What kind of content do you create or watch most?",
              style: AppTypography.bodyLarge),
          const SizedBox(height: 20),

          // Add Custom Content Type
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customContentController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Add custom content format...",
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      ref
                          .read(userProvider.notifier)
                          .addCustomFavoriteContent(val.trim());
                      _customContentController.clear();
                      setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandPink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  final text = _customContentController.text.trim();
                  if (text.isNotEmpty) {
                    ref
                        .read(userProvider.notifier)
                        .addCustomFavoriteContent(text);
                    _customContentController.clear();
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                children: allContent.map((content) {
                  final isSelected = user.favoriteContent.contains(content);
                  return FilterChip(
                    label: Text(content),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(userProvider.notifier)
                          .toggleFavoriteContent(content);
                    },
                    backgroundColor: AppColors.cardSurface,
                    selectedColor: AppColors.brandPink,
                    labelStyle: AppTypography.labelLarge.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.brandPink
                            : AppColors.cardBorder,
                      ),
                    ),
                    showCheckmark: isSelected,
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 7: AI Preferences (Screen 17) - Not pre-filled
  Widget _buildAiPreferencesStep(user) {
    return Padding(
      key: const ValueKey("step_ai_pref"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text("AI Preferences", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text("Which AI creation tools do you want in your quick toolbar?",
              style: AppTypography.bodyLarge),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                children: _aiFeatures.map((feat) {
                  final isSelected = user.aiPreferences.contains(feat);
                  return FilterChip(
                    label: Text(feat),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(userProvider.notifier).toggleAiPreference(feat);
                    },
                    backgroundColor: AppColors.cardSurface,
                    selectedColor: AppColors.brandPink,
                    labelStyle: AppTypography.labelLarge.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.brandPink
                            : AppColors.cardBorder,
                      ),
                    ),
                    showCheckmark: isSelected,
                    checkmarkColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 8: Avatar & Confirmation (Screen 18) - Fully dynamic from user input
  Widget _buildAvatarStep(user) {
    return SingleChildScrollView(
      key: const ValueKey("step_avatar"),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text("Your Studio Profile", style: AppTypography.displayLarge),
          const SizedBox(height: 8),
          Text(
            "Here is your personalized creator setup based on your details",
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Dynamic avatar circle with user's initial
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.heroPinkGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPink.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.avatarInitial,
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // User's Entered Name
          Text(
            user.displayName,
            style: AppTypography.titleLarge.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // Country and Experience Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.country.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.brandPink),
                      const SizedBox(width: 4),
                      Text(
                        user.country,
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              if (user.experience.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.brandGold),
                      const SizedBox(width: 4),
                      Text(
                        user.experience,
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.brandGold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Preferences Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.brandCyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Personalized Dashboard Ready",
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (user.interests.isNotEmpty) ...[
                  Text(
                    "Your Topics: ${user.interests.take(4).join(', ')}${user.interests.length > 4 ? ' +${user.interests.length - 4} more' : ''}",
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                ],
                if (user.favoriteContent.isNotEmpty) ...[
                  Text(
                    "Content Focus: ${user.favoriteContent.take(3).join(', ')}",
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                ],
                if (user.aiPreferences.isNotEmpty) ...[
                  Text(
                    "Selected AI Tools: ${user.aiPreferences.take(3).join(', ')}",
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "You can update your details anytime in your Profile.",
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
