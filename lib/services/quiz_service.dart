import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  // Cache for loaded questions
  final Map<int, QuizData> _questionsCache = {};

  /// Belirli bir modülün quiz verilerini yükler
  Future<QuizData> loadQuizForModule(int moduleId) async {
    // Cache'den kontrol et
    if (_questionsCache.containsKey(moduleId)) {
      return _questionsCache[moduleId]!;
    }

    try {
      // JSON dosyasından yükle
      final String data = await rootBundle.loadString(
        'assets/questions/module_$moduleId.json',
      );
      final Map<String, dynamic> jsonData = json.decode(data);

      final QuizData quizData = QuizData.fromJson(jsonData);

      // Cache'e kaydet
      _questionsCache[moduleId] = quizData;

      return quizData;
    } catch (e) {
      print('Quiz yüklenirken hata oluştu: $e');
      // Fallback: boş quiz döndür
      return QuizData(
        moduleId: moduleId,
        moduleName: 'Modül $moduleId',
        questions: [],
      );
    }
  }

  /// Rastgele soru seçimi yapar (belirli sayıda)
  List<QuizQuestion> selectRandomQuestions(QuizData quizData, int count) {
    if (quizData.questions.length <= count) {
      return quizData.questions;
    }

    final random = Random();
    final selectedQuestions = <QuizQuestion>[];
    final availableQuestions = List<QuizQuestion>.from(quizData.questions);

    for (int i = 0; i < count; i++) {
      final randomIndex = random.nextInt(availableQuestions.length);
      selectedQuestions.add(availableQuestions.removeAt(randomIndex));
    }

    return selectedQuestions;
  }

  /// Zorluk seviyesine göre soru seçimi
  List<QuizQuestion> selectQuestionsByDifficulty(
    QuizData quizData,
    String difficulty,
    int count,
  ) {
    final filteredQuestions = quizData.questions
        .where((q) => q.difficulty == difficulty)
        .toList();

    if (filteredQuestions.length <= count) {
      return filteredQuestions;
    }

    final random = Random();
    final selectedQuestions = <QuizQuestion>[];
    final availableQuestions = List<QuizQuestion>.from(filteredQuestions);

    for (int i = 0; i < count; i++) {
      final randomIndex = random.nextInt(availableQuestions.length);
      selectedQuestions.add(availableQuestions.removeAt(randomIndex));
    }

    return selectedQuestions;
  }

  /// Karışık zorluk seviyesinde soru seçimi
  List<QuizQuestion> selectMixedDifficultyQuestions(
    QuizData quizData,
    int totalCount,
  ) {
    final easy = selectQuestionsByDifficulty(quizData, 'easy', totalCount ~/ 2);
    final medium = selectQuestionsByDifficulty(
      quizData,
      'medium',
      totalCount ~/ 3,
    );
    final hard = selectQuestionsByDifficulty(quizData, 'hard', totalCount ~/ 6);

    final mixedQuestions = <QuizQuestion>[];
    mixedQuestions.addAll(easy);
    mixedQuestions.addAll(medium);
    mixedQuestions.addAll(hard);

    // Eğer yeterli soru yoksa, rastgele ekle
    if (mixedQuestions.length < totalCount) {
      final remaining = totalCount - mixedQuestions.length;
      final availableQuestions = quizData.questions
          .where((q) => !mixedQuestions.contains(q))
          .toList();

      final additional = selectRandomQuestions(
        QuizData(
          moduleId: quizData.moduleId,
          moduleName: quizData.moduleName,
          questions: availableQuestions,
        ),
        remaining,
      );

      mixedQuestions.addAll(additional);
    }

    // Soruları karıştır
    mixedQuestions.shuffle();
    return mixedQuestions.take(totalCount).toList();
  }

  /// Quiz sonucunu hesaplar
  QuizResult calculateQuizResult(
    List<QuizQuestion> questions,
    Map<int, int> userAnswers,
  ) {
    int correctAnswers = 0;
    int totalPoints = 0;
    int earnedPoints = 0;

    for (final question in questions) {
      totalPoints += question.points;

      if (userAnswers.containsKey(question.id) &&
          userAnswers[question.id] == question.correctAnswer) {
        correctAnswers++;
        earnedPoints += question.points;
      }
    }

    final percentage = (correctAnswers / questions.length) * 100;
    final passed = percentage >= 70.0; // Geçme notu %70

    return QuizResult(
      totalQuestions: questions.length,
      correctAnswers: correctAnswers,
      wrongAnswers: questions.length - correctAnswers,
      totalPoints: totalPoints,
      earnedPoints: earnedPoints,
      percentage: percentage,
      passed: passed,
      userAnswers: userAnswers,
    );
  }

  /// Quiz sonucunu kaydet
  Future<void> saveQuizResult(int moduleId, QuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_result_module_$moduleId';
    await prefs.setString(key, json.encode(result.toJson()));
  }

  /// Kayıtlı quiz sonucunu getir
  Future<QuizResult?> getQuizResult(int moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'quiz_result_module_$moduleId';
    final resultJson = prefs.getString(key);

    if (resultJson != null) {
      final Map<String, dynamic> data = json.decode(resultJson);
      return QuizResult.fromJson(data);
    }

    return null;
  }

  /// Tüm quiz sonuçlarını getir
  Future<Map<int, QuizResult>> getAllQuizResults() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, QuizResult> results = {};

    for (int moduleId = 1; moduleId <= 11; moduleId++) {
      final result = await getQuizResult(moduleId);
      if (result != null) {
        results[moduleId] = result;
      }
    }

    return results;
  }

  /// Quiz istatistikleri
  Future<QuizStatistics> getQuizStatistics() async {
    final results = await getAllQuizResults();

    if (results.isEmpty) {
      return QuizStatistics(
        totalQuizzesTaken: 0,
        totalQuizzesPassed: 0,
        averageScore: 0.0,
        totalPointsEarned: 0,
        bestScore: 0.0,
        worstScore: 0.0,
      );
    }

    final totalQuizzes = results.length;
    final passedQuizzes = results.values.where((r) => r.passed).length;
    final totalPoints = results.values.fold(
      0,
      (sum, r) => sum + r.earnedPoints,
    );
    final averageScore =
        results.values.fold(0.0, (sum, r) => sum + r.percentage) / totalQuizzes;
    final bestScore = results.values.fold(
      0.0,
      (max, r) => r.percentage > max ? r.percentage : max,
    );
    final worstScore = results.values.fold(
      100.0,
      (min, r) => r.percentage < min ? r.percentage : min,
    );

    return QuizStatistics(
      totalQuizzesTaken: totalQuizzes,
      totalQuizzesPassed: passedQuizzes,
      averageScore: averageScore,
      totalPointsEarned: totalPoints,
      bestScore: bestScore,
      worstScore: worstScore,
    );
  }
}

