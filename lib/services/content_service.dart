import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  // Cache for loaded content
  final Map<String, ContentModule> _contentCache = {};

  /// Haftalık içerik yapısı
  static const Map<int, List<String>> weekModules = {
    1: [
      'variables_and_types',
      'operators',
      'control_flow',
      'collections',
      'functions',
    ],
    // Diğer haftalar henüz hazır değil - ilerleyen süreçte eklenecek
  };

  /// Belirli bir modülün içeriğini yükler
  Future<ContentModule> loadContentModule(int week, String moduleId) async {
    final cacheKey = 'week_${week}_$moduleId';

    // Cache'den kontrol et
    if (_contentCache.containsKey(cacheKey)) {
      print('Cache\'den yüklendi: $cacheKey');
      return _contentCache[cacheKey]!;
    }

    try {
      // JSON dosyasından yükle
      final String assetPath = 'assets/content/week_$week/$moduleId.json';
      print('JSON yükleniyor: $assetPath');

      final String data = await rootBundle.loadString(assetPath);
      print('JSON başarıyla yüklendi, boyut: ${data.length} karakter');

      final Map<String, dynamic> jsonData = json.decode(data);
      print('JSON parse edildi, modül: ${jsonData['title']}');

      final ContentModule module = ContentModule.fromJson(jsonData);
      print('ContentModule oluşturuldu: ${module.title}');

      // Cache'e kaydet
      _contentCache[cacheKey] = module;

      return module;
    } catch (e, stackTrace) {
      print('İçerik yüklenirken hata oluştu: $e');
      print('Stack trace: $stackTrace');
      // Fallback: boş modül döndür
      return ContentModule.createEmpty(week, moduleId);
    }
  }

  /// Bir haftanın tüm modüllerini yükler
  Future<List<ContentModule>> loadWeekModules(int week) async {
    final moduleIds = weekModules[week] ?? [];
    final List<ContentModule> modules = [];

    for (String moduleId in moduleIds) {
      try {
        final module = await loadContentModule(week, moduleId);
        modules.add(module);
      } catch (e) {
        print('Modül yüklenirken hata: $week/$moduleId - $e');
      }
    }

    // Sıraya göre sırala
    modules.sort((a, b) => a.order.compareTo(b.order));
    return modules;
  }

  /// Kullanıcının modül ilerlemesini kaydet
  Future<void> saveModuleProgress(
    String moduleId,
    ModuleProgress progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'module_progress_$moduleId';
    await prefs.setString(key, json.encode(progress.toJson()));
  }

  /// Modül ilerlemesini getir
  Future<ModuleProgress> getModuleProgress(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'module_progress_$moduleId';
    final progressJson = prefs.getString(key);

    if (progressJson != null) {
      final Map<String, dynamic> data = json.decode(progressJson);
      return ModuleProgress.fromJson(data);
    }

    return ModuleProgress.initial(moduleId);
  }

  /// Tüm haftalık ilerlemeleri getir
  Future<Map<int, WeekProgress>> getAllWeekProgress() async {
    final Map<int, WeekProgress> weekProgressMap = {};

    // Sadece mevcut haftalar için ilerleme hesapla
    for (int week in weekModules.keys) {
      final modules = await loadWeekModules(week);
      int completedModules = 0;
      int totalModules = modules.length;

      for (ContentModule module in modules) {
        final progress = await getModuleProgress(module.moduleId);
        if (progress.isCompleted) {
          completedModules++;
        }
      }

      weekProgressMap[week] = WeekProgress(
        week: week,
        totalModules: totalModules,
        completedModules: completedModules,
        progressPercentage: totalModules > 0
            ? (completedModules / totalModules) * 100
            : 0,
      );
    }

    return weekProgressMap;
  }

  /// Hafta adlarını getir
  static String getWeekTitle(int week) {
    const weekTitles = {
      1: 'Dart Temelleri',
      2: 'Nesne Yönelimli Programlama',
      3: 'Asenkron Programlama',
      4: 'Flutter\'a Giriş',
      5: 'Flutter Temel Widget\'ları',
      6: 'Durum Yönetimi',
      7: 'Navigasyon ve Çoklu Sayfa',
      8: 'HTTP ve Backend Entegrasyonu',
      9: 'Lokal Veri Depolama',
      10: 'İleri Seviye Konular',
      11: 'Test ve Yayınlama',
    };

    return weekTitles[week] ?? 'Hafta $week';
  }

  /// Modül başlık listesini getir
  static List<String> getModuleTitles(int week) {
    const moduleTitles = {
      1: [
        'Değişkenler ve Veri Tipleri',
        'Operatörler',
        'Kontrol Akışı',
        'Koleksiyonlar',
        'Fonksiyonlar',
      ],
      2: [
        'Sınıflar ve Nesneler',
        'Yapıcı Metotlar',
        'Kalıtım',
        'Soyut Sınıflar ve Arayüzler',
        'Mixin ve İleri Kavramlar',
      ],
      // Diğer haftalar da eklenebilir...
    };

    return moduleTitles[week] ?? [];
  }

  /// Arama fonksiyonu
  Future<List<SearchResult>> searchContent(String query) async {
    final List<SearchResult> results = [];
    query = query.toLowerCase();

    for (int week = 1; week <= 11; week++) {
      final modules = await loadWeekModules(week);

      for (ContentModule module in modules) {
        // Başlıkta ara
        if (module.title.toLowerCase().contains(query)) {
          results.add(
            SearchResult(
              moduleId: module.moduleId,
              week: week,
              title: module.title,
              snippet: module.description,
              type: SearchResultType.title,
            ),
          );
        }

        // İçerikte ara
        for (ContentSection section in module.sections) {
          if (section.content.toLowerCase().contains(query)) {
            results.add(
              SearchResult(
                moduleId: module.moduleId,
                week: week,
                title: '${module.title} - ${section.title}',
                snippet: _extractSnippet(section.content, query),
                type: SearchResultType.content,
              ),
            );
          }
        }
      }
    }

    return results;
  }

  String _extractSnippet(String content, String query) {
    final index = content.toLowerCase().indexOf(query.toLowerCase());
    if (index == -1) return content.substring(0, 100);

    final start = (index - 50).clamp(0, content.length);
    final end = (index + 100).clamp(0, content.length);

    return content.substring(start, end);
  }
}

