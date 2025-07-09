import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/content_service.dart';
import 'dart:async';

class ContentViewerScreen extends StatefulWidget {
  final int week;
  final String moduleId;

  const ContentViewerScreen({
    Key? key,
    required this.week,
    required this.moduleId,
  }) : super(key: key);

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  final ContentService _contentService = ContentService();
  ContentModule? _currentModule;
  ModuleProgress? _progress;
  bool _isLoading = true;
  int _currentSectionIndex = 0;
  Timer? _readingTimer;
  DateTime? _sectionStartTime;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _readingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContent() async {
    try {
      print(
        'ContentViewerScreen: İçerik yükleniyor - week: ${widget.week}, moduleId: ${widget.moduleId}',
      );

      final module = await _contentService.loadContentModule(
        widget.week,
        widget.moduleId,
      );
      final progress = await _contentService.getModuleProgress(widget.moduleId);

      print('ContentViewerScreen: Modül yüklendi - ${module.title}');
      print('ContentViewerScreen: Bölüm sayısı - ${module.sections.length}');
      print('ContentViewerScreen: İlerleme - ${progress.currentSectionIndex}');

      setState(() {
        _currentModule = module;
        _progress = progress;
        _currentSectionIndex = progress.currentSectionIndex;
        _isLoading = false;
      });

      _startReadingTimer();
    } catch (e, stackTrace) {
      print('ContentViewerScreen hata: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İçerik yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startReadingTimer() {
    _sectionStartTime = DateTime.now();
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Her saniye süreyi güncelle
    });
  }

  Future<void> _markSectionCompleted(String sectionId) async {
    if (_progress != null) {
      final updatedProgress = ModuleProgress(
        moduleId: _progress!.moduleId,
        isCompleted: _progress!.isCompleted,
        sectionProgress: Map.from(_progress!.sectionProgress)
          ..[sectionId] = true,
        currentSectionIndex: _currentSectionIndex,
        lastAccessedAt: DateTime.now(),
        timeSpent: _progress!.timeSpent,
      );

      await _contentService.saveModuleProgress(
        widget.moduleId,
        updatedProgress,
      );

      setState(() {
        _progress = updatedProgress;
      });
    }
  }

  void _nextSection() {
    if (_currentModule != null &&
        _currentSectionIndex < _currentModule!.sections.length - 1) {
      setState(() {
        _currentSectionIndex++;
      });
      _startReadingTimer();
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
      });
      _startReadingTimer();
    }
  }

  void _goToSection(int index) {
    setState(() {
      _currentSectionIndex = index;
    });
    _startReadingTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('İçerik Yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentModule == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: const Center(child: Text('İçerik yüklenemedi')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentModule!.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.quiz), onPressed: _showQuiz),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _markSectionCompleted(
              _currentModule!.sections[_currentSectionIndex].id,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          _buildSectionTabs(),
          Expanded(child: _buildContent()),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    if (_progress == null || _currentModule == null) return const SizedBox();

    final completedSections = _progress!.sectionProgress.values
        .where((completed) => completed)
        .length;
    final totalSections = _currentModule!.sections.length;
    final progressPercentage = totalSections > 0
        ? completedSections / totalSections
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İlerleme: ${(progressPercentage * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$completedSections/$totalSections bölüm tamamlandı',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _currentModule!.sections.length,
        itemBuilder: (context, index) {
          final section = _currentModule!.sections[index];
          final isCompleted = _progress?.sectionProgress[section.id] ?? false;
          final isCurrent = index == _currentSectionIndex;

          return GestureDetector(
            onTap: () => _goToSection(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted ? Colors.green : Colors.grey,
                  width: isCompleted ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCompleted) ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${index + 1}. ${section.title}',
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.black,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_currentSectionIndex == 0) {
      return _buildIntroduction();
    } else if (_currentSectionIndex <= _currentModule!.sections.length) {
      return _buildSection(_currentModule!.sections[_currentSectionIndex - 1]);
    } else {
      return _buildSummary();
    }
  }

  Widget _buildIntroduction() {
    final intro = _currentModule!.introduction;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCards(),
          const SizedBox(height: 24),
          Text(
            intro.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            intro.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildKeyPoints(intro.keyPoints),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.schedule,
            title: 'Süre',
            value: _currentModule!.estimatedTime,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.trending_up,
            title: 'Seviye',
            value: _getDifficultyText(_currentModule!.difficulty),
            color: _getDifficultyColor(_currentModule!.difficulty),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPoints(List<String> keyPoints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Önemli Noktalar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...keyPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ContentSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            section.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          ...section.subsections.map(
            (subsection) => _buildSubsection(subsection),
          ),
          if (section.bestPractices != null) ...[
            const SizedBox(height: 24),
            _buildBestPractices(section.bestPractices!),
          ],
        ],
      ),
    );
  }

  Widget _buildSubsection(ContentSubsection subsection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subsection.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subsection.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...subsection.codeExamples.map(
            (example) => _buildCodeExample(example),
          ),
          if (subsection.interactiveExercise != null) ...[
            const SizedBox(height: 16),
            _buildInteractiveExercise(subsection.interactiveExercise!),
          ],
          if (subsection.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildKeyPoints(subsection.keyPoints),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeExample(CodeExample example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            example.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.code, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      example.language.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: example.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kod kopyalandı!')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  example.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            example.explanation,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          if (example.output != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.terminal, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'ÇIKTI',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    example.output!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractiveExercise(InteractiveExercise exercise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.quiz, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'İnteraktif Egzersiz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exercise.question,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 8),
          ExpansionTile(
            title: const Text('💡 İpucu'),
            children: [
              Text(
                exercise.hint,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('✅ Çözüm'),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exercise.solution,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestPractices(BestPractices practices) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                practices.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            practices.content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 12),
          ...practices.examples.map(
            (example) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: Colors.purple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      example,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final summary = _currentModule!.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          _buildKeyPoints(summary.keyTakeaways),
          const SizedBox(height: 24),
          if (summary.nextModule != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.arrow_forward, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sıradaki Modül',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary.nextModule!,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_currentModule!.practiceExercises.isNotEmpty) ...[
            const Text(
              'Pratik Egzersizler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            ..._currentModule!.practiceExercises.map(
              (exercise) => _buildPracticeExercise(exercise),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPracticeExercise(PracticeExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                exercise.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exercise.description,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 12),
          ...exercise.instructions.map(
            (instruction) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instruction,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (exercise.starterCode != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('🚀 Başlangıç Kodu'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercise.starterCode!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
          ExpansionTile(
            title: const Text('✅ Çözüm'),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exercise.solution,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentSectionIndex > 0 ? _previousSection : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Önceki'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
            ),
          ),
          Text(
            '${_currentSectionIndex + 1} / ${_currentModule!.sections.length + 2}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed:
                _currentSectionIndex < _currentModule!.sections.length + 1
                ? _nextSection
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Sonraki'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Başlangıç';
      case 'intermediate':
        return 'Orta';
      case 'advanced':
        return 'İleri';
      default:
        return 'Bilinmeyen';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showQuiz() {
    if (_currentModule?.quiz != null) {
      // Quiz ekranına yönlendir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz özelliği yakında eklenecek!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu modül için quiz bulunmuyor.')),
      );
    }
  }
}
