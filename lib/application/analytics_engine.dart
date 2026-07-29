import '../data/repositories/analytics_repository.dart';

class AnalyticsEngine {
  final AnalyticsRepository repository;

  AnalyticsEngine({AnalyticsRepository? repository})
      : repository = repository ?? AnalyticsRepository();

  Future<double> getOverallMastery() async {
    return await repository.getOverallAverageScore();
  }

  Future<int> getStreakDays() async {
    return await repository.getStudyStreakDays();
  }

  Future<Map<String, double>> getSubjectPerformance(int grade) async {
    return await repository.getSubjectPerformance(grade);
  }

  Future<List<String>> getWeakConcepts(int grade) async {
    return await repository.getWeakConcepts(grade: grade);
  }

  Future<List<String>> getStrongConcepts(int grade) async {
    return await repository.getStrongConcepts(grade: grade);
  }
}
