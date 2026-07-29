import 'dart:math';
import '../data/models/models.dart';
import '../data/repositories/question_repository.dart';

enum TestType { practice, revision, dailyChallenge }

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
    String? indigenousLanguage,
  }) async {
    List<Question> allQuestions = await questionRepository.getQuestions(
      grade: grade,
      subject: subject,
      topic: topic,
      indigenousLanguage: indigenousLanguage,
    );

    if (allQuestions.isEmpty) {
      return [];
    }

    int targetCount = 15;
    if (testType == TestType.revision) {
      targetCount = 40;
    } else if (testType == TestType.dailyChallenge) {
      targetCount = 5;
    }

    // Shuffle questions
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