/// İçerik modülü modeli
class ContentModule {
  final String moduleId;
  final String title;
  final int week;
  final int order;
  final String estimatedTime;
  final String difficulty;
  final String description;
  final ContentIntroduction introduction;
  final List<ContentSection> sections;
  final ModuleQuiz? quiz;
  final List<PracticeExercise> practiceExercises;
  final ModuleSummary summary;

  ContentModule({
    required this.moduleId,
    required this.title,
    required this.week,
    required this.order,
    required this.estimatedTime,
    required this.difficulty,
    required this.description,
    required this.introduction,
    required this.sections,
    this.quiz,
    required this.practiceExercises,
    required this.summary,
  });

  factory ContentModule.fromJson(Map<String, dynamic> json) {
    return ContentModule(
      moduleId: json['moduleId'],
      title: json['title'],
      week: json['week'],
      order: json['order'],
      estimatedTime: json['estimatedTime'],
      difficulty: json['difficulty'],
      description: json['description'],
      introduction: ContentIntroduction.fromJson(json['introduction']),
      sections: (json['sections'] as List)
          .map((s) => ContentSection.fromJson(s))
          .toList(),
      quiz: json['quiz'] != null ? ModuleQuiz.fromJson(json['quiz']) : null,
      practiceExercises: (json['practiceExercises'] as List)
          .map((e) => PracticeExercise.fromJson(e))
          .toList(),
      summary: ModuleSummary.fromJson(json['summary']),
    );
  }

  static ContentModule createEmpty(int week, String moduleId) {
    return ContentModule(
      moduleId: moduleId,
      title: 'Modül Bulunamadı',
      week: week,
      order: 0,
      estimatedTime: '0 dakika',
      difficulty: 'unknown',
      description: 'Bu modül henüz hazır değil.',
      introduction: ContentIntroduction.empty(),
      sections: [],
      practiceExercises: [],
      summary: ModuleSummary.empty(),
    );
  }
}

/// İçerik giriş bölümü
class ContentIntroduction {
  final String title;
  final String content;
  final List<String> keyPoints;

  ContentIntroduction({
    required this.title,
    required this.content,
    required this.keyPoints,
  });

  factory ContentIntroduction.fromJson(Map<String, dynamic> json) {
    return ContentIntroduction(
      title: json['title'],
      content: json['content'],
      keyPoints: List<String>.from(json['keyPoints']),
    );
  }

  static ContentIntroduction empty() {
    return ContentIntroduction(title: '', content: '', keyPoints: []);
  }
}

/// İçerik bölümü
class ContentSection {
  final String id;
  final String title;
  final String content;
  final List<ContentSubsection> subsections;
  final BestPractices? bestPractices;

  ContentSection({
    required this.id,
    required this.title,
    required this.content,
    required this.subsections,
    this.bestPractices,
  });

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    return ContentSection(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      subsections:
          (json['subsections'] as List?)
              ?.map((s) => ContentSubsection.fromJson(s))
              .toList() ??
          [],
      bestPractices: json['bestPractices'] != null
          ? BestPractices.fromJson(json['bestPractices'])
          : null,
    );
  }
}

/// İçerik alt bölümü
class ContentSubsection {
  final String id;
  final String title;
  final String content;
  final List<CodeExample> codeExamples;
  final InteractiveExercise? interactiveExercise;
  final List<String> keyPoints;

  ContentSubsection({
    required this.id,
    required this.title,
    required this.content,
    required this.codeExamples,
    this.interactiveExercise,
    required this.keyPoints,
  });

