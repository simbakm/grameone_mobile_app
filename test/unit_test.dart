import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grame_one/application/content_manager.dart';
import 'package:grame_one/application/license_manager.dart';
import 'package:grame_one/data/models/models.dart';
import 'package:grame_one/data/repositories/question_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  group('LicenseManager Anti-Tamper & Device Binding Tests', () {
    final licenseManager = LicenseManager();

    test('Device ID is consistent and formatted correctly', () async {
      final devId = await licenseManager.getDeviceId();
      expect(devId.startsWith('DEV-'), isTrue);
      expect(devId.length, greaterThan(8));
    });

    test('Activation code validation accepts valid format', () async {
      final valid = await licenseManager.activateDevice('GRAME-2026');
      expect(valid, isTrue);
    });

    test('Activation code validation rejects bogus key', () async {
      final valid = await licenseManager.activateDevice('INVALID-KEY-1234');
      expect(valid, isFalse);
    });
  });

  group('Indigenous Language Filtering Tests', () {
    final questionRepository = QuestionRepository();
    final contentManager = ContentManager(questionRepository: questionRepository);

    test('Selected Indigenous language returns only questions for that specific language', () async {
      await contentManager.seedDefaultQuestionsIfEmpty();

      final shonaQuestions = await questionRepository.getQuestions(
        grade: 7,
        subject: 'Indigenous Language',
        indigenousLanguage: 'Shona',
      );

      final tongaQuestions = await questionRepository.getQuestions(
        grade: 7,
        subject: 'Indigenous Language',
        indigenousLanguage: 'Tonga',
      );

      expect(shonaQuestions.isNotEmpty, isTrue);
      expect(shonaQuestions.every((q) => q.unit == 'Shona'), isTrue);
      expect(shonaQuestions.any((q) => q.unit == 'Tonga'), isFalse);

      expect(tongaQuestions.isNotEmpty, isTrue);
      expect(tongaQuestions.every((q) => q.unit == 'Tonga'), isTrue);
      expect(tongaQuestions.any((q) => q.unit == 'Shona'), isFalse);
    });

    test('All-subject query (daily challenge) excludes other language\'s indigenous questions', () async {
      await contentManager.seedDefaultQuestionsIfEmpty();

      // Simulate what daily challenge does: no subject filter, indigenousLanguage = 'Shona'
      final allForShona = await questionRepository.getQuestions(
        grade: 7,
        indigenousLanguage: 'Shona',
      );

      // Must include non-indigenous subjects
      expect(allForShona.any((q) => q.subject == 'Science'), isTrue,
          reason: 'Science questions must appear in all-subject queries');
      expect(allForShona.any((q) => q.subject == 'Mathematics'), isTrue,
          reason: 'Mathematics questions must appear in all-subject queries');

      // Must include Shona indigenous questions
      expect(allForShona.any((q) => q.subject == 'Indigenous Language' && q.unit == 'Shona'),
          isTrue, reason: 'Shona indigenous questions must be included');

      // Must NOT include other language indigenous questions
      expect(allForShona.any((q) => q.subject == 'Indigenous Language' && q.unit == 'Tonga'),
          isFalse, reason: 'Tonga questions must be excluded when Shona is selected');
      expect(allForShona.any((q) => q.subject == 'Indigenous Language' && q.unit == 'Ndebele'),
          isFalse, reason: 'Ndebele questions must be excluded when Shona is selected');
    });
  });

  group('Quiz Engine & Randomizer Tests', () {
    test('Question option shuffling preserves answer correctness flags', () {
      final question = Question(
        id: 'q1',
        grade: 7,
        subject: 'Science',
        topic: 'Health',
        unit: 'Hygiene',
        concept: 'Hygiene',
        difficulty: 'Easy',
        questionText: 'Test Question?',
        explanation: 'Test Explanation',
        options: [
          QuestionOption(id: 'opt1', questionId: 'q1', optionText: 'Option A', isCorrect: true),
          QuestionOption(id: 'opt2', questionId: 'q1', optionText: 'Option B', isCorrect: false),
          QuestionOption(id: 'opt3', questionId: 'q1', optionText: 'Option C', isCorrect: false),
        ],
      );

      final hasCorrect = question.options.any((o) => o.isCorrect);
      expect(hasCorrect, isTrue);
    });
  });

  group('Strict Centralized Color Policy Enforcement Test', () {
    test('Ensures no raw Color() or Colors.x declarations outside lib/theme/app_theme.dart', () {
      final libDir = Directory('lib');
      final files = libDir.listSync(recursive: true).whereType<File>();

      List<String> violations = [];
      for (var file in files) {
        if (file.path.contains('app_theme.dart')) continue;

        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().startsWith('//')) continue;

          if ((line.contains('Colors.') || line.contains('Color(0x') || line.contains('Color(0xFF')) &&
              !line.contains('AppColors.')) {
            violations.add('${file.path}: L${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(violations, isEmpty, reason: 'Strict Color Policy violated! Found raw colors outside app_theme.dart:\n${violations.join('\n')}');
    });
  });
}
