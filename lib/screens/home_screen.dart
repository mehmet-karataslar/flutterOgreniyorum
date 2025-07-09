// Ana sayfa ekranı - kullanıcının öğrenme durumunu görüntüler
// Mevcut hafta, ilerleme yüzdesi ve hızlı erişim butonlarını içerir

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/progress.dart';
import '../models/module.dart';
import '../services/data_service.dart';
import '../services/progress_service.dart';
import 'module_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  final ProgressService _progressService = ProgressService();

  Progress? _currentProgress;
  Module? _currentModule;
  bool _isLoading = true;

  // Animasyon değişkenleri
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsünü başlat
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animasyonları oluştur
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadData();

    // İlerleme değişikliklerini dinle
    _progressService.progressStream.listen((progress) {
      setState(() {
        _currentProgress = progress;
      });
    });
  }

  // Sayfa verilerini yükler - kullanıcının mevcut durumunu ve aktif modülünü getirir
  Future<void> _loadData() async {
    try {
      final progress = await _progressService.getCurrentProgress();
      final module = await _dataService.getCurrentWeekModule();

      setState(() {
        _currentProgress = progress;
        _currentModule = module;
        _isLoading = false;
      });

      // Animasyonları başlat
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yüklenirken hata oluştu: $e')),
        );
      }
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
        title: const Text('Flutter Öğrenme Takip'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildHomeContent(),
    );
  }

  // Ana sayfa içeriğini oluşturur
  Widget _buildHomeContent() {
    if (_currentProgress == null) {
      return const Center(child: Text('Veriler yüklenemedi'));
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hoşgeldin mesajı ve genel durum
                _buildWelcomeCard(),
                const SizedBox(height: 20),

                // Mevcut hafta modülü kartı
                _buildCurrentWeekCard(),
                const SizedBox(height: 20),

                // İlerleme göstergesi
                _buildProgressCard(),
                const SizedBox(height: 20),

                // Hızlı erişim butonları
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hoşgeldin mesajı ve genel durum kartı
  Widget _buildWelcomeCard() {
    final startDate = _currentProgress!.startDate;
    final daysSinceStart = DateTime.now().difference(startDate).inDays;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[400]!, Colors.blue[600]!],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoşgeldin!',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Flutter öğrenme yolculuğunun ${daysSinceStart + 1}. günü',
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Mevcut Hafta',
                  '${_currentProgress!.currentWeek}/${_currentProgress!.totalWeeks}',
                  Icons.calendar_today,
                ),
                _buildStatItem(
                  'Tamamlanan',
                  '${_currentProgress!.totalQuizzesPassed} Quiz',
                  Icons.quiz,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Küçük istatistik öğesi oluşturur
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  // Mevcut hafta modülü kartı
  Widget _buildCurrentWeekCard() {
    if (_currentModule == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Mevcut modül bulunamadı'),
        ),
      );
    }

    final moduleProgress = _currentProgress!.moduleProgress[_currentModule!.id];
    final completionPercentage = moduleProgress?.completionPercentage ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hafta ${_currentModule!.weekNumber}',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                CircularPercentIndicator(
                  radius: 25,
                  lineWidth: 4,
                  animation: true,
                  percent: completionPercentage / 100,
                  center: Text(
                    '${completionPercentage.toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  progressColor: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentModule!.title,
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentModule!.description,
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ModuleDetailScreen(module: _currentModule!),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  completionPercentage > 0 ? 'Devam Et' : 'Başla',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Genel ilerleme kartı
  Widget _buildProgressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel İlerleme',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            // İlerleme çubuğu
            LinearPercentIndicator(
              animation: true,
              lineHeight: 20.0,
              animationDuration: 1000,
              percent: _currentProgress!.overallProgress / 100,
              center: Text(
                '${_currentProgress!.overallProgress.toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              progressColor: Colors.blue,
              backgroundColor: Colors.grey[300],
              barRadius: const Radius.circular(10),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressStat(
                  'Tamamlanan Modüller',
                  '${_currentProgress!.moduleProgress.values.where((p) => p.isCompleted).length}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildProgressStat(
                  'Toplam Modüller',
                  '${_currentProgress!.totalWeeks}',
                  Icons.library_books,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // İlerleme istatistik öğesi
  Widget _buildProgressStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Hızlı erişim butonları
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Erişim',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Tüm Modüller',
                Icons.library_books,
                Colors.blue,
                () {
                  // Modüller sekmesine geç
                  DefaultTabController.of(context)?.animateTo(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'İstatistikler',
                Icons.analytics,
                Colors.green,
                () {
                  // İstatistikler sekmesine geç
                  DefaultTabController.of(context)?.animateTo(2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Hızlı erişim butonu
  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
