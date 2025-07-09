// Modül detay ekranı - seçilen modülün tüm içeriğini gösterir
// Konular, kod örnekleri, hedefler ve modülü tamamlama butonu içerir

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/module.dart';
import '../services/progress_service.dart';
import 'quiz_screen.dart';

class ModuleDetailScreen extends StatefulWidget {
  final Module module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final ProgressService _progressService = ProgressService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hafta ${widget.module.weekNumber}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // Ana içerik bölümü - tüm modül bilgilerini gösterir
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve açıklama
          _buildHeader(),
          const SizedBox(height: 24),

          // Haftalık hedefler
          _buildGoalsSection(),
          const SizedBox(height: 24),

          // Konular
          _buildTopicsSection(),
          const SizedBox(height: 24),

          // Kod örnekleri
          _buildCodeExamplesSection(),
          const SizedBox(height: 24),

          // Ek kaynaklar
          _buildResourcesSection(),
          const SizedBox(height: 80), // Bottom bar için boşluk
        ],
      ),
    );
  }

  // Başlık ve açıklama bölümü
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.module.title,
          style: GoogleFonts.roboto(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.module.description,
          style: GoogleFonts.roboto(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Haftalık hedefler bölümü
  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Haftalık Hedefler',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  widget.module.goals.map((goal) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              goal,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Konular bölümü
  Widget _buildTopicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Konular',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...widget.module.topics.map((topic) => _buildTopicCard(topic)),
      ],
    );
  }

  // Tek bir konu kartı
  Widget _buildTopicCard(Topic topic) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(
          topic.title,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Konu açıklaması
                Text(
                  topic.content,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Anahtar noktalar
                if (topic.keyPoints.isNotEmpty) ...[
                  Text(
                    'Anahtar Noktalar:',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...topic.keyPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              point,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Kod örnekleri bölümü
  Widget _buildCodeExamplesSection() {
    if (widget.module.codeExamples.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kod Örnekleri',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...widget.module.codeExamples.map(
          (example) => _buildCodeExampleCard(example),
        ),
      ],
    );
  }

  // Tek bir kod örneği kartı
  Widget _buildCodeExampleCard(CodeExample example) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kod örneği başlığı
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              example.title,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),

          // Kod bloku
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: HighlightView(
              example.code,
              language: example.language,
              theme: githubTheme,
              padding: const EdgeInsets.all(12),
              textStyle: GoogleFonts.sourceCodePro(fontSize: 12),
            ),
          ),

          // Kod açıklaması
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              example.explanation,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ek kaynaklar bölümü
  Widget _buildResourcesSection() {
    if (widget.module.resources.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ek Kaynaklar',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  widget.module.resources.map((resource) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _launchURL(resource),
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.blue[600], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                resource,
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.blue[600],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Alt bar - tamamlama butonu ve quiz erişimi
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quiz butonu
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Quiz ekranına yönlendirme
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(module: widget.module),
                  ),
                );
              },
              icon: const Icon(Icons.quiz),
              label: const Text('Quiz Çöz'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Tamamlama butonu
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _completeModule(),
              icon: const Icon(Icons.check),
              label: const Text('Tamamla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modülü tamamlandı olarak işaretler
  Future<void> _completeModule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _progressService.completeModule(widget.module.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.module.title} tamamlandı!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // URL açma fonksiyonu
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('URL açılamadı: $url')));
      }
    }
  }
}