  factory ContentSubsection.fromJson(Map<String, dynamic> json) {
    return ContentSubsection(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      codeExamples:
          (json['codeExamples'] as List?)
              ?.map((e) => CodeExample.fromJson(e))
              .toList() ??
          [],
      interactiveExercise: json['interactiveExercise'] != null
          ? InteractiveExercise.fromJson(json['interactiveExercise'])
          : null,
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
    );
  }
}

/// Kod örneği
class CodeExample {
  final String title;
  final String code;
  final String explanation;
  final String? output;
  final String language;

  CodeExample({
    required this.title,
    required this.code,
    required this.explanation,
    this.output,
    this.language = 'dart',
  });

  factory CodeExample.fromJson(Map<String, dynamic> json) {
    return CodeExample(
      title: json['title'],
      code: json['code'],
      explanation: json['explanation'],
      output: json['output'],
      language: json['language'] ?? 'dart',
    );
  }
}

/// İnteraktif egzersiz
class InteractiveExercise {
  final String question;
  final String hint;
  final String solution;

  InteractiveExercise({
    required this.question,
    required this.hint,
    required this.solution,
  });

  factory InteractiveExercise.fromJson(Map<String, dynamic> json) {
    return InteractiveExercise(
      question: json['question'],
      hint: json['hint'],
      solution: json['solution'],
    );
  }
}

/// En iyi uygulamalar
class BestPractices {
  final String title;
  final String content;
  final List<String> examples;

  BestPractices({
    required this.title,
    required this.content,
    required this.examples,
  });

  factory BestPractices.fromJson(Map<String, dynamic> json) {
    return BestPractices(
      title: json['title'],
      content: json['content'],
      examples: List<String>.from(json['examples']),
    );
  }
}

/// Pratik egzersiz
class PracticeExercise {
  final String title;
  final String description;
  final List<String> instructions;
  final String? starterCode;
  final String solution;
  final String difficulty;

  PracticeExercise({
    required this.title,
    required this.description,
    required this.instructions,
    this.starterCode,
    required this.solution,
    required this.difficulty,
  });

  factory PracticeExercise.fromJson(Map<String, dynamic> json) {
    return PracticeExercise(
      title: json['title'],
      description: json['description'],
      instructions: List<String>.from(json['instructions']),
      starterCode: json['starterCode'],
      solution: json['solution'],
      difficulty: json['difficulty'],
    );
  }
}

/// Modül özeti
class ModuleSummary {
  final String title;
  final List<String> keyTakeaways;
  final String? nextModule;

  ModuleSummary({
    required this.title,
    required this.keyTakeaways,
    this.nextModule,
  });

  factory ModuleSummary.fromJson(Map<String, dynamic> json) {
    return ModuleSummary(
      title: json['title'],
      keyTakeaways: List<String>.from(json['keyTakeaways']),
      nextModule: json['nextModule'],
    );
  }

  static ModuleSummary empty() {
    return ModuleSummary(title: 'Özet', keyTakeaways: []);
  }
}

/// Modül ilerlemesi
class ModuleProgress {
  final String moduleId;
  final bool isCompleted;
  final Map<String, bool> sectionProgress;
  final int currentSectionIndex;
  final DateTime? lastAccessedAt;
  final Duration timeSpent;

  ModuleProgress({
    required this.moduleId,
    required this.isCompleted,
    required this.sectionProgress,
    required this.currentSectionIndex,
    this.lastAccessedAt,
    required this.timeSpent,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['moduleId'],
      isCompleted: json['isCompleted'],
      sectionProgress: Map<String, bool>.from(json['sectionProgress']),
      currentSectionIndex: json['currentSectionIndex'],
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'])
          : null,
      timeSpent: Duration(seconds: json['timeSpentSeconds'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'isCompleted': isCompleted,
      'sectionProgress': sectionProgress,
      'currentSectionIndex': currentSectionIndex,
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'timeSpentSeconds': timeSpent.inSeconds,
    };
  }

  static ModuleProgress initial(String moduleId) {
    return ModuleProgress(
      moduleId: moduleId,
      isCompleted: false,
      sectionProgress: {},
      currentSectionIndex: 0,
      timeSpent: Duration.zero,
    );
  }
}

/// Haftalık ilerleme
class WeekProgress {
  final int week;
  final int totalModules;
  final int completedModules;
  final double progressPercentage;

  WeekProgress({
    required this.week,
    required this.totalModules,
    required this.completedModules,
    required this.progressPercentage,
  });
}

/// Arama sonucu
class SearchResult {
  final String moduleId;
  final int week;
  final String title;
  final String snippet;
  final SearchResultType type;

  SearchResult({
    required this.moduleId,
    required this.week,
    required this.title,
    required this.snippet,
    required this.type,
  });
}

enum SearchResultType { title, content, code }

/// Modül quiz'i
class ModuleQuiz {
  final List<QuizQuestion> questions;

  ModuleQuiz({required this.questions});

  factory ModuleQuiz.fromJson(Map<String, dynamic> json) {
    return ModuleQuiz(
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
    );
  }
}

class QuizQuestion {
  final int id;
  final String question;
  final String type;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      type: json['type'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
    );
  }
}
