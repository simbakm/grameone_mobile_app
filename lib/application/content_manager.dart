import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/models.dart';
import '../data/repositories/question_repository.dart';

class ContentManager {
  final QuestionRepository questionRepository;

  ContentManager({QuestionRepository? questionRepository})
      : questionRepository = questionRepository ?? QuestionRepository();

  Future<void> seedDefaultQuestionsIfEmpty() async {
    final count = await questionRepository.getQuestionCount(grade: 7);
    if (count > 0) return; // Keep existing questions, do not overwrite

    final prefs = await SharedPreferences.getInstance();
    final hasDownloadedVersion = prefs.containsKey('content_version_7');
    if (hasDownloadedVersion) return; // Content package downloaded, do not seed mock data

    List<Question> seedQuestions = [];

    seedQuestions.addAll(_generateScienceQuestions());
    seedQuestions.addAll(_generateMathQuestions());
    seedQuestions.addAll(_generateEnglishQuestions());
    seedQuestions.addAll(_generateAgricultureQuestions());
    seedQuestions.addAll(_generateSocialScienceQuestions());
    seedQuestions.addAll(_generateIndigenousQuestions());

    await questionRepository.insertQuestions(seedQuestions);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCIENCE – 10 questions
  // ─────────────────────────────────────────────────────────────────────────
  List<Question> _generateScienceQuestions() {
    return [
      Question(
        id: 'sci_7_1',
        grade: 7,
        subject: 'Science',
        topic: 'Health and Hygiene Practices',
        unit: 'Personal Hygiene',
        concept: 'Disease Prevention',
        difficulty: 'Medium',
        questionText:
            'Which of the following is the most effective way to prevent the spread of waterborne diseases like cholera?',
        explanation:
            'Boiling water kills harmful pathogens and bacteria causing waterborne diseases.',
        options: [
          QuestionOption(id: 'sci_7_1_a', questionId: 'sci_7_1', optionText: 'Boiling drinking water before use', isCorrect: true),
          QuestionOption(id: 'sci_7_1_b', questionId: 'sci_7_1', optionText: 'Leaving water uncovered in the sun', isCorrect: false),
          QuestionOption(id: 'sci_7_1_c', questionId: 'sci_7_1', optionText: 'Filtering water through cloth only', isCorrect: false),
          QuestionOption(id: 'sci_7_1_d', questionId: 'sci_7_1', optionText: 'Adding salt to unboiled water', isCorrect: false),
        ],
      ),
      Question(
        id: 'sci_7_2',
        grade: 7,
        subject: 'Science',
        topic: 'Food and Nutrition',
        unit: 'Balanced Diet',
        concept: 'Nutrients and Functions',
        difficulty: 'Easy',
        questionText:
            'Which class of food is primarily responsible for tissue repair and growth in the body?',
        explanation: 'Proteins are essential for building and repairing body tissues.',
        options: [
          QuestionOption(id: 'sci_7_2_a', questionId: 'sci_7_2', optionText: 'Proteins', isCorrect: true),
          QuestionOption(id: 'sci_7_2_b', questionId: 'sci_7_2', optionText: 'Carbohydrates', isCorrect: false),
          QuestionOption(id: 'sci_7_2_c', questionId: 'sci_7_2', optionText: 'Fats and Oils', isCorrect: false),
          QuestionOption(id: 'sci_7_2_d', questionId: 'sci_7_2', optionText: 'Vitamins', isCorrect: false),
        ],
      ),
      Question(
        id: 'sci_7_3',
        grade: 7,
        subject: 'Science',
        topic: 'Crops, Plants and Animals',
        unit: 'Photosynthesis',
        concept: 'Plant Physiology',
        difficulty: 'Medium',
        questionText:
            'What gas do green plants absorb from the atmosphere during photosynthesis?',
        explanation:
            'Green plants take in carbon dioxide and release oxygen during photosynthesis.',
        options: [
          QuestionOption(id: 'sci_7_3_a', questionId: 'sci_7_3', optionText: 'Carbon dioxide', isCorrect: true),
          QuestionOption(id: 'sci_7_3_b', questionId: 'sci_7_3', optionText: 'Oxygen', isCorrect: false),
          QuestionOption(id: 'sci_7_3_c', questionId: 'sci_7_3', optionText: 'Nitrogen', isCorrect: false),
          QuestionOption(id: 'sci_7_3_d', questionId: 'sci_7_3', optionText: 'Hydrogen', isCorrect: false),
        ],
      ),
      Question(
        id: 'sci_7_4',
        grade: 7,
        subject: 'Science',
        topic: 'Environmental Awareness and Conservation',
        unit: 'Soil Erosion',
        concept: 'Conservation Methods',
        difficulty: 'Medium',
        questionText: 'Which practice helps prevent soil erosion on steep hillsides?',
        explanation: 'Terracing slows water runoff and retains topsoil on steep hills.',
        options: [
          QuestionOption(id: 'sci_7_4_a', questionId: 'sci_7_4', optionText: 'Terracing and contour plowing', isCorrect: true),
          QuestionOption(id: 'sci_7_4_b', questionId: 'sci_7_4', optionText: 'Deforestation', isCorrect: false),
          QuestionOption(id: 'sci_7_4_c', questionId: 'sci_7_4', optionText: 'Overgrazing livestock', isCorrect: false),
          QuestionOption(id: 'sci_7_4_d', questionId: 'sci_7_4', optionText: 'Veld fires', isCorrect: false),
        ],
      ),
      Question(
        id: 'sci_7_5',
        grade: 7,
        subject: 'Science',
        topic: 'Tools, Equipment and Implements',
        unit: 'Simple Machines',
        concept: 'Levers & Pulleys',
        difficulty: 'Easy',
        questionText:
            'Which simple machine is used to lift heavy loads vertically using a wheel and rope?',
        explanation:
            'A pulley consists of a grooved wheel and rope used to change direction of force.',
        options: [
          QuestionOption(id: 'sci_7_5_a', questionId: 'sci_7_5', optionText: 'Pulley', isCorrect: true),
          QuestionOption(id: 'sci_7_5_b', questionId: 'sci_7_5', optionText: 'Inclined Plane', isCorrect: false),
          QuestionOption(id: 'sci_7_5_c', questionId: 'sci_7_5', optionText: 'Wedge', isCorrect: false),
          QuestionOption(id: 'sci_7_5_d', questionId: 'sci_7_5', optionText: 'Screw', isCorrect: false),
        ],
      ),
      // ── Science Extra ──────────────────────────────────────────────────
      Question(
        id: 'sci_7_6',
        grade: 7,
        subject: 'Science',
        topic: 'Health and Hygiene Practices',
        unit: 'Personal Hygiene',
        concept: 'Immunisation',
        difficulty: 'Easy',
        questionText:
            'Which practice protects a child from getting measles?',
        explanation:
            'Vaccination introduces a weakened form of the pathogen to build immunity.',
        options: [
          QuestionOption(id: 'sci_7_6_a', questionId: 'sci_7_6', optionText: 'Vaccination / immunisation', isCorrect: true),
          QuestionOption(id: 'sci_7_6_b', questionId: 'sci_7_6', optionText: 'Eating more sugar', isCorrect: false),
          QuestionOption(id: 'sci_7_6_c', questionId: 'sci_7_6', optionText: 'Wearing extra clothing', isCorrect: false),
          QuestionOption(id: 'sci_7_6_d', questionId: 'sci_7_6', optionText: 'Sleeping in the sun', isCorrect: false),
        ],
      ),
      Question(
        id: 'sci_7_7',
        grade: 7,
        subject: 'Science',
        topic: 'Food and Nutrition',
        unit: 'Balanced Diet',
        concept: 'Vitamins',
        difficulty: 'Easy',
        questionText:
            'Which vitamin is produced in the skin when it is exposed to sunlight?',
        explanation: 'Vitamin D is synthesised by the body when skin is exposed to UV light.',
        options: [
          QuestionOption(id: 'sci_7_7_a', questionId: 'sci_7_7', optionText: 'Vitamin D', isCorrect: true),
          QuestionOption(id: 'sci_7_7_b', questionId: 'sci_7_7', optionText: 'Vitamin C', isCorrect: false),
          QuestionOption(id: 'sci_7_7_c', questionId: 'sci_7_7', optionText: 'Vitamin A', isCorrect: false),
          QuestionOption(id: 'sci_7_7_d', questionId: 'sci_7_7', optionText: 'Vitamin K', isCorrect: false),
        ],
      ),
      Question(
        id: 'sci_7_8',
        grade: 7,
        subject: 'Science',
        topic: 'Crops, Plants and Animals',
        unit: 'Pollination',
        concept: 'Plant Reproduction',
        difficulty: 'Medium',
        questionText:
            'Which agent is the most common carrier of pollen between flowering plants?',
        explanation: 'Bees carry pollen on their bodies as they feed on nectar, pollinating plants.',
        options: [
          QuestionOption(id: 'sci_7_8_a', questionId: 'sci_7_8', optionText: 'Bees (insects)', isCorrect: true),
          QuestionOption(id: 'sci_7_8_b', questionId: 'sci_7_8', optionText: 'Earthworms', isCorrect: false),
          QuestionOption(id: 'sci_7_8_c', questionId: 'sci_7_8', optionText: 'Rainfall', isCorrect: false),
          QuestionOption(id: 'sci_7_8_d', questionId: 'sci_7_8', optionText: 'Roots', isCorrect: false),
        ],
      ),
      Question(
        id: 'sci_7_9',
        grade: 7,
        subject: 'Science',
        topic: 'Environmental Awareness and Conservation',
        unit: 'Pollution',
        concept: 'Water Pollution',
        difficulty: 'Medium',
        questionText:
            'What is the main environmental danger of dumping untreated sewage into rivers?',
        explanation:
            'Sewage depletes oxygen in water, killing aquatic life and spreading disease.',
        options: [
          QuestionOption(id: 'sci_7_9_a', questionId: 'sci_7_9', optionText: 'It reduces dissolved oxygen and spreads disease', isCorrect: true),
          QuestionOption(id: 'sci_7_9_b', questionId: 'sci_7_9', optionText: 'It makes the river flow faster', isCorrect: false),
          QuestionOption(id: 'sci_7_9_c', questionId: 'sci_7_9', optionText: 'It warms the river water slightly', isCorrect: false),
          QuestionOption(id: 'sci_7_9_d', questionId: 'sci_7_9', optionText: 'It increases fish population', isCorrect: false),
        ],
      ),
      Question(
        id: 'sci_7_10',
        grade: 7,
        subject: 'Science',
        topic: 'Tools, Equipment and Implements',
        unit: 'Simple Machines',
        concept: 'Levers',
        difficulty: 'Medium',
        questionText:
            'A wheelbarrow is an example of which class of lever?',
        explanation:
            'A wheelbarrow is a second-class lever: load between fulcrum and effort.',
        options: [
          QuestionOption(id: 'sci_7_10_a', questionId: 'sci_7_10', optionText: 'Second-class lever', isCorrect: true),
          QuestionOption(id: 'sci_7_10_b', questionId: 'sci_7_10', optionText: 'First-class lever', isCorrect: false),
          QuestionOption(id: 'sci_7_10_c', questionId: 'sci_7_10', optionText: 'Third-class lever', isCorrect: false),
          QuestionOption(id: 'sci_7_10_d', questionId: 'sci_7_10', optionText: 'Not a lever', isCorrect: false),
        ],
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MATHEMATICS – 6 questions
  // ─────────────────────────────────────────────────────────────────────────
  List<Question> _generateMathQuestions() {
    return [
      Question(
        id: 'math_7_1',
        grade: 7,
        subject: 'Mathematics',
        topic: 'Numbers and Operations',
        unit: 'Fractions and Decimals',
        concept: 'Fraction Multiplication',
        difficulty: 'Medium',
        questionText: 'What is 3/4 multiplied by 2/5 in simplest form?',
        explanation: '(3 × 2) / (4 × 5) = 6/20 = 3/10.',
        options: [
          QuestionOption(id: 'math_7_1_a', questionId: 'math_7_1', optionText: '3/10', isCorrect: true),
          QuestionOption(id: 'math_7_1_b', questionId: 'math_7_1', optionText: '5/9', isCorrect: false),
          QuestionOption(id: 'math_7_1_c', questionId: 'math_7_1', optionText: '6/20', isCorrect: false),
          QuestionOption(id: 'math_7_1_d', questionId: 'math_7_1', optionText: '8/15', isCorrect: false),
        ],
      ),
      Question(
        id: 'math_7_2',
        grade: 7,
        subject: 'Mathematics',
        topic: 'Measures and Geometry',
        unit: 'Area & Perimeter',
        concept: 'Rectangle Area',
        difficulty: 'Easy',
        questionText:
            'Calculate the area of a rectangular garden measuring 12 m long and 8 m wide.',
        explanation: 'Area = length × width = 12 m × 8 m = 96 m².',
        options: [
          QuestionOption(id: 'math_7_2_a', questionId: 'math_7_2', optionText: '96 m²', isCorrect: true),
          QuestionOption(id: 'math_7_2_b', questionId: 'math_7_2', optionText: '40 m', isCorrect: false),
          QuestionOption(id: 'math_7_2_c', questionId: 'math_7_2', optionText: '84 m²', isCorrect: false),
          QuestionOption(id: 'math_7_2_d', questionId: 'math_7_2', optionText: '108 m²', isCorrect: false),
        ],
      ),
      // ── Math Extra ─────────────────────────────────────────────────────
      Question(
        id: 'math_7_3',
        grade: 7,
        subject: 'Mathematics',
        topic: 'Numbers and Operations',
        unit: 'Percentages',
        concept: 'Finding Percentage',
        difficulty: 'Medium',
        questionText: 'A learner scored 36 out of 45. What is the percentage score?',
        explanation: 'Percentage = (36 ÷ 45) × 100 = 80%.',
        options: [
          QuestionOption(id: 'math_7_3_a', questionId: 'math_7_3', optionText: '80%', isCorrect: true),
          QuestionOption(id: 'math_7_3_b', questionId: 'math_7_3', optionText: '75%', isCorrect: false),
          QuestionOption(id: 'math_7_3_c', questionId: 'math_7_3', optionText: '85%', isCorrect: false),
          QuestionOption(id: 'math_7_3_d', questionId: 'math_7_3', optionText: '72%', isCorrect: false),
        ],
      ),
      Question(
        id: 'math_7_4',
        grade: 7,
        subject: 'Mathematics',
        topic: 'Numbers and Operations',
        unit: 'Fractions and Decimals',
        concept: 'Fraction Division',
        difficulty: 'Hard',
        questionText: 'Divide 5/6 by 2/3. Express your answer in simplest form.',
        explanation: 'Dividing: 5/6 ÷ 2/3 = 5/6 × 3/2 = 15/12 = 5/4 = 1¼.',
        options: [
          QuestionOption(id: 'math_7_4_a', questionId: 'math_7_4', optionText: '5/4 (1¼)', isCorrect: true),
          QuestionOption(id: 'math_7_4_b', questionId: 'math_7_4', optionText: '10/18', isCorrect: false),
          QuestionOption(id: 'math_7_4_c', questionId: 'math_7_4', optionText: '3/4', isCorrect: false),
          QuestionOption(id: 'math_7_4_d', questionId: 'math_7_4', optionText: '7/6', isCorrect: false),
        ],
      ),
      Question(
        id: 'math_7_5',
        grade: 7,
        subject: 'Mathematics',
        topic: 'Measures and Geometry',
        unit: 'Area & Perimeter',
        concept: 'Triangle Area',
        difficulty: 'Easy',
        questionText:
            'What is the area of a triangle with a base of 10 cm and a height of 6 cm?',
        explanation: 'Area = ½ × base × height = ½ × 10 × 6 = 30 cm².',
        options: [
          QuestionOption(id: 'math_7_5_a', questionId: 'math_7_5', optionText: '30 cm²', isCorrect: true),
          QuestionOption(id: 'math_7_5_b', questionId: 'math_7_5', optionText: '60 cm²', isCorrect: false),
          QuestionOption(id: 'math_7_5_c', questionId: 'math_7_5', optionText: '16 cm²', isCorrect: false),
          QuestionOption(id: 'math_7_5_d', questionId: 'math_7_5', optionText: '32 cm²', isCorrect: false),
        ],
      ),
      Question(
        id: 'math_7_6',
        grade: 7,
        subject: 'Mathematics',
        topic: 'Measures and Geometry',
        unit: 'Angles',
        concept: 'Types of Angles',
        difficulty: 'Easy',
        questionText: 'An angle that measures exactly 90° is called a _____ angle.',
        explanation: 'A right angle is exactly 90°.',
        options: [
          QuestionOption(id: 'math_7_6_a', questionId: 'math_7_6', optionText: 'Right angle', isCorrect: true),
          QuestionOption(id: 'math_7_6_b', questionId: 'math_7_6', optionText: 'Obtuse angle', isCorrect: false),
          QuestionOption(id: 'math_7_6_c', questionId: 'math_7_6', optionText: 'Acute angle', isCorrect: false),
          QuestionOption(id: 'math_7_6_d', questionId: 'math_7_6', optionText: 'Reflex angle', isCorrect: false),
        ],
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ENGLISH – 4 questions
  // ─────────────────────────────────────────────────────────────────────────
  List<Question> _generateEnglishQuestions() {
    return [
      Question(
        id: 'eng_7_1',
        grade: 7,
        subject: 'English',
        topic: 'Grammar and Structure',
        unit: 'Parts of Speech',
        concept: 'Adverbs',
        difficulty: 'Easy',
        questionText:
            'Identify the adverb in the sentence: "The diligent student solved the puzzle quickly."',
        explanation: '"Quickly" describes how the action (solved) was performed.',
        options: [
          QuestionOption(id: 'eng_7_1_a', questionId: 'eng_7_1', optionText: 'quickly', isCorrect: true),
          QuestionOption(id: 'eng_7_1_b', questionId: 'eng_7_1', optionText: 'diligent', isCorrect: false),
          QuestionOption(id: 'eng_7_1_c', questionId: 'eng_7_1', optionText: 'solved', isCorrect: false),
          QuestionOption(id: 'eng_7_1_d', questionId: 'eng_7_1', optionText: 'puzzle', isCorrect: false),
        ],
      ),
      Question(
        id: 'eng_7_2',
        grade: 7,
        subject: 'English',
        topic: 'Grammar and Structure',
        unit: 'Parts of Speech',
        concept: 'Pronouns',
        difficulty: 'Easy',
        questionText:
            'Choose the correct pronoun: "The teacher praised _____ for the excellent work." (referring to the boy)',
        explanation:
            '"Him" is the objective case pronoun used when the noun is the object of the verb.',
        options: [
          QuestionOption(id: 'eng_7_2_a', questionId: 'eng_7_2', optionText: 'him', isCorrect: true),
          QuestionOption(id: 'eng_7_2_b', questionId: 'eng_7_2', optionText: 'his', isCorrect: false),
          QuestionOption(id: 'eng_7_2_c', questionId: 'eng_7_2', optionText: 'he', isCorrect: false),
          QuestionOption(id: 'eng_7_2_d', questionId: 'eng_7_2', optionText: 'himself', isCorrect: false),
        ],
      ),
      Question(
        id: 'eng_7_3',
        grade: 7,
        subject: 'English',
        topic: 'Reading and Comprehension',
        unit: 'Comprehension Skills',
        concept: 'Main Idea',
        difficulty: 'Medium',
        questionText:
            'In a comprehension passage, the "main idea" refers to:',
        explanation:
            'The main idea is the central thought or argument the author wishes to convey.',
        options: [
          QuestionOption(id: 'eng_7_3_a', questionId: 'eng_7_3', optionText: 'The central message or point of the passage', isCorrect: true),
          QuestionOption(id: 'eng_7_3_b', questionId: 'eng_7_3', optionText: 'A specific detail from one paragraph', isCorrect: false),
          QuestionOption(id: 'eng_7_3_c', questionId: 'eng_7_3', optionText: 'The title of the passage', isCorrect: false),
          QuestionOption(id: 'eng_7_3_d', questionId: 'eng_7_3', optionText: 'The last sentence of the passage', isCorrect: false),
        ],
      ),
      Question(
        id: 'eng_7_4',
        grade: 7,
        subject: 'English',
        topic: 'Reading and Comprehension',
        unit: 'Vocabulary',
        concept: 'Antonyms',
        difficulty: 'Easy',
        questionText: 'What is the antonym of the word "generous"?',
        explanation: '"Selfish" or "miserly" are the antonyms of generous.',
        options: [
          QuestionOption(id: 'eng_7_4_a', questionId: 'eng_7_4', optionText: 'Selfish', isCorrect: true),
          QuestionOption(id: 'eng_7_4_b', questionId: 'eng_7_4', optionText: 'Kind', isCorrect: false),
          QuestionOption(id: 'eng_7_4_c', questionId: 'eng_7_4', optionText: 'Charitable', isCorrect: false),
          QuestionOption(id: 'eng_7_4_d', questionId: 'eng_7_4', optionText: 'Helpful', isCorrect: false),
        ],
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AGRICULTURE – 4 questions
  // ─────────────────────────────────────────────────────────────────────────
  List<Question> _generateAgricultureQuestions() {
    return [
      Question(
        id: 'agri_7_1',
        grade: 7,
        subject: 'Agriculture',
        topic: 'Soil Science and Crops',
        unit: 'Fertility',
        concept: 'Composting',
        difficulty: 'Easy',
        questionText:
            'Which organic material supplies nitrogen-rich content to compost heaps?',
        explanation: 'Green plant cuttings and animal manure are rich in nitrogen.',
        options: [
          QuestionOption(id: 'agri_7_1_a', questionId: 'agri_7_1', optionText: 'Green grass clippings and manure', isCorrect: true),
          QuestionOption(id: 'agri_7_1_b', questionId: 'agri_7_1', optionText: 'Dry maize stalks', isCorrect: false),
          QuestionOption(id: 'agri_7_1_c', questionId: 'agri_7_1', optionText: 'Crushed plastic containers', isCorrect: false),
          QuestionOption(id: 'agri_7_1_d', questionId: 'agri_7_1', optionText: 'Sand particles', isCorrect: false),
        ],
      ),
      Question(
        id: 'agri_7_2',
        grade: 7,
        subject: 'Agriculture',
        topic: 'Soil Science and Crops',
        unit: 'Soil Types',
        concept: 'Loam Soil',
        difficulty: 'Medium',
        questionText:
            'Which type of soil is considered best for most crop production because it retains moisture and is well-drained?',
        explanation:
            'Loam soil is a balanced mixture of sand, silt, and clay that drains well and retains nutrients.',
        options: [
          QuestionOption(id: 'agri_7_2_a', questionId: 'agri_7_2', optionText: 'Loam soil', isCorrect: true),
          QuestionOption(id: 'agri_7_2_b', questionId: 'agri_7_2', optionText: 'Sandy soil', isCorrect: false),
          QuestionOption(id: 'agri_7_2_c', questionId: 'agri_7_2', optionText: 'Clay soil', isCorrect: false),
          QuestionOption(id: 'agri_7_2_d', questionId: 'agri_7_2', optionText: 'Gravel soil', isCorrect: false),
        ],
      ),
      Question(
        id: 'agri_7_3',
        grade: 7,
        subject: 'Agriculture',
        topic: 'Farm Management',
        unit: 'Record Keeping',
        concept: 'Farm Records',
        difficulty: 'Easy',
        questionText:
            'Why is it important for a farmer to keep production records?',
        explanation:
            'Records help farmers track expenses, yields and make informed decisions for future seasons.',
        options: [
          QuestionOption(id: 'agri_7_3_a', questionId: 'agri_7_3', optionText: 'To track costs, income and improve future planning', isCorrect: true),
          QuestionOption(id: 'agri_7_3_b', questionId: 'agri_7_3', optionText: 'To show neighbours how productive the farm is', isCorrect: false),
          QuestionOption(id: 'agri_7_3_c', questionId: 'agri_7_3', optionText: 'To avoid paying taxes', isCorrect: false),
          QuestionOption(id: 'agri_7_3_d', questionId: 'agri_7_3', optionText: 'Records are not necessary for small farms', isCorrect: false),
        ],
      ),
      Question(
        id: 'agri_7_4',
        grade: 7,
        subject: 'Agriculture',
        topic: 'Farm Management',
        unit: 'Livestock',
        concept: 'Cattle Diseases',
        difficulty: 'Medium',
        questionText:
            'Which disease in cattle is spread by ticks and can be prevented by dipping the animals?',
        explanation:
            'East Coast Fever is a tick-borne disease controlled by regular dipping of cattle.',
        options: [
          QuestionOption(id: 'agri_7_4_a', questionId: 'agri_7_4', optionText: 'East Coast Fever', isCorrect: true),
          QuestionOption(id: 'agri_7_4_b', questionId: 'agri_7_4', optionText: 'Anthrax', isCorrect: false),
          QuestionOption(id: 'agri_7_4_c', questionId: 'agri_7_4', optionText: 'Foot-and-Mouth disease', isCorrect: false),
          QuestionOption(id: 'agri_7_4_d', questionId: 'agri_7_4', optionText: 'Rabies', isCorrect: false),
        ],
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SOCIAL SCIENCE – 4 questions
  // ─────────────────────────────────────────────────────────────────────────
  List<Question> _generateSocialScienceQuestions() {
    return [
      Question(
        id: 'soc_7_1',
        grade: 7,
        subject: 'Social Science',
        topic: 'Heritage and Culture',
        unit: 'National Symbols',
        concept: 'Zimbabwe Bird',
        difficulty: 'Easy',
        questionText: 'What national monument is the Zimbabwe Bird associated with?',
        explanation: 'Soapstone birds were discovered at Great Zimbabwe.',
        options: [
          QuestionOption(id: 'soc_7_1_a', questionId: 'soc_7_1', optionText: 'Great Zimbabwe National Monument', isCorrect: true),
          QuestionOption(id: 'soc_7_1_b', questionId: 'soc_7_1', optionText: 'Victoria Falls', isCorrect: false),
          QuestionOption(id: 'soc_7_1_c', questionId: 'soc_7_1', optionText: 'Matobo Hills', isCorrect: false),
          QuestionOption(id: 'soc_7_1_d', questionId: 'soc_7_1', optionText: 'Mana Pools', isCorrect: false),
        ],
      ),
      Question(
        id: 'soc_7_2',
        grade: 7,
        subject: 'Social Science',
        topic: 'Heritage and Culture',
        unit: 'Independence',
        concept: 'Zimbabwe Independence',
        difficulty: 'Easy',
        questionText: 'On which date did Zimbabwe gain independence?',
        explanation: 'Zimbabwe gained independence from Britain on 18 April 1980.',
        options: [
          QuestionOption(id: 'soc_7_2_a', questionId: 'soc_7_2', optionText: '18 April 1980', isCorrect: true),
          QuestionOption(id: 'soc_7_2_b', questionId: 'soc_7_2', optionText: '11 November 1965', isCorrect: false),
          QuestionOption(id: 'soc_7_2_c', questionId: 'soc_7_2', optionText: '31 December 1979', isCorrect: false),
          QuestionOption(id: 'soc_7_2_d', questionId: 'soc_7_2', optionText: '1 March 1975', isCorrect: false),
        ],
      ),
      Question(
        id: 'soc_7_3',
        grade: 7,
        subject: 'Social Science',
        topic: 'Government and Citizenship',
        unit: 'Democracy',
        concept: 'Voting Rights',
        difficulty: 'Medium',
        questionText:
            'In a democratic country like Zimbabwe, who has the right to vote?',
        explanation:
            'All registered citizens aged 18 and above have the right to vote in democratic elections.',
        options: [
          QuestionOption(id: 'soc_7_3_a', questionId: 'soc_7_3', optionText: 'All registered citizens aged 18 and above', isCorrect: true),
          QuestionOption(id: 'soc_7_3_b', questionId: 'soc_7_3', optionText: 'Only men over 21', isCorrect: false),
          QuestionOption(id: 'soc_7_3_c', questionId: 'soc_7_3', optionText: 'Only the wealthy', isCorrect: false),
          QuestionOption(id: 'soc_7_3_d', questionId: 'soc_7_3', optionText: 'Only educated people', isCorrect: false),
        ],
      ),
      Question(
        id: 'soc_7_4',
        grade: 7,
        subject: 'Social Science',
        topic: 'Government and Citizenship',
        unit: 'Government Structure',
        concept: 'Three Arms of Government',
        difficulty: 'Medium',
        questionText: 'Which arm of government is responsible for making laws in Zimbabwe?',
        explanation:
            'The Legislature (Parliament) makes laws; the Executive implements them; the Judiciary interprets them.',
        options: [
          QuestionOption(id: 'soc_7_4_a', questionId: 'soc_7_4', optionText: 'The Legislature (Parliament)', isCorrect: true),
          QuestionOption(id: 'soc_7_4_b', questionId: 'soc_7_4', optionText: 'The Executive (President & Cabinet)', isCorrect: false),
          QuestionOption(id: 'soc_7_4_c', questionId: 'soc_7_4', optionText: 'The Judiciary (Courts)', isCorrect: false),
          QuestionOption(id: 'soc_7_4_d', questionId: 'soc_7_4', optionText: 'The Police Force', isCorrect: false),
        ],
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INDIGENOUS LANGUAGE – 4 Shona + 4 Ndebele + 4 Tonga = 12 questions
  // unit field MUST equal the language name exactly for filtering to work.
  // ─────────────────────────────────────────────────────────────────────────
  List<Question> _generateIndigenousQuestions() {
    return [
      // ── Shona ────────────────────────────────────────────────────────────
      Question(
        id: 'sho_7_1',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Tsumo neMadimikira (Shona)',
        unit: 'Shona',
        concept: 'Shona Proverbs',
        difficulty: 'Easy',
        questionText: 'Pedzisa tsumo inoti: "Chara chimwe hachitswanyi ..."',
        explanation:
            'Tsumo iyi inoreva kuti vanhu vanofanira kubatsirana panhau dzekushanda.',
        options: [
          QuestionOption(id: 'sho_7_1_a', questionId: 'sho_7_1', optionText: 'inda', isCorrect: true),
          QuestionOption(id: 'sho_7_1_b', questionId: 'sho_7_1', optionText: 'sango', isCorrect: false),
          QuestionOption(id: 'sho_7_1_c', questionId: 'sho_7_1', optionText: 'musha', isCorrect: false),
          QuestionOption(id: 'sho_7_1_d', questionId: 'sho_7_1', optionText: 'hove', isCorrect: false),
        ],
      ),
      Question(
        id: 'sho_7_2',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Madimikira echiShona',
        unit: 'Shona',
        concept: 'Shona Idioms',
        difficulty: 'Medium',
        questionText:
            'Chii chinoreva madimikira ekuti "Kurova imbwa wakaviga mupinyi"?',
        explanation:
            'Kurova imbwa wakaviga mupinyi zvinoreva kutaura kana kuita chinhu uine chinangwa chakavandika.',
        options: [
          QuestionOption(id: 'sho_7_2_a', questionId: 'sho_7_2', optionText: 'Kuita chinhu uine chinangwa chakavandika', isCorrect: true),
          QuestionOption(id: 'sho_7_2_b', questionId: 'sho_7_2', optionText: 'Kuchengeta imbwa mumusha', isCorrect: false),
          QuestionOption(id: 'sho_7_2_c', questionId: 'sho_7_2', optionText: 'Kutenga mupinyi mutsva', isCorrect: false),
          QuestionOption(id: 'sho_7_2_d', questionId: 'sho_7_2', optionText: 'Kuvhima kusango nevamwe', isCorrect: false),
        ],
      ),
      Question(
        id: 'sho_7_3',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Tsumo neMadimikira (Shona)',
        unit: 'Shona',
        concept: 'Shona Proverbs',
        difficulty: 'Medium',
        questionText:
            'Tsumo inoti "Kudzidza hakuperi" inoreva kuitei?',
        explanation:
            'Kuda kudzidza hakunganwi — vanhu vanogona kudzidza chero nguva dzavo dzose.',
        options: [
          QuestionOption(id: 'sho_7_3_a', questionId: 'sho_7_3', optionText: 'Kudzidza kunoenderera mberi upenyu hwose', isCorrect: true),
          QuestionOption(id: 'sho_7_3_b', questionId: 'sho_7_3', optionText: 'Kudzidza kunoita vanhu vapusa', isCorrect: false),
          QuestionOption(id: 'sho_7_3_c', questionId: 'sho_7_3', optionText: 'Tsumo inorevera vana bedzi', isCorrect: false),
          QuestionOption(id: 'sho_7_3_d', questionId: 'sho_7_3', optionText: 'Kudzidza kunopedza nguva', isCorrect: false),
        ],
      ),
      Question(
        id: 'sho_7_4',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Madimikira echiShona',
        unit: 'Shona',
        concept: 'Shona Comprehension',
        difficulty: 'Hard',
        questionText:
            'Ndezvipi zvimiro zvechishona (zvifananidzo) zvinobatsira mukunyora ngano?',
        explanation:
            'Zvifananidzo (similes) zvinoshandiswa kuenzanisa zvinhu zviviri zvine mufananidzo.',
        options: [
          QuestionOption(id: 'sho_7_4_a', questionId: 'sho_7_4', optionText: 'Zvifananidzo (similes ne metaphors)', isCorrect: true),
          QuestionOption(id: 'sho_7_4_b', questionId: 'sho_7_4', optionText: 'Mazita chete', isCorrect: false),
          QuestionOption(id: 'sho_7_4_c', questionId: 'sho_7_4', optionText: 'Nhamba dzepamusoro', isCorrect: false),
          QuestionOption(id: 'sho_7_4_d', questionId: 'sho_7_4', optionText: 'Mapinduriro chete', isCorrect: false),
        ],
      ),

      // ── Ndebele ───────────────────────────────────────────────────────────
      Question(
        id: 'nde_7_1',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Izaga nGezitsho (Ndebele)',
        unit: 'Ndebele',
        concept: 'Ndebele Proverbs',
        difficulty: 'Easy',
        questionText: 'Qedela isaga esithi: "Izandla ziyagezana ..."',
        explanation:
            'Isaga lesi sifundisa ngokuncedana nekuthathaneni kwabantu emphakathini.',
        options: [
          QuestionOption(id: 'nde_7_1_a', questionId: 'nde_7_1', optionText: 'kanye', isCorrect: true),
          QuestionOption(id: 'nde_7_1_b', questionId: 'nde_7_1', optionText: 'lezinye', isCorrect: false),
          QuestionOption(id: 'nde_7_1_c', questionId: 'nde_7_1', optionText: 'emakhaya', isCorrect: false),
          QuestionOption(id: 'nde_7_1_d', questionId: 'nde_7_1', optionText: 'ezibhakabhakeni', isCorrect: false),
        ],
      ),
      Question(
        id: 'nde_7_2',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Izitsho zesiNdebele',
        unit: 'Ndebele',
        concept: 'Ndebele Grammar',
        difficulty: 'Medium',
        questionText:
            'Yini incazelo yesitsho esithi "ukutshayela umthetho phansi"?',
        explanation:
            'Ukutshayela umthetho phansi kutsho ukwephula noma ukungalandeli umthetho.',
        options: [
          QuestionOption(id: 'nde_7_2_a', questionId: 'nde_7_2', optionText: 'Ukwephula noma ukungalandeli umthetho', isCorrect: true),
          QuestionOption(id: 'nde_7_2_b', questionId: 'nde_7_2', optionText: 'Ukubhala umthetho phansi', isCorrect: false),
          QuestionOption(id: 'nde_7_2_c', questionId: 'nde_7_2', optionText: 'Ukulalela abadala ngaso sonke isikhathi', isCorrect: false),
          QuestionOption(id: 'nde_7_2_d', questionId: 'nde_7_2', optionText: 'Ukugijima ngamandla enkundleni', isCorrect: false),
        ],
      ),
      Question(
        id: 'nde_7_3',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Izaga nGezitsho (Ndebele)',
        unit: 'Ndebele',
        concept: 'Ndebele Proverbs',
        difficulty: 'Medium',
        questionText:
            'Yini isaga esikhuluma ngokuthi "Indlela ibuzwa kwabaphambili"?',
        explanation:
            'Isaga lesi sikhuthaza ukubuza abadala noma abanolwazi ukukutshengisa indlela.',
        options: [
          QuestionOption(id: 'nde_7_3_a', questionId: 'nde_7_3', optionText: 'Buza abadala ukuze uthole iseluleko', isCorrect: true),
          QuestionOption(id: 'nde_7_3_b', questionId: 'nde_7_3', optionText: 'Hamba wedwa ungabuzi muntu', isCorrect: false),
          QuestionOption(id: 'nde_7_3_c', questionId: 'nde_7_3', optionText: 'Indlela iyaziwa ngabantwana', isCorrect: false),
          QuestionOption(id: 'nde_7_3_d', questionId: 'nde_7_3', optionText: 'Abaphambili abazi lutho', isCorrect: false),
        ],
      ),
      Question(
        id: 'nde_7_4',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Izitsho zesiNdebele',
        unit: 'Ndebele',
        concept: 'Ndebele Vocabulary',
        difficulty: 'Hard',
        questionText:
            'Yiluphi uhlobo lwezinkondlo ezibhalwa ngoLimi lwesiNdebele olusebenzisa imfanekiso yemvelo?',
        explanation:
            'Izinkondlo zemvelo (nature poetry) zisebenzisa izithombe zemvelo ukufinyelela inhloso yazo.',
        options: [
          QuestionOption(id: 'nde_7_4_a', questionId: 'nde_7_4', optionText: 'Izinkondlo zemvelo (nature poetry)', isCorrect: true),
          QuestionOption(id: 'nde_7_4_b', questionId: 'nde_7_4', optionText: 'Inoveli', isCorrect: false),
          QuestionOption(id: 'nde_7_4_c', questionId: 'nde_7_4', optionText: 'Indaba emfushane', isCorrect: false),
          QuestionOption(id: 'nde_7_4_d', questionId: 'nde_7_4', optionText: 'Ingxoxo', isCorrect: false),
        ],
      ),

      // ── Tonga ────────────────────────────────────────────────────────────
      Question(
        id: 'ton_7_1',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Tshisusu ne ZyaChitonga',
        unit: 'Tonga',
        concept: 'Tonga Grammar',
        difficulty: 'Easy',
        questionText: 'Mu Chitonga, mulimi ula lima ku ...?',
        explanation: 'Mulimi ula lima mu munda wakwe.',
        options: [
          QuestionOption(id: 'ton_7_1_a', questionId: 'ton_7_1', optionText: 'munda', isCorrect: true),
          QuestionOption(id: 'ton_7_1_b', questionId: 'ton_7_1', optionText: 'lwanje', isCorrect: false),
          QuestionOption(id: 'ton_7_1_c', questionId: 'ton_7_1', optionText: 'mulonga', isCorrect: false),
          QuestionOption(id: 'ton_7_1_d', questionId: 'ton_7_1', optionText: 'chibadela', isCorrect: false),
        ],
      ),
      Question(
        id: 'ton_7_2',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Language & Culture (Tonga)',
        unit: 'Tonga',
        concept: 'Tonga Culture',
        difficulty: 'Medium',
        questionText:
            'Kumaanzi aatola malwazi aamutuntuko, ncinzi tweelede kucita kaatana kunywa?',
        explanation: 'Kubeesa maanzi kulateleezya maanzi aasalala kucesa malwazi.',
        options: [
          QuestionOption(id: 'ton_7_2_a', questionId: 'ton_7_2', optionText: 'Kubeesa maanzi kaatana kunywa', isCorrect: true),
          QuestionOption(id: 'ton_7_2_b', questionId: 'ton_7_2', optionText: 'Kuleka maanzi aanguzu azuba', isCorrect: false),
          QuestionOption(id: 'ton_7_2_c', questionId: 'ton_7_2', optionText: 'Kubikka mchere mumaanzi', isCorrect: false),
          QuestionOption(id: 'ton_7_2_d', questionId: 'ton_7_2', optionText: 'Kunywa aafwambaana', isCorrect: false),
        ],
      ),
      Question(
        id: 'ton_7_3',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Tshisusu ne ZyaChitonga',
        unit: 'Tonga',
        concept: 'Tonga Proverbs',
        difficulty: 'Medium',
        questionText:
            'Nikuba bantu babede zyiiyo zyaChitonga, nzi nkamu yiimya tata?',
        explanation:
            'Muzyalo (family / clan) ngu nkamu iimya tata muChitonga.',
        options: [
          QuestionOption(id: 'ton_7_3_a', questionId: 'ton_7_3', optionText: 'Muzyalo (clan / family)', isCorrect: true),
          QuestionOption(id: 'ton_7_3_b', questionId: 'ton_7_3', optionText: 'Mulonga', isCorrect: false),
          QuestionOption(id: 'ton_7_3_c', questionId: 'ton_7_3', optionText: 'Chibadela', isCorrect: false),
          QuestionOption(id: 'ton_7_3_d', questionId: 'ton_7_3', optionText: 'Mweemba', isCorrect: false),
        ],
      ),
      Question(
        id: 'ton_7_4',
        grade: 7,
        subject: 'Indigenous Language',
        topic: 'Language & Culture (Tonga)',
        unit: 'Tonga',
        concept: 'Tonga Vocabulary',
        difficulty: 'Hard',
        questionText:
            'Mu Chitonga, "bana" kutsyomeka kuti bantu bali boobo. Nzi nsyomeko ya "bana baako"?',
        explanation:
            '"Bana baako" kutegwa your children / your children (plural possessive in Chitonga).',
        options: [
          QuestionOption(id: 'ton_7_4_a', questionId: 'ton_7_4', optionText: 'Your children (bana bako)', isCorrect: true),
          QuestionOption(id: 'ton_7_4_b', questionId: 'ton_7_4', optionText: 'My house', isCorrect: false),
          QuestionOption(id: 'ton_7_4_c', questionId: 'ton_7_4', optionText: 'Their cattle', isCorrect: false),
          QuestionOption(id: 'ton_7_4_d', questionId: 'ton_7_4', optionText: 'Our teacher', isCorrect: false),
        ],
      ),
    ];
  }
}
