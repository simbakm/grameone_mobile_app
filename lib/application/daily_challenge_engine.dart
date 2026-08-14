import 'dart:math';
import '../data/models/models.dart';
import '../data/repositories/analytics_repository.dart';
import '../data/repositories/question_repository.dart';

class DailyChallengeEngine {
  final QuestionRepository questionRepository;
  final AnalyticsRepository analyticsRepository;
  final Random _random = Random();

  DailyChallengeEngine({
    QuestionRepository? questionRepository,
    AnalyticsRepository? analyticsRepository,
  })  : questionRepository = questionRepository ?? QuestionRepository(),
        analyticsRepository = analyticsRepository ?? AnalyticsRepository();

  Future<List<Question>> generateDailyChallenge({
    required int grade,
    required String currentSubject,
    String? indigenousLanguage,
  }) async {
    final List<Question> allQuestions = await questionRepository.getQuestions(
      grade: grade,
      indigenousLanguage: indigenousLanguage,
    );
    if (allQuestions.isEmpty) return [];

    final List<String> weakConcepts = await analyticsRepository.getWeakConcepts(grade: grade, limit: 5);

    List<Question> weakQuestions = [];
    List<Question> subjectQuestions = [];
    List<Question> randomQuestions = List.from(allQuestions);

    for (var q in allQuestions) {
      if (weakConcepts.contains(q.concept)) {
        weakQuestions.add(q);
      }
      if (q.subject.toLowerCase() == currentSubject.toLowerCase()) {
        subjectQuestions.add(q);
      }
    }

    weakQuestions.shuffle(_random);
    subjectQuestions.shuffle(_random);
    randomQuestions.shuffle(_random);

    List<Question> result = [];
    Set<String> addedIds = {};

    // 1. Add weak concepts (up to 9 questions)
    for (var q in weakQuestions) {
      if (result.length >= 9) break;
      if (addedIds.add(q.id)) {
        result.add(q);
      }
    }

    // 2. Add current subject (up to 4 questions)
    for (var q in subjectQuestions) {
      if (result.length >= 13) break;
      if (addedIds.add(q.id)) {
        result.add(q);
      }
    }

    // 3. Fill remaining random revision to make 15 total questions
    for (var q in randomQuestions) {
      if (result.length >= 15) break;
      if (addedIds.add(q.id)) {
        result.add(q);
      }
    }

    // Shuffle options for all final questions
    return result.map((q) {
      List<QuestionOption> shuffled = List.from(q.options);
      shuffled.shuffle(_random);
      return q.copyWith(options: shuffled);
    }).toList();
  }
}
