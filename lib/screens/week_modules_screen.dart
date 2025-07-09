import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'content_viewer_screen.dart';

class WeekModulesScreen extends StatefulWidget {
  final int week;

  const WeekModulesScreen({Key? key, required this.week}) : super(key: key);

  @override
  State<WeekModulesScreen> createState() => _WeekModulesScreenState();
}

class _WeekModulesScreenState extends State<WeekModulesScreen> {
  final ContentService _contentService = ContentService();
  List<ContentModule> _modules = [];
  bool _isLoading = true;
  WeekProgress? _weekProgress;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    try {
      final modules = await _contentService.loadWeekModules(widget.week);
      final allWeekProgress = await _contentService.getAllWeekProgress();

      setState(() {
        _modules = modules;
        _weekProgress = allWeekProgress[widget.week];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modüller yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hafta ${widget.week}: ${ContentService.getWeekTitle(widget.week)}',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildWeekProgress(),
                Expanded(child: _buildModuleList()),
              ],
            ),
    );
  }

  Widget _buildWeekProgress() {
    if (_weekProgress == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Haftalık İlerleme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_weekProgress!.completedModules}/${_weekProgress!.totalModules} Modül',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _weekProgress!.progressPercentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(_weekProgress!.progressPercentage),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tamamlanan: %${_weekProgress!.progressPercentage.toInt()}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleList() {
    if (_modules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Bu hafta için henüz modül hazırlanmadı',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _modules.length,
      itemBuilder: (context, index) {
        final module = _modules[index];
        return _buildModuleCard(module, index);
      },
    );
  }

  Widget _buildModuleCard(ContentModule module, int index) {
    return FutureBuilder<ModuleProgress>(
      future: _contentService.getModuleProgress(module.moduleId),
      builder: (context, snapshot) {
        final progress =
            snapshot.data ?? ModuleProgress.initial(module.moduleId);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _openModule(module),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildModuleIcon(module, progress.isCompleted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${module.title}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              module.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (progress.isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.schedule,
                        label: module.estimatedTime,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.trending_up,
                        label: _getDifficultyText(module.difficulty),
                        color: _getDifficultyColor(module.difficulty),
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.article,
                        label: '${module.sections.length} bölüm',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildModuleProgress(progress, module),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModuleIcon(ContentModule module, bool isCompleted) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;

    if (isCompleted) {
      iconData = Icons.check_circle;
      backgroundColor = Colors.green;
      iconColor = Colors.white;
    } else {
      switch (module.difficulty) {
        case 'beginner':
          iconData = Icons.play_arrow;
          backgroundColor = Colors.green[100]!;
          iconColor = Colors.green;
          break;
        case 'intermediate':
          iconData = Icons.trending_up;
          backgroundColor = Colors.orange[100]!;
          iconColor = Colors.orange;
          break;
        case 'advanced':
          iconData = Icons.rocket_launch;
          backgroundColor = Colors.red[100]!;
          iconColor = Colors.red;
          break;
        default:
          iconData = Icons.book;
          backgroundColor = Colors.grey[100]!;
          iconColor = Colors.grey;
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleProgress(ModuleProgress progress, ContentModule module) {
    final completedSections = progress.sectionProgress.values
        .where((completed) => completed)
        .length;
    final totalSections = module.sections.length;
    final progressPercentage = totalSections > 0
        ? completedSections / totalSections
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'İlerleme: ${(progressPercentage * 100).toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '$completedSections/$totalSections bölüm',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progressPercentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(progressPercentage * 100),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
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

  void _openModule(ContentModule module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContentViewerScreen(week: widget.week, moduleId: module.moduleId),
      ),
    ).then((_) {
      // Modül ekranından döndükten sonra ilerlemeyi yenile
      _loadModules();
    });
  }
}
