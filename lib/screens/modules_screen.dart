// Modüller ekranı - tüm 11 haftalık modülleri timeline şeklinde gösterir
// Her modülün tamamlanma durumu, ilerleme yüzdesi ve erişim durumu gösterilir

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/module.dart';
import '../models/progress.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';
import 'module_detail_screen.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen>
    with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  final ProgressService _progressService = ProgressService();

  List<Module> _modules = [];
  Progress? _progress;
  bool _isLoading = true;

  // Animasyon değişkenleri
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    // Animation controller'ı başlat
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _loadData();

    // İlerleme değişikliklerini dinle
    _progressService.progressStream.listen((progress) {
      setState(() {
        _progress = progress;
      });
    });
  }

  // Modüller ve ilerleme verilerini yükler
  Future<void> _loadData() async {
    try {
      final modules = _dataService.getAllModules();
      final progress = await _progressService.getCurrentProgress();

      setState(() {
        _modules = modules;
        _progress = progress;
        _isLoading = false;
      });

      // Animasyonları oluştur
      _createAnimations();

      // Animasyonları başlat
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Veri yüklenirken hata: $e')));
      }
    }
  }

  // Animasyonları oluşturur
  void _createAnimations() {
    _fadeAnimations = [];
    _slideAnimations = [];

    for (int i = 0; i < _modules.length; i++) {
      final startDelay = i * 0.1; // Her modül için 100ms gecikme
      final endDelay = startDelay + 0.3; // 300ms süre

      // Fade animasyonu
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(startDelay, endDelay, curve: Curves.easeOut),
          ),
        ),
      );

      // Slide animasyonu
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(startDelay, endDelay, curve: Curves.easeOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm Modüller'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
    );
  }

  // Ana içerik - modülleri timeline şeklinde gösterir
  Widget _buildContent() {
    if (_modules.isEmpty || _progress == null) {
      return const Center(child: Text('Modüller yüklenemedi'));
    }

    return Column(
      children: [
        // Üst bilgi paneli
        _buildInfoPanel(),

        // Modüller listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _modules.length,
            itemBuilder: (context, index) {
              final module = _modules[index];
              final moduleProgress = _progress!.moduleProgress[module.id];
              final isUnlocked = _isModuleUnlocked(module.weekNumber);

              return _buildAnimatedModuleCard(
                module,
                moduleProgress,
                isUnlocked,
                index,
              );
            },
          ),
        ),
      ],
    );
  }

  // Üst bilgi paneli - genel ilerleme durumu
  Widget _buildInfoPanel() {
    final completedModules =
        _progress!.moduleProgress.values.where((p) => p.isCompleted).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            'Tamamlanan',
            '$completedModules',
            Icons.check_circle,
            Colors.green,
          ),
          _buildInfoItem(
            'Mevcut Hafta',
            '${_progress!.currentWeek}',
            Icons.play_circle,
            Colors.blue,
          ),
          _buildInfoItem(
            'Kalan',
            '${_progress!.totalWeeks - completedModules}',
            Icons.schedule,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  // Bilgi öğesi
  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Animasyonlu modül kartı
  Widget _buildAnimatedModuleCard(
    Module module,
    ModuleProgress? moduleProgress,
    bool isUnlocked,
    int index,
  ) {
    // Animasyonlar yüklenmediyse normal kartı göster
    if (_fadeAnimations.isEmpty || _slideAnimations.isEmpty) {
      return _buildModuleCard(module, moduleProgress, isUnlocked);
    }

    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: _buildModuleCard(module, moduleProgress, isUnlocked),
      ),
    );
  }

  // Modül kartı
  Widget _buildModuleCard(
    Module module,
    ModuleProgress? moduleProgress,
    bool isUnlocked,
  ) {
    final completionPercentage = moduleProgress?.completionPercentage ?? 0.0;
    final isCompleted = moduleProgress?.isCompleted ?? false;
    final isQuizCompleted = moduleProgress?.isQuizCompleted ?? false;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isUnlocked ? () => _navigateToModule(module) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst kısım - hafta numarası ve durum
              Row(
                children: [
                  // Hafta numarası
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(isCompleted, isUnlocked),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${module.weekNumber}',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Başlık ve durum
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isUnlocked
                                    ? Colors.grey[800]
                                    : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusText(
                            isCompleted,
                            isUnlocked,
                            module.weekNumber,
                          ),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: _getStatusColor(isCompleted, isUnlocked),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // İlerleme göstergesi
                  if (isUnlocked)
                    CircularPercentIndicator(
                      radius: 25,
                      lineWidth: 4,
                      animation: true,
                      percent: completionPercentage / 100,
                      center: Text(
                        '${completionPercentage.toInt()}%',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      progressColor: _getStatusColor(isCompleted, isUnlocked),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Açıklama
              Text(
                module.description,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Alt bilgiler
              if (isUnlocked) ...[
                Row(
                  children: [
                    // Konu sayısı
                    _buildInfoChip(
                      Icons.topic,
                      '${module.topics.length} Konu',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),

                    // Kod örneği sayısı
                    _buildInfoChip(
                      Icons.code,
                      '${module.codeExamples.length} Örnek',
                      Colors.green,
                    ),
                    const SizedBox(width: 8),

                    // Quiz durumu
                    if (isQuizCompleted)
                      _buildInfoChip(Icons.quiz, 'Quiz ✓', Colors.orange),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Küçük bilgi chip'i
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Modül kilidi açık mı kontrol eder
  bool _isModuleUnlocked(int weekNumber) {
    return weekNumber <= _progress!.currentWeek;
  }

  // Durum rengini döndürür
  Color _getStatusColor(bool isCompleted, bool isUnlocked) {
    if (isCompleted) return Colors.green;
    if (isUnlocked) return Colors.blue;
    return Colors.grey;
  }

  // Durum metnini döndürür
  String _getStatusText(bool isCompleted, bool isUnlocked, int weekNumber) {
    if (isCompleted) return 'Tamamlandı';
    if (isUnlocked) {
      if (weekNumber == _progress!.currentWeek) {
        return 'Mevcut Hafta';
      }
      return 'Erişilebilir';
    }
    return 'Kilitli';
  }

  // Modül detayına yönlendir
  void _navigateToModule(Module module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModuleDetailScreen(module: module),
      ),
    );
  }
}
