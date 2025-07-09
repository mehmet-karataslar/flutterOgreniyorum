// İstatistikler ekranı - kullanıcının öğrenme ilerlemesini detaylı olarak gösterir
// Tamamlanan modüller, quiz sonuçları, genel performans ve zaman takibi içerir

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/progress.dart';
import '../models/module.dart';
import '../services/progress_service.dart';
import '../services/data_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ProgressService _progressService = ProgressService();
  final DataService _dataService = DataService();

  Progress? _progress;
  List<Module> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final progress = await _progressService.getCurrentProgress();
      final modules = await _dataService.getAllModules();

      setState(() {
        _progress = progress;
        _modules = modules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'İstatistikler',
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_progress == null) {
      return const Center(child: Text('Veri yüklenirken hata oluştu'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genel İlerleme Özeti
            _buildOverallProgressCard(),
            const SizedBox(height: 16),

            // Haftalık İlerleme
            _buildWeeklyProgressCard(),
            const SizedBox(height: 16),

            // Quiz Performansı
            _buildQuizPerformanceCard(),
            const SizedBox(height: 16),

            // Modül Detayları
            _buildModuleDetailsCard(),
            const SizedBox(height: 16),

            // Başarı Rozetleri
            _buildAchievementsCard(),
          ],
        ),
      ),
    );
  }

  // Genel ilerleme kartı
  Widget _buildOverallProgressCard() {
    final completedModules = _progress!.moduleProgress.values
        .where((mp) => mp.isCompleted)
        .length;
    final totalModules = _modules.length;
    final overallProgress = totalModules > 0
        ? (completedModules / totalModules) * 100
        : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[600]!, Colors.blue[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Genel İlerleme',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              CircularPercentIndicator(
                radius: 60,
                lineWidth: 10,
                animation: true,
                percent: overallProgress / 100,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${overallProgress.toInt()}%',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$completedModules/$totalModules',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                progressColor: Colors.white,
                backgroundColor: Colors.white24,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Tamamlanan\nModüller',
                    '$completedModules',
                    Icons.check_circle,
                  ),
                  _buildStatItem(
                    'Toplam\nModüller',
                    '$totalModules',
                    Icons.library_books,
                  ),
                  _buildStatItem(
                    'Mevcut\nHafta',
                    '${_progress!.currentWeek}',
                    Icons.calendar_today,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Haftalık ilerleme kartı
  Widget _buildWeeklyProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haftalık İlerleme',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // Haftalık ilerleme çubuğu
            LinearPercentIndicator(
              animation: true,
              lineHeight: 20,
              percent: _progress!.currentWeek / _progress!.totalWeeks,
              center: Text(
                'Hafta ${_progress!.currentWeek} / ${_progress!.totalWeeks}',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              progressColor: Colors.green[600],
              backgroundColor: Colors.grey[300],
              barRadius: const Radius.circular(10),
            ),
            const SizedBox(height: 16),

            // Haftalık detaylar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeeklyStatItem(
                  'Kalan\nHafta',
                  '${_progress!.totalWeeks - _progress!.currentWeek}',
                  Colors.orange,
                ),
                _buildWeeklyStatItem(
                  'Başlangıç\nTarihi',
                  _formatDate(_progress!.startDate),
                  Colors.blue,
                ),
                _buildWeeklyStatItem(
                  'Son\nGüncelleme',
                  _formatDate(_progress!.lastUpdated ?? DateTime.now()),
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Quiz performansı kartı
  Widget _buildQuizPerformanceCard() {
    final completedQuizzes = _progress!.moduleProgress.values
        .where((mp) => mp.isQuizCompleted)
        .length;
    final totalQuizzes = _modules.length;
    final averageScore = _calculateAverageQuizScore();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Performansı',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Quiz tamamlama oranı
                Expanded(
                  child: Column(
                    children: [
                      CircularPercentIndicator(
                        radius: 40,
                        lineWidth: 6,
                        animation: true,
                        percent: totalQuizzes > 0
                            ? completedQuizzes / totalQuizzes
                            : 0,
                        center: Text(
                          '$completedQuizzes/$totalQuizzes',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        progressColor: Colors.purple[600]!,
                        backgroundColor: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tamamlanan\nQuiz',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Ortalama skor
                Expanded(
                  child: Column(
                    children: [
                      CircularPercentIndicator(
                        radius: 40,
                        lineWidth: 6,
                        animation: true,
                        percent: averageScore / 100,
                        center: Text(
                          '${averageScore.toInt()}%',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        progressColor: Colors.orange[600]!,
                        backgroundColor: Colors.grey[300]!,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ortalama\nSkor',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quiz detayları
            if (completedQuizzes > 0) ...[
              Text(
                'Quiz Detayları',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),

              ..._modules
                  .where((module) {
                    final moduleProgress = _progress!.moduleProgress[module.id];
                    return moduleProgress != null &&
                        moduleProgress.isQuizCompleted;
                  })
                  .map((module) {
                    final moduleProgress =
                        _progress!.moduleProgress[module.id]!;
                    final score = moduleProgress.quizScore ?? 0;
                    final totalQuestions = module.quiz.questions.length;
                    final percentage = totalQuestions > 0
                        ? (score / totalQuestions) * 100
                        : 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              module.title,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '$score/$totalQuestions',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: percentage >= 70
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${percentage.toInt()}%',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            ],
          ],
        ),
      ),
    );
  }

  // Modül detayları kartı
  Widget _buildModuleDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modül Detayları',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            ..._modules.map((module) {
              final moduleProgress = _progress!.moduleProgress[module.id];
              final isCompleted = moduleProgress?.isCompleted ?? false;
              final isQuizCompleted = moduleProgress?.isQuizCompleted ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted ? Colors.green[200]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    // Modül ikonu
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green[600]
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Modül bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hafta ${module.weekNumber}: ${module.title}',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.check : Icons.schedule,
                                size: 14,
                                color: isCompleted
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted ? 'Tamamlandı' : 'Devam ediyor',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: isCompleted
                                      ? Colors.green[600]
                                      : Colors.orange[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                isQuizCompleted
                                    ? Icons.quiz
                                    : Icons.quiz_outlined,
                                size: 14,
                                color: isQuizCompleted
                                    ? Colors.blue[600]
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isQuizCompleted
                                    ? 'Quiz Tamamlandı'
                                    : 'Quiz Bekliyor',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: isQuizCompleted
                                      ? Colors.blue[600]
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Başarı rozetleri kartı
  Widget _buildAchievementsCard() {
    final completedModules = _progress!.moduleProgress.values
        .where((mp) => mp.isCompleted)
        .length;
    final completedQuizzes = _progress!.moduleProgress.values
        .where((mp) => mp.isQuizCompleted)
        .length;
    final averageScore = _calculateAverageQuizScore();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Başarı Rozetleri',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildAchievementBadge(
                  'İlk Adım',
                  'İlk modülü tamamla',
                  Icons.rocket_launch,
                  completedModules >= 1,
                  Colors.blue,
                ),
                _buildAchievementBadge(
                  'Quiz Ustası',
                  'İlk quiz\'i tamamla',
                  Icons.quiz,
                  completedQuizzes >= 1,
                  Colors.purple,
                ),
                _buildAchievementBadge(
                  'Yüksek Performans',
                  'Ortalama %80+ skor',
                  Icons.trending_up,
                  averageScore >= 80,
                  Colors.orange,
                ),
                _buildAchievementBadge(
                  'Sabırlı Öğrenci',
                  '5 modül tamamla',
                  Icons.school,
                  completedModules >= 5,
                  Colors.green,
                ),
                _buildAchievementBadge(
                  'Dart Uzmanı',
                  'Tüm modülleri tamamla',
                  Icons.diamond,
                  completedModules >= _modules.length,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Başarı rozeti widget'ı
  Widget _buildAchievementBadge(
    String title,
    String description,
    IconData icon,
    bool isUnlocked,
    Color color,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? color.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnlocked ? color : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: isUnlocked ? color : Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? color : Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: isUnlocked ? color : Colors.grey[400],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Yardımcı widget'lar
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWeeklyStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_today, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Yardımcı metodlar
  double _calculateAverageQuizScore() {
    final completedQuizzes = _progress!.moduleProgress.values.where(
      (mp) => mp.isQuizCompleted && mp.quizScore != null,
    );

    if (completedQuizzes.isEmpty) return 0;

    int totalScore = 0;
    int totalQuestions = 0;

    for (final moduleProgress in completedQuizzes) {
      final module = _modules.firstWhere(
        (m) => m.id == moduleProgress.moduleId,
      );
      totalScore += moduleProgress.quizScore!;
      totalQuestions += module.quiz.questions.length;
    }

    return totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
