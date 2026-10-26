class QuizQuestionModel {
  final String id;
  final String questionNumberText;
  final String question;
  final List<String> options;
  final int correctIndex;
  final int rewardCoins;

  const QuizQuestionModel({
    required this.id,
    required this.questionNumberText,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.rewardCoins = 150,
  });
}
