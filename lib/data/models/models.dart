class QuestionOption {
  final String id;
  final String questionId;
  final String optionText;
  final bool isCorrect;

  QuestionOption({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'option_text': optionText,
      'is_correct': isCorrect ? 1 : 0,
    };
  }

  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(
      id: map['id'] as String,
      questionId: map['question_id'] as String,
      optionText: map['option_text'] as String,
      isCorrect: (map['is_correct'] as int) == 1,
    );
  }
}

class Question {
  final String id;
  final int grade;
  final String subject;
  final String topic;
  final String unit;
  final String concept;
  final String difficulty;
  final String questionText;
  final String? comprehensionText;
  final String? imagePath;
  final String? diagramPath;
  final String explanation;
  final List<QuestionOption> options;

  Question({
    required this.id,
    required this.grade,
    required this.subject,
    required this.topic,
    required this.unit,
    required this.concept,
    required this.difficulty,
    required this.questionText,
    this.comprehensionText,
    this.imagePath,
    this.diagramPath,
    required this.explanation,
    required this.options,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grade': grade,
      'subject': subject,
      'topic': topic,
      'unit': unit,
      'concept': concept,
      'difficulty': difficulty,
      'question_text': questionText,
      'comprehension_text': comprehensionText,
      'image_path': imagePath,
      'diagram_path': diagramPath,
      'explanation': explanation,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map, List<QuestionOption> options) {
    return Question(
      id: map['id'] as String,
      grade: map['grade'] as int,
      subject: map['subject'] as String,
      topic: map['topic'] as String,
      unit: map['unit'] as String,
      concept: map['concept'] as String,
      difficulty: map['difficulty'] as String,
      questionText: map['question_text'] as String,
      comprehensionText: map['comprehension_text'] as String?,
      imagePath: map['image_path'] as String?,
      diagramPath: map['diagram_path'] as String?,
      explanation: map['explanation'] as String,
      options: options,
    );
  }

  Question copyWith({List<QuestionOption>? options}) {
    return Question(
      id: id,
      grade: grade,
      subject: subject,
      topic: topic,
      unit: unit,
      concept: concept,
      difficulty: difficulty,
      questionText: questionText,
      comprehensionText: comprehensionText,
      imagePath: imagePath,
      diagramPath: diagramPath,
      explanation: explanation,
      options: options ?? this.options,
    );
  }
}

class QuizAttempt {
  final String id;
  final String testType; // Practice, Revision, Daily Challenge
  final int grade;
  final String subject;
  final String topic;
  final int totalQuestions;
  final int correctCount;
  final DateTime timestamp;
  final String? learnerProfileId; // ← isolates attempts per learner

  QuizAttempt({
    required this.id,
    required this.testType,
    required this.grade,
    required this.subject,
    required this.topic,
    required this.totalQuestions,
    required this.correctCount,
    required this.timestamp,
    this.learnerProfileId,
  });

  double get scorePercentage => (correctCount / (totalQuestions > 0 ? totalQuestions : 1)) * 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'test_type': testType,
      'grade': grade,
      'subject': subject,
      'topic': topic,
      'total_questions': totalQuestions,
      'correct_count': correctCount,
      'timestamp': timestamp.toIso8601String(),
      'learner_profile_id': learnerProfileId,
    };
  }

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: map['id'] as String,
      testType: map['test_type'] as String,
      grade: map['grade'] as int,
      subject: map['subject'] as String,
      topic: map['topic'] as String,
      totalQuestions: map['total_questions'] as int,
      correctCount: map['correct_count'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      learnerProfileId: map['learner_profile_id'] as String?,
    );
  }
}

// ─── Learner Profile ─────────────────────────────────────────────────────────

class LearnerProfile {
  final String id;
  final String name;
  final String avatar; // emoji avatar e.g. '🧒'
  final int grade;
  final String indigenousLanguage;
  final DateTime createdAt;

  LearnerProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.grade,
    required this.indigenousLanguage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'grade': grade,
      'indigenous_language': indigenousLanguage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LearnerProfile.fromMap(Map<String, dynamic> map) {
    return LearnerProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      avatar: map['avatar'] as String,
      grade: map['grade'] as int,
      indigenousLanguage: map['indigenous_language'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  LearnerProfile copyWith({
    String? name,
    String? avatar,
    int? grade,
    String? indigenousLanguage,
  }) {
    return LearnerProfile(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      grade: grade ?? this.grade,
      indigenousLanguage: indigenousLanguage ?? this.indigenousLanguage,
      createdAt: createdAt,
    );
  }
}


class AttemptAnswer {
  final String attemptId;
  final String questionId;
  final String selectedOptionId;
  final bool isCorrect;

  AttemptAnswer({
    required this.attemptId,
    required this.questionId,
    required this.selectedOptionId,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'attempt_id': attemptId,
      'question_id': questionId,
      'selected_option_id': selectedOptionId,
      'is_correct': isCorrect ? 1 : 0,
    };
  }

  factory AttemptAnswer.fromMap(Map<String, dynamic> map) {
    return AttemptAnswer(
      attemptId: map['attempt_id'] as String,
      questionId: map['question_id'] as String,
      selectedOptionId: map['selected_option_id'] as String,
      isCorrect: (map['is_correct'] as int) == 1,
    );
  }
}

class LicenseInfo {
  final String deviceId;
  final String? activationCode;
  final bool isActivated;
  final DateTime? activatedAt;
  final DateTime? expiryDate;
  final DateTime lastOpenedDate;

  LicenseInfo({
    required this.deviceId,
    this.activationCode,
    required this.isActivated,
    this.activatedAt,
    this.expiryDate,
    required this.lastOpenedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'device_id': deviceId,
      'activation_code': activationCode,
      'is_activated': isActivated ? 1 : 0,
      'activated_at': activatedAt?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'last_opened_date': lastOpenedDate.toIso8601String(),
    };
  }

  factory LicenseInfo.fromMap(Map<String, dynamic> map) {
    return LicenseInfo(
      deviceId: map['device_id'] as String,
      activationCode: map['activation_code'] as String?,
      isActivated: (map['is_activated'] as int) == 1,
      activatedAt: map['activated_at'] != null ? DateTime.parse(map['activated_at'] as String) : null,
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date'] as String) : null,
      lastOpenedDate: DateTime.parse(map['last_opened_date'] as String),
    );
  }
}

class UserSettings {
  final int selectedGrade;
  final String selectedIndigenousLang;
  final bool darkMode;
  final bool isGradeLocked;

  UserSettings({
    required this.selectedGrade,
    required this.selectedIndigenousLang,
    required this.darkMode,
    this.isGradeLocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'selected_grade': selectedGrade,
      'selected_indigenous_lang': selectedIndigenousLang,
      'dark_mode': darkMode ? 1 : 0,
      'is_grade_locked': isGradeLocked ? 1 : 0,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      selectedGrade: map['selected_grade'] as int,
      selectedIndigenousLang: map['selected_indigenous_lang'] as String,
      darkMode: (map['dark_mode'] as int? ?? 0) == 1,
      isGradeLocked: (map['is_grade_locked'] as int? ?? 0) == 1,
    );
  }
}

class BadgeModel {
  final String id;
  final String badgeKey;
  final String title;
  final String description;
  final String iconName;
  final DateTime? unlockedAt;

  BadgeModel({
    required this.id,
    required this.badgeKey,
    required this.title,
    required this.description,
    required this.iconName,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'badge_key': badgeKey,
      'title': title,
      'description': description,
      'icon_name': iconName,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'] as String,
      badgeKey: map['badge_key'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      iconName: map['icon_name'] as String,
      unlockedAt: map['unlocked_at'] != null ? DateTime.parse(map['unlocked_at'] as String) : null,
    );
  }
}