/// Quiz verileri modeli
class QuizData {
  final int moduleId;
  final String moduleName;
  final List<QuizQuestion> questions;

  QuizData({
    required this.moduleId,
    required this.moduleName,
    required this.questions,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      moduleId: json['moduleId'],
      moduleName: json['moduleName'],
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'moduleName': moduleName,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

/// Quiz sorusu modeli
class QuizQuestion {
  final int id;
  final String question;
  final String type;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String difficulty;
  final int points;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
    required this.points,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      type: json['type'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
      difficulty: json['difficulty'],
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'points': points,
    };
  }
}

/// Quiz sonucu modeli
class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalPoints;
  final int earnedPoints;
  final double percentage;
  final bool passed;
  final Map<int, int> userAnswers;

  QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalPoints,
    required this.earnedPoints,
    required this.percentage,
    required this.passed,
    required this.userAnswers,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      wrongAnswers: json['wrongAnswers'],
      totalPoints: json['totalPoints'],
      earnedPoints: json['earnedPoints'],
      percentage: json['percentage'].toDouble(),
      passed: json['passed'],
      userAnswers: Map<int, int>.from(json['userAnswers']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'totalPoints': totalPoints,
      'earnedPoints': earnedPoints,
      'percentage': percentage,
      'passed': passed,
      'userAnswers': userAnswers,
    };
  }
}

/// Quiz istatistikleri modeli
class QuizStatistics {
  final int totalQuizzesTaken;
  final int totalQuizzesPassed;
  final double averageScore;
  final int totalPointsEarned;
  final double bestScore;
  final double worstScore;

  QuizStatistics({
    required this.totalQuizzesTaken,
    required this.totalQuizzesPassed,
    required this.averageScore,
    required this.totalPointsEarned,
    required this.bestScore,
    required this.worstScore,
  });

  double get passRate => totalQuizzesTaken > 0
      ? (totalQuizzesPassed / totalQuizzesTaken) * 100
      : 0.0;
}
