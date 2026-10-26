import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/route_names.dart';
import '../../providers/user_provider.dart';
import '../../models/quiz_question_model.dart';
import '../../widgets/glowing_action_button.dart';
import '../../core/theme/responsive_orientation_manager.dart';

class QuizRewardScreen extends ConsumerStatefulWidget {
  const QuizRewardScreen({super.key});

  @override
  ConsumerState<QuizRewardScreen> createState() => _QuizRewardScreenState();
}

class _QuizRewardScreenState extends ConsumerState<QuizRewardScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool _isRewardClaimed = false;

  final List<QuizQuestionModel> _questions = const [
    QuizQuestionModel(
      id: "q1",
      questionNumberText: "1/2",
      question: "Andy Murray is related to which sport?",
      options: ["FOOTBALL", "TENNIS", "CRICKET"],
      correctIndex: 1, // TENNIS
      rewardCoins: 150,
    ),
    QuizQuestionModel(
      id: "q2",
      questionNumberText: "2/2",
      question: "Who among these is a pop singer?",
      options: ["ARIANA GRANDE", "JON HENDRICKS", "DEAN MARTIN"],
      correctIndex: 0, // ARIANA GRANDE
      rewardCoins: 150,
    ),
  ];

  void _onOptionSelected(int index) {
    if (_isAnswered) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
    });
  }

  void _onNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
      });
    } else {
      // Award coins and mark claimed
      ref.read(userProvider.notifier).addCoins(300);
      setState(() {
        _isRewardClaimed = true;
      });
    }
  }

  void _onEnterStudio() {
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveOrientationHelper.enforce(context);
    final currentQ = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient celebratory background glow
            Positioned(
              top: 40,
              right: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandGold.withOpacity(0.08),
                ),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Skip / Close Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.brandGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.brandGold.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: AppColors.brandGold, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "300 Coins",
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.brandGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _onEnterStudio,
                        child: Text(
                          "Skip to Studio",
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (!_isRewardClaimed) ...[
                    // Challenge Header matching Screen 04
                    Text(
                      "Let's get started,",
                      style: AppTypography.displayLarge.copyWith(
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.bodyLarge,
                        children: [
                          const TextSpan(
                              text: "answer 2 simple questions to get "),
                          TextSpan(
                            text: "300 coins",
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.brandGold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: " now:"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Question Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${currentQ.questionNumberText} - ${currentQ.question}",
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 18,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Multiple choice options
                          ...List.generate(currentQ.options.length, (idx) {
                            final option = currentQ.options[idx];
                            final isSelected = _selectedOptionIndex == idx;
                            final isCorrect = idx == currentQ.correctIndex;

                            Color tileBorder = AppColors.cardBorder;
                            Color tileBg = AppColors.canvasBackground;
                            Color textColor = AppColors.textPrimary;

                            if (_isAnswered) {
                              if (isCorrect) {
                                tileBorder = AppColors.brandGreen;
                                tileBg = AppColors.brandGreen.withOpacity(0.12);
                                textColor = Colors.white;
                              } else if (isSelected) {
                                tileBorder = Colors.redAccent;
                                tileBg = Colors.redAccent.withOpacity(0.12);
                              }
                            } else if (isSelected) {
                              tileBorder = AppColors.brandPink;
                              tileBg = AppColors.brandPink.withOpacity(0.15);
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _onOptionSelected(idx),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: tileBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: tileBorder, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        option,
                                        style:
                                            AppTypography.labelLarge.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (_isAnswered && isCorrect)
                                        const Icon(Icons.check_circle_rounded,
                                            color: AppColors.brandGreen, size: 20)
                                      else if (_isAnswered &&
                                          isSelected &&
                                          !isCorrect)
                                        const Icon(Icons.cancel_rounded,
                                            color: Colors.redAccent, size: 20)
                                      else
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked_rounded
                                              : Icons
                                                  .radio_button_unchecked_rounded,
                                          color: isSelected
                                              ? AppColors.brandPink
                                              : AppColors.textMuted,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Next / Claim action
                    if (_isAnswered)
                      GlowingActionButton(
                        label: _currentQuestionIndex == 0
                            ? "Next Question"
                            : "Claim 300 Coins & Continue",
                        color: AppColors.brandGold,
                        onTap: _onNextQuestion,
                      ),
                  ] else ...[
                    // Celebratory Reward Claimed Card
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 36),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.brandGold.withOpacity(0.2),
                              border: Border.all(
                                  color: AppColors.brandGold, width: 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.stars_rounded,
                                size: 58,
                                color: AppColors.brandGold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "+300 Coins Unlocked!",
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.brandGold,
                              fontSize: 28,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "You earned starter coins to generate AI subtitles and export in 4K resolution.",
                            style: AppTypography.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 36),
                          GlowingActionButton(
                            label: "Enter Studio Hub",
                            onTap: _onEnterStudio,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),

                  // Bottom info banner matching screen 04 footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Test your knowledge instantly!",
                              style: AppTypography.labelLarge.copyWith(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Play quizzes in over 25 categories like GK, sports, bollywood, photography & video creation.",
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
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
}
