// Bu servis, kullanıcının öğrenme ilerlemesini takip etmek için kullanılır
// Modül tamamlama, quiz sonuçları ve genel ilerleme hesaplamalarını yapar

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress.dart';
import 'data_service.dart';

class ProgressService {
  final DataService _dataService = DataService();

  // Singleton pattern - tek instance kullanımı
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  // StreamController ile ilerleme değişikliklerini dinleyebilir hale getiriyoruz
  final StreamController<Progress> _progressController =
      StreamController<Progress>.broadcast();
  Stream<Progress> get progressStream => _progressController.stream;

  // Kullanıcının mevcut ilerlemesini getirir
  Future<Progress> getCurrentProgress() async {
    return await _dataService.getUserProgress();
  }

  // Bir modülü tamamlandı olarak işaretler
  Future<void> completeModule(int moduleId) async {
    final progress = await getCurrentProgress();
    final moduleProgress =
        progress.moduleProgress[moduleId] ?? ModuleProgress.initial(moduleId);

    // Modülü tamamlandı olarak güncelle
    final updatedModuleProgress = moduleProgress.copyWith(
      isCompleted: true,
      completionPercentage: 100.0,
      completedAt: DateTime.now(),
    );

    await _dataService.updateModuleProgress(moduleId, updatedModuleProgress);

    // Güncellenmiş ilerlemeyi broadcast et
    final updatedProgress = await getCurrentProgress();
    _progressController.add(updatedProgress);
  }

  // Bir topic'i tamamlandı olarak işaretler
  Future<void> completeTopic(int moduleId, String topicTitle) async {
    final progress = await getCurrentProgress();
    final moduleProgress =
        progress.moduleProgress[moduleId] ?? ModuleProgress.initial(moduleId);

    // Topic'i tamamlandı olarak güncelle
    final updatedTopicsCompleted = Map<String, bool>.from(
      moduleProgress.topicsCompleted,
    );
    updatedTopicsCompleted[topicTitle] = true;

    // Tamamlanan topic sayısına göre completion percentage hesapla
    final module = _dataService.getModuleById(moduleId);
    if (module != null) {
      final totalTopics = module.topics.length;
      final completedTopics =
          updatedTopicsCompleted.values.where((completed) => completed).length;
      final completionPercentage = (completedTopics / totalTopics) * 100;

      final updatedModuleProgress = moduleProgress.copyWith(
        topicsCompleted: updatedTopicsCompleted,
        completionPercentage: completionPercentage,
        isCompleted: completionPercentage == 100.0,
      );

      await _dataService.updateModuleProgress(moduleId, updatedModuleProgress);
    }

    // Güncellenmiş ilerlemeyi broadcast et
    final updatedProgress = await getCurrentProgress();
    _progressController.add(updatedProgress);
  }

  // Quiz sonucunu kaydeder
  Future<void> saveQuizResult(
    int moduleId,
    int score,
    int totalQuestions,
  ) async {
    final progress = await getCurrentProgress();
    final moduleProgress =
        progress.moduleProgress[moduleId] ?? ModuleProgress.initial(moduleId);

    // Quiz başarı yüzdesini hesapla
    final scorePercentage = (score / totalQuestions) * 100;

    // Quiz sonucunu kaydet
    final updatedModuleProgress = moduleProgress.copyWith(
      isQuizCompleted: true,
      quizScore: score,
      // Eğer quiz başarılıysa (%70 ve üzeri) modülü tamamlanmış olarak işaretle
      isCompleted: scorePercentage >= 70,
      completedAt: scorePercentage >= 70 ? DateTime.now() : null,
      completionPercentage:
          scorePercentage >= 70 ? 100.0 : moduleProgress.completionPercentage,
    );

    await _dataService.updateModuleProgress(moduleId, updatedModuleProgress);

    // Güncellenmiş ilerlemeyi broadcast et
    final updatedProgress = await getCurrentProgress();
    _progressController.add(updatedProgress);
  }

  // Bir sonraki haftaya geçiş yapar
  Future<void> advanceToNextWeek() async {
    final progress = await getCurrentProgress();
    if (progress.currentWeek < progress.totalWeeks) {
      final updatedProgress = progress.copyWith(
        currentWeek: progress.currentWeek + 1,
        lastUpdated: DateTime.now(),
      );

      await _dataService.saveUserProgress(updatedProgress);
      _progressController.add(updatedProgress);
    }
  }

  // Genel ilerleme yüzdesini hesaplar
  Future<double> calculateOverallProgress() async {
    final progress = await getCurrentProgress();
    final completedModules =
        progress.moduleProgress.values
            .where((moduleProgress) => moduleProgress.isCompleted)
            .length;

    return (completedModules / progress.totalWeeks) * 100;
  }

  // Tamamlanan quiz sayısını hesaplar
  Future<int> getCompletedQuizCount() async {
    final progress = await getCurrentProgress();
    return progress.moduleProgress.values
        .where((moduleProgress) => moduleProgress.isQuizCompleted)
        .length;
  }

  // Tamamlanan topic sayısını hesaplar
  Future<int> getCompletedTopicCount() async {
    final progress = await getCurrentProgress();
    int totalCompletedTopics = 0;

    for (final moduleProgress in progress.moduleProgress.values) {
      totalCompletedTopics +=
          moduleProgress.topicsCompleted.values
              .where((completed) => completed)
              .length;
    }

    return totalCompletedTopics;
  }

  // İlerleme verilerini sıfırlar (reset)
  Future<void> resetProgress() async {
    final initialProgress = Progress.initial();
    await _dataService.saveUserProgress(initialProgress);
    _progressController.add(initialProgress);
  }

  // Servisi temizler
  void dispose() {
    _progressController.close();
  }
}
