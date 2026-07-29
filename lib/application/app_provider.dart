import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/analytics_repository.dart';
import '../data/repositories/question_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'badge_engine.dart';
import 'content_manager.dart';
import 'daily_challenge_engine.dart';
import 'license_manager.dart';
import 'quiz_engine.dart';

class AppProvider extends ChangeNotifier {
  final LicenseManager _licenseManager = LicenseManager();
  final ContentManager _contentManager = ContentManager();
  final QuestionRepository _questionRepository = QuestionRepository();
  final AnalyticsRepository _analyticsRepository = AnalyticsRepository();
  final SettingsRepository _settingsRepository = SettingsRepository();
  final QuizEngine _quizEngine = QuizEngine();
  final BadgeEngine _badgeEngine = BadgeEngine();
  final DailyChallengeEngine _dailyChallengeEngine = DailyChallengeEngine();

  LicenseInfo? _licenseInfo;
  UserSettings? _settings;
  List<Question> _currentQuizQuestions = [];
  int _currentQuestionIndex = 0;
  List<AttemptAnswer> _currentAttemptAnswers = [];
  QuizAttempt? _lastCompletedAttempt;
  List<BadgeModel> _badges = [];
  double _overallScore = 0.0;
  int _testsDone = 0;
  int _studyStreak = 0;
  String _activeSubject = 'Science';

  Map<String, double> _subjectPerformance = {};
  List<ConceptDetail> _weakConceptsDetailed = [];
  List<ConceptDetail> _strongConceptsDetailed = [];
  List<QuizAttempt> _recentAttempts = [];

  QuestionRepository get questionRepository => _questionRepository;
  AnalyticsRepository get analyticsRepository => _analyticsRepository;

  LicenseInfo? get licenseInfo => _licenseInfo;
  UserSettings? get settings => _settings;
  List<Question> get currentQuizQuestions => _currentQuizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<AttemptAnswer> get currentAttemptAnswers => _currentAttemptAnswers;
  QuizAttempt? get lastCompletedAttempt => _lastCompletedAttempt;
  List<BadgeModel> get badges => _badges;
  double get overallScore => _overallScore;
  int get testsDone => _testsDone;
  int get studyStreak => _studyStreak;
  String get activeSubject => _activeSubject;

  Map<String, double> get subjectPerformance => _subjectPerformance;
  List<ConceptDetail> get weakConceptsDetailed => _weakConceptsDetailed;
  List<ConceptDetail> get strongConceptsDetailed => _strongConceptsDetailed;
  List<QuizAttempt> get recentAttempts => _recentAttempts;

  Future<void> initializeApp() async {
    await _contentManager.seedDefaultQuestionsIfEmpty();
    _licenseInfo = await _licenseManager.initLicense();
    _settings = await _settingsRepository.getSettings();
    await refreshAnalytics();
    notifyListeners();
  }

  Future<void> refreshAnalytics() async {
    final grade = _settings?.selectedGrade ?? 7;
    _overallScore = await _analyticsRepository.getOverallAverageScore();
    _testsDone = await _analyticsRepository.getTotalTestsCount();
    _studyStreak = await _analyticsRepository.getStudyStreakDays();
    _badges = await _badgeEngine.evaluateAndGetBadges();
    _subjectPerformance = await _analyticsRepository.getSubjectPerformance(grade);
    _weakConceptsDetailed = await _analyticsRepository.getWeakConceptsDetailed(grade: grade);
    _strongConceptsDetailed = await _analyticsRepository.getStrongConceptsDetailed(grade: grade);
    _recentAttempts = await _analyticsRepository.getRecentAttempts(limit: 10);
    notifyListeners();
  }

  Future<bool> activateLicense(String code) async {
    final success = await _licenseManager.activateDevice(code);
    if (success) {
      _licenseInfo = await _licenseManager.initLicense();
      notifyListeners();
    }
    return success;
  }

  Future<void> setGrade(int grade) async {
    await _settingsRepository.updateGrade(grade);
    _settings = await _settingsRepository.getSettings();
    await refreshAnalytics();
    notifyListeners();
  }

  Future<void> setIndigenousLanguage(String language) async {
    await _settingsRepository.updateIndigenousLanguage(language);
    _settings = await _settingsRepository.getSettings();
    notifyListeners();
  }

  void setActiveSubject(String subject) {
    _activeSubject = subject;
    notifyListeners();
  }

  Future<void> startQuiz({
    required TestType testType,
    String? subject,
    String? topic,
  }) async {
    final int grade = _settings?.selectedGrade ?? 7;
    final String indigenousLang = _settings?.selectedIndigenousLang ?? 'Shona';
    _activeSubject = subject ?? _activeSubject;

    if (testType == TestType.dailyChallenge) {
      _currentQuizQuestions = await _dailyChallengeEngine.generateDailyChallenge(
        grade: grade,
        currentSubject: _activeSubject,
        indigenousLanguage: indigenousLang,
      );
    } else {
      _currentQuizQuestions = await _quizEngine.generateQuiz(
        grade: grade,
        testType: testType,
        subject: subject,
        topic: topic,
        indigenousLanguage: indigenousLang,
      );
    }

    _currentQuestionIndex = 0;
    _currentAttemptAnswers = [];
    _lastCompletedAttempt = null;
    notifyListeners();
  }

  void answerCurrentQuestion(String selectedOptionId, bool isCorrect) {
    if (_currentQuestionIndex < _currentQuizQuestions.length) {
      final question = _currentQuizQuestions[_currentQuestionIndex];
      _currentAttemptAnswers.add(AttemptAnswer(
        attemptId: '', // Set when attempt is saved
        questionId: question.id,
        selectedOptionId: selectedOptionId,
        isCorrect: isCorrect,
      ));
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _currentQuizQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  Future<QuizAttempt> finishQuiz(TestType testType, String subject, String topic) async {
    final int grade = _settings?.selectedGrade ?? 7;
    final String attemptId = 'attempt_${DateTime.now().millisecondsSinceEpoch}';
    final int correctCount = _currentAttemptAnswers.where((a) => a.isCorrect).length;

    final attempt = QuizAttempt(
      id: attemptId,
      testType: testType == TestType.practice
          ? 'Practice'
          : testType == TestType.revision
              ? 'Revision'
              : 'Daily Challenge',
      grade: grade,
      subject: subject,
      topic: topic,
      totalQuestions: _currentQuizQuestions.length,
      correctCount: correctCount,
      timestamp: DateTime.now(),
    );

    final updatedAnswers = _currentAttemptAnswers.map((a) {
      return AttemptAnswer(
        attemptId: attemptId,
        questionId: a.questionId,
        selectedOptionId: a.selectedOptionId,
        isCorrect: a.isCorrect,
      );
    }).toList();

    await _analyticsRepository.saveQuizAttempt(attempt: attempt, answers: updatedAnswers);
    _lastCompletedAttempt = attempt;
    await refreshAnalytics();
    notifyListeners();
    return attempt;
  }
}
