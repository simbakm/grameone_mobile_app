import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/analytics_repository.dart';
import '../data/repositories/learner_repository.dart';
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
  final LearnerRepository _learnerRepository = LearnerRepository();
  final QuizEngine _quizEngine = QuizEngine();
  final BadgeEngine _badgeEngine = BadgeEngine();
  final DailyChallengeEngine _dailyChallengeEngine = DailyChallengeEngine();

  LicenseInfo? _licenseInfo;
  UserSettings? _settings;
  List<LearnerProfile> _learnerProfiles = [];
  LearnerProfile? _activeLearner;

  List<Question> _currentQuizQuestions = [];
  int _currentQuestionIndex = 0;
  // Index -> Selected Option ID for deferred feedback & reselection
  final Map<int, String> _userSelectedOptionIds = {};

  int _totalUnitQuestionsAvailable = 0;
  String? _currentQuizTopic;
  String? _currentQuizUnit;
  TestType _currentTestType = TestType.practice;

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
  LearnerRepository get learnerRepository => _learnerRepository;

  LicenseInfo? get licenseInfo => _licenseInfo;
  UserSettings? get settings => _settings;
  List<LearnerProfile> get learnerProfiles => _learnerProfiles;
  LearnerProfile? get activeLearner => _activeLearner;

  List<Question> get currentQuizQuestions => _currentQuizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, String> get userSelectedOptionIds => _userSelectedOptionIds;
  int get totalUnitQuestionsAvailable => _totalUnitQuestionsAvailable;
  String? get currentQuizTopic => _currentQuizTopic;
  String? get currentQuizUnit => _currentQuizUnit;
  TestType get currentTestType => _currentTestType;
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

  // Active Grade helper (from profile or global setting)
  int get currentGrade => _activeLearner?.grade ?? _settings?.selectedGrade ?? 7;
  String get currentIndigenousLang => _activeLearner?.indigenousLanguage ?? _settings?.selectedIndigenousLang ?? 'Shona';
  bool get isGradeLocked => _settings?.isGradeLocked ?? false;

  int? _dismissedExpiryThresholdDay;
  int? get dismissedExpiryThresholdDay => _dismissedExpiryThresholdDay;

  void dismissExpiryThreshold(int day) {
    _dismissedExpiryThresholdDay = day;
    notifyListeners();
  }

  Future<void> initializeApp() async {
    await _contentManager.seedDefaultQuestionsIfEmpty();
    _licenseInfo = await _licenseManager.initLicense();
    _settings = await _settingsRepository.getSettings();

    // Auto-lock grade if question content is already present on device for current grade
    final questionCount = await _questionRepository.getQuestionCount(grade: currentGrade);
    if (questionCount > 0 && !isGradeLocked) {
      await lockGrade();
    }

    // Load learner profiles
    await refreshLearnerProfiles();

    await refreshAnalytics();
    notifyListeners();
  }

  Future<void> refreshLearnerProfiles() async {
    _learnerProfiles = await _learnerRepository.getLearnerProfiles();

    // Seed initial default profile if none exists
    if (_learnerProfiles.isEmpty) {
      final defaultProfile = LearnerProfile(
        id: 'learner_1',
        name: 'Learner A',
        avatar: '🧒',
        grade: _settings?.selectedGrade ?? 7,
        indigenousLanguage: _settings?.selectedIndigenousLang ?? 'Shona',
        createdAt: DateTime.now(),
      );
      await _learnerRepository.saveLearnerProfile(defaultProfile);
      await _learnerRepository.setActiveLearnerProfileId(defaultProfile.id);
      _learnerProfiles = [defaultProfile];
      _activeLearner = defaultProfile;
    } else {
      _activeLearner = await _learnerRepository.getActiveLearnerProfile();
      _activeLearner ??= _learnerProfiles.first;
    }
  }

  Future<void> switchLearnerProfile(LearnerProfile profile) async {
    _activeLearner = profile;
    await _learnerRepository.setActiveLearnerProfileId(profile.id);
    await setGrade(profile.grade);
    await setIndigenousLanguage(profile.indigenousLanguage);
    await refreshAnalytics();
    notifyListeners();
  }

  Future<void> createOrUpdateLearnerProfile(LearnerProfile profile) async {
    await _learnerRepository.saveLearnerProfile(profile);
    await refreshLearnerProfiles();
    if (_activeLearner?.id == profile.id || _learnerProfiles.length == 1) {
      await switchLearnerProfile(profile);
    }
    notifyListeners();
  }

  Future<void> refreshAnalytics() async {
    final grade = currentGrade;
    final learnerId = _activeLearner?.id;
    _overallScore = await _analyticsRepository.getOverallAverageScore(learnerProfileId: learnerId);
    _testsDone = await _analyticsRepository.getTotalTestsCount(learnerProfileId: learnerId);
    _studyStreak = await _analyticsRepository.getStudyStreakDays(learnerProfileId: learnerId);
    _badges = await _badgeEngine.evaluateAndGetBadges();
    _subjectPerformance = await _analyticsRepository.getSubjectPerformance(grade, learnerProfileId: learnerId);
    _weakConceptsDetailed = await _analyticsRepository.getWeakConceptsDetailed(grade: grade, learnerProfileId: learnerId);
    _strongConceptsDetailed = await _analyticsRepository.getStrongConceptsDetailed(grade: grade, learnerProfileId: learnerId);
    _recentAttempts = await _analyticsRepository.getRecentAttempts(limit: 5, learnerProfileId: learnerId);
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

  Future<void> activateLicenseFromApi({
    required String code,
    String? expiryDate,
    List<int>? gradeIds,
    String licenseType = 'STANDARD',
  }) async {
    final devId = await _licenseManager.getDeviceId();
    final now = DateTime.now();
    DateTime? expiry;
    if (expiryDate != null) {
      try { expiry = DateTime.parse(expiryDate); } catch (_) {}
    }
    expiry ??= now.add(const Duration(days: 365));

    final updatedLicense = LicenseInfo(
      deviceId: devId,
      activationCode: code,
      isActivated: true,
      activatedAt: now,
      expiryDate: expiry,
      lastOpenedDate: now,
    );
    await _licenseManager.licenseRepository.saveLicenseInfo(updatedLicense);
    _licenseInfo = updatedLicense;
    notifyListeners();
  }

  Future<void> lockGrade() async {
    await _settingsRepository.updateGradeLock(true);
    _settings = await _settingsRepository.getSettings();
    notifyListeners();
  }

  Future<void> unlockGrade() async {
    await _settingsRepository.updateGradeLock(false);
    _settings = await _settingsRepository.getSettings();
    notifyListeners();
  }

  Future<void> setGrade(int grade) async {
    await _settingsRepository.updateGrade(grade);
    _settings = await _settingsRepository.getSettings();
    if (_activeLearner != null && _activeLearner!.grade != grade) {
      final updated = _activeLearner!.copyWith(grade: grade);
      await _learnerRepository.updateLearnerProfile(updated);
      _activeLearner = updated;
    }
    await refreshAnalytics();
    notifyListeners();
  }

  Future<void> setIndigenousLanguage(String language) async {
    await _settingsRepository.updateIndigenousLanguage(language);
    _settings = await _settingsRepository.getSettings();
    if (_activeLearner != null && _activeLearner!.indigenousLanguage != language) {
      final updated = _activeLearner!.copyWith(indigenousLanguage: language);
      await _learnerRepository.updateLearnerProfile(updated);
      _activeLearner = updated;
    }
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
    String? unit,
  }) async {
    final int grade = currentGrade;
    final String indigenousLang = currentIndigenousLang;
    _activeSubject = subject ?? _activeSubject;

    _currentTestType = testType;
    _currentQuizTopic = topic;
    _currentQuizUnit = unit;

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
        unit: unit,
        indigenousLanguage: indigenousLang,
      );
    }

    if (subject != null && topic != null) {
      _totalUnitQuestionsAvailable = await _questionRepository.getQuestionCountForUnit(
        grade: grade,
        subject: subject,
        topic: topic,
        unit: unit,
      );
    } else {
      _totalUnitQuestionsAvailable = _currentQuizQuestions.length;
    }

    _currentQuestionIndex = 0;
    _userSelectedOptionIds.clear();
    _currentAttemptAnswers = [];
    _lastCompletedAttempt = null;
    notifyListeners();
  }

  /// Selects or changes answer for question at [questionIndex] (Deferred Feedback mode).
  void selectOptionForQuestion(int questionIndex, String optionId) {
    _userSelectedOptionIds[questionIndex] = optionId;
    notifyListeners();
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _currentQuizQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < _currentQuizQuestions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  /// Submits the quiz attempt after all questions have been reviewed/answered by child.
  Future<QuizAttempt> finishQuiz(TestType testType, String subject, String topic) async {
    final int grade = currentGrade;
    final String attemptId = 'attempt_${DateTime.now().millisecondsSinceEpoch}';

    // Evaluate answers at submission time
    _currentAttemptAnswers = [];
    int correctCount = 0;

    for (int i = 0; i < _currentQuizQuestions.length; i++) {
      final q = _currentQuizQuestions[i];
      final selectedOptId = _userSelectedOptionIds[i] ?? '';
      
      bool isCorrect = false;
      if (selectedOptId.isNotEmpty) {
        final opt = q.options.firstWhere(
          (o) => o.id == selectedOptId,
          orElse: () => QuestionOption(id: '', questionId: q.id, optionText: '', isCorrect: false),
        );
        isCorrect = opt.isCorrect;
      }

      if (isCorrect) correctCount++;

      _currentAttemptAnswers.add(AttemptAnswer(
        attemptId: attemptId,
        questionId: q.id,
        selectedOptionId: selectedOptId,
        isCorrect: isCorrect,
      ));
    }

    final attempt = QuizAttempt(
      id: attemptId,
      testType: testType == TestType.practice
          ? 'Practice'
          : testType == TestType.revision
              ? 'Revision'
              : testType == TestType.topicRevision
                  ? 'Topic Revision'
                  : 'Daily Challenge',
      grade: grade,
      subject: subject,
      topic: topic,
      totalQuestions: _currentQuizQuestions.length,
      correctCount: correctCount,
      timestamp: DateTime.now(),
      learnerProfileId: _activeLearner?.id,
    );

    await _analyticsRepository.saveQuizAttempt(attempt: attempt, answers: _currentAttemptAnswers);
    _lastCompletedAttempt = attempt;
    await refreshAnalytics();
    notifyListeners();
    return attempt;
  }
}
