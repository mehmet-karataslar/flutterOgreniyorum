class Module {
  final int id;
  final String title;
  final String description;
  final int weekNumber;
  final List<String> goals;
  final List<Topic> topics;
  final List<CodeExample> codeExamples;
  final List<String> resources;
  final Quiz quiz;
  final bool isCompleted;
  final double completionPercentage;

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.weekNumber,
    required this.goals,
    required this.topics,
    required this.codeExamples,
    required this.resources,
    required this.quiz,
    this.isCompleted = false,
    this.completionPercentage = 0.0,
  });

  Module copyWith({
    int? id,
    String? title,
    String? description,
    int? weekNumber,
    List<String>? goals,
    List<Topic>? topics,
    List<CodeExample>? codeExamples,
    List<String>? resources,
    Quiz? quiz,
    bool? isCompleted,
    double? completionPercentage,
  }) {
    return Module(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      weekNumber: weekNumber ?? this.weekNumber,
      goals: goals ?? this.goals,
      topics: topics ?? this.topics,
      codeExamples: codeExamples ?? this.codeExamples,
      resources: resources ?? this.resources,
      quiz: quiz ?? this.quiz,
      isCompleted: isCompleted ?? this.isCompleted,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'weekNumber': weekNumber,
      'goals': goals,
      'topics': topics.map((topic) => topic.toJson()).toList(),
      'codeExamples': codeExamples.map((example) => example.toJson()).toList(),
      'resources': resources,
      'quiz': quiz.toJson(),
      'isCompleted': isCompleted,
      'completionPercentage': completionPercentage,
    };
  }

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      weekNumber: json['weekNumber'],
      goals: List<String>.from(json['goals']),
      topics:
          (json['topics'] as List)
              .map((topic) => Topic.fromJson(topic))
              .toList(),
      codeExamples:
          (json['codeExamples'] as List)
              .map((example) => CodeExample.fromJson(example))
              .toList(),
      resources: List<String>.from(json['resources']),
      quiz: Quiz.fromJson(json['quiz']),
      isCompleted: json['isCompleted'] ?? false,
      completionPercentage: json['completionPercentage'] ?? 0.0,
    );
  }
}

class Topic {
  final String title;
  final String content;
  final List<String> keyPoints;
  final bool isCompleted;

  Topic({
    required this.title,
    required this.content,
    required this.keyPoints,
    this.isCompleted = false,
  });

  Topic copyWith({
    String? title,
    String? content,
    List<String>? keyPoints,
    bool? isCompleted,
  }) {
    return Topic(
      title: title ?? this.title,
      content: content ?? this.content,
      keyPoints: keyPoints ?? this.keyPoints,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'keyPoints': keyPoints,
      'isCompleted': isCompleted,
    };
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      title: json['title'],
      content: json['content'],
      keyPoints: List<String>.from(json['keyPoints']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class CodeExample {
  final String title;
  final String code;
  final String explanation;
  final String language;

  CodeExample({
    required this.title,
    required this.code,
    required this.explanation,
    this.language = 'dart',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'code': code,
      'explanation': explanation,
      'language': language,
    };
  }

  factory CodeExample.fromJson(Map<String, dynamic> json) {
    return CodeExample(
      title: json['title'],
      code: json['code'],
      explanation: json['explanation'],
      language: json['language'] ?? 'dart',
    );
  }
}

class Quiz {
  final int moduleId;
  final List<Question> questions;
  final double passScore;
  final int? userScore;
  final bool isCompleted;

  Quiz({
    required this.moduleId,
    required this.questions,
    this.passScore = 70.0,
    this.userScore,
    this.isCompleted = false,
  });

  Quiz copyWith({
    int? moduleId,
    List<Question>? questions,
    double? passScore,
    int? userScore,
    bool? isCompleted,
  }) {
    return Quiz(
      moduleId: moduleId ?? this.moduleId,
      questions: questions ?? this.questions,
      passScore: passScore ?? this.passScore,
      userScore: userScore ?? this.userScore,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'questions': questions.map((q) => q.toJson()).toList(),
      'passScore': passScore,
      'userScore': userScore,
      'isCompleted': isCompleted,
    };
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      moduleId: json['moduleId'],
      questions:
          (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
      passScore: json['passScore'] ?? 70.0,
      userScore: json['userScore'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class Question {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
    );
  }
}
