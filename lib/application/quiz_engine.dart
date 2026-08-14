import 'dart:math';
import '../data/models/models.dart';
import '../data/repositories/question_repository.dart';

enum TestType { practice, revision, topicRevision, dailyChallenge }

class QuizEngine {
  final QuestionRepository questionRepository;
  final Random _random = Random();

  QuizEngine({QuestionRepository? questionRepository})
      : questionRepository = questionRepository ?? QuestionRepository();

  Future<List<Question>> generateQuiz({
    required int grade,
    required TestType testType,
    String? subject,
    String? topic,
    String? unit,
    String? indigenousLanguage,
  }) async {
    List<Question> allQuestions = await questionRepository.getQuestions(
      grade: grade,
      subject: subject,
      topic: topic,
      // For topicRevision: fetch ALL units in the topic (no unit filter)
      unit: testType == TestType.topicRevision ? null : unit,
      indigenousLanguage: indigenousLanguage,
    );

    if (allQuestions.isEmpty) {
      return [];
    }

    int targetCount;
    switch (testType) {
      case TestType.revision:
        targetCount = 40; // Subject-level revision = 40 questions
        break;
      case TestType.topicRevision:
        targetCount = 40; // End-of-topic revision test = 40 questions
        break;
      case TestType.dailyChallenge:
        targetCount = 15;
        break;
      case TestType.practice:
        targetCount = 20; // Max 20 per unit practice session
        break;
    }

    // Shuffle questions every time for fresh randomized order
    allQuestions.shuffle(_random);
    List<Question> selected = allQuestions.take(targetCount).toList();

    // Randomize options for each question
    return selected.map((q) => _randomizeOptions(q)).toList();
  }

  Question _randomizeOptions(Question question) {
    List<QuestionOption> shuffledOptions = List.from(question.options);
    shuffledOptions.shuffle(_random);
    return question.copyWith(options: shuffledOptions);
  }
}
