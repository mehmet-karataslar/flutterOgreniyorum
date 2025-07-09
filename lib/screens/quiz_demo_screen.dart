import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quiz_service.dart';

class QuizDemoScreen extends StatefulWidget {
  const QuizDemoScreen({super.key});

  @override
  State<QuizDemoScreen> createState() => _QuizDemoScreenState();
}

class _QuizDemoScreenState extends State<QuizDemoScreen> {
  final QuizService _quizService = QuizService();
  bool _isLoading = false;
  String _message = '';
  QuizStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final stats = await _quizService.getQuizStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testQuizLoading() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final quizData = await _quizService.loadQuizForModule(1);
      setState(() {
        _message =
            'Quiz başarıyla yüklendi!\n'
            'Modül: ${quizData.moduleName}\n'
            'Soru sayısı: ${quizData.questions.length}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Quiz yüklenirken hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz Sistemi Demo',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Yeni Quiz Sistemi',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'JSON dosyalarından quiz verilerini yükleyen modern quiz sistemi',
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Features
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Özellikler:',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem('📁 Modüler JSON dosyalar'),
                    _buildFeatureItem('🎯 Zorluk seviyesi seçimi'),
                    _buildFeatureItem('🔄 Rastgele soru seçimi'),
                    _buildFeatureItem('⏱️ Zamanlayıcı sistemi'),
                    _buildFeatureItem('📊 Detaylı istatistikler'),
                    _buildFeatureItem('💾 Sonuçları kaydetme'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testQuizLoading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Quiz Yüklemeyi Test Et'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loadStatistics,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('İstatistikleri Yükle'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Message Area
            if (_message.isNotEmpty)
              Card(
                color: _message.contains('Hata')
                    ? Colors.red[50]
                    : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _message,
                    style: GoogleFonts.roboto(
                      color: _message.contains('Hata')
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Statistics
            if (_statistics != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz İstatistikleri',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Toplam Quiz:',
                          '${_statistics!.totalQuizzesTaken}',
                        ),
                        _buildStatRow(
                          'Geçilen Quiz:',
                          '${_statistics!.totalQuizzesPassed}',
                        ),
                        _buildStatRow(
                          'Geçme Oranı:',
                          '${_statistics!.passRate.toStringAsFixed(1)}%',
                        ),
                        _buildStatRow(
                          'Ortalama Puan:',
                          '${_statistics!.averageScore.toStringAsFixed(1)}%',
                        ),
                        _buildStatRow(
                          'En Yüksek Puan:',
                          '${_statistics!.bestScore.toStringAsFixed(1)}%',
                        ),
                        _buildStatRow(
                          'En Düşük Puan:',
                          '${_statistics!.worstScore.toStringAsFixed(1)}%',
                        ),
                        _buildStatRow(
                          'Toplam Puan:',
                          '${_statistics!.totalPointsEarned}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(feature, style: GoogleFonts.roboto(fontSize: 14)),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.roboto(fontSize: 14)),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }
}
