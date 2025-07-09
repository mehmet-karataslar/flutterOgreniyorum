class Progress {
  final int currentWeek;
  final int totalWeeks;
  final double overallProgress;
  final Map<int, ModuleProgress> moduleProgress;
  final int totalQuizzesPassed;
  final int totalTopicsCompleted;
  final DateTime startDate;
  final DateTime? lastUpdated;

  Progress({
    required this.currentWeek,
    required this.totalWeeks,
    required this.overallProgress,
    required this.moduleProgress,
    required this.totalQuizzesPassed,
    required this.totalTopicsCompleted,
    required this.startDate,
    this.lastUpdated,
  });

  Progress copyWith({
    int? currentWeek,
    int? totalWeeks,
    double? overallProgress,
    Map<int, ModuleProgress>? moduleProgress,
    int? totalQuizzesPassed,
    int? totalTopicsCompleted,
    DateTime? startDate,
    DateTime? lastUpdated,
  }) {
    return Progress(
      currentWeek: currentWeek ?? this.currentWeek,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      overallProgress: overallProgress ?? this.overallProgress,
      moduleProgress: moduleProgress ?? this.moduleProgress,
      totalQuizzesPassed: totalQuizzesPassed ?? this.totalQuizzesPassed,
      totalTopicsCompleted: totalTopicsCompleted ?? this.totalTopicsCompleted,
      startDate: startDate ?? this.startDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWeek': currentWeek,
      'totalWeeks': totalWeeks,
      'overallProgress': overallProgress,
      'moduleProgress': moduleProgress.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
      'totalQuizzesPassed': totalQuizzesPassed,
      'totalTopicsCompleted': totalTopicsCompleted,
      'startDate': startDate.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      currentWeek: json['currentWeek'],
      totalWeeks: json['totalWeeks'],
      overallProgress: json['overallProgress'],
      moduleProgress: (json['moduleProgress'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(int.parse(key), ModuleProgress.fromJson(value)),
      ),
      totalQuizzesPassed: json['totalQuizzesPassed'],
      totalTopicsCompleted: json['totalTopicsCompleted'],
      startDate: DateTime.parse(json['startDate']),
      lastUpdated:
          json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'])
              : null,
    );
  }

  factory Progress.initial() {
    return Progress(
      currentWeek: 1,
      totalWeeks: 11,
      overallProgress: 0.0,
      moduleProgress: {},
      totalQuizzesPassed: 0,
      totalTopicsCompleted: 0,
      startDate: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }
}

class ModuleProgress {
  final int moduleId;
  final bool isCompleted;
  final double completionPercentage;
  final bool isQuizCompleted;
  final int? quizScore;
  final Map<String, bool> topicsCompleted;
  final DateTime? completedAt;

  ModuleProgress({
    required this.moduleId,
    required this.isCompleted,
    required this.completionPercentage,
    required this.isQuizCompleted,
    required this.topicsCompleted,
    this.quizScore,
    this.completedAt,
  });

  ModuleProgress copyWith({
    int? moduleId,
    bool? isCompleted,
    double? completionPercentage,
    bool? isQuizCompleted,
    int? quizScore,
    Map<String, bool>? topicsCompleted,
    DateTime? completedAt,
  }) {
    return ModuleProgress(
      moduleId: moduleId ?? this.moduleId,
      isCompleted: isCompleted ?? this.isCompleted,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      isQuizCompleted: isQuizCompleted ?? this.isQuizCompleted,
      quizScore: quizScore ?? this.quizScore,
      topicsCompleted: topicsCompleted ?? this.topicsCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'isCompleted': isCompleted,
      'completionPercentage': completionPercentage,
      'isQuizCompleted': isQuizCompleted,
      'quizScore': quizScore,
      'topicsCompleted': topicsCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['moduleId'],
      isCompleted: json['isCompleted'],
      completionPercentage: json['completionPercentage'],
      isQuizCompleted: json['isQuizCompleted'],
      quizScore: json['quizScore'],
      topicsCompleted: Map<String, bool>.from(json['topicsCompleted']),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
    );
  }

  factory ModuleProgress.initial(int moduleId) {
    return ModuleProgress(
      moduleId: moduleId,
      isCompleted: false,
      completionPercentage: 0.0,
      isQuizCompleted: false,
      topicsCompleted: {},
    );
  }
}
