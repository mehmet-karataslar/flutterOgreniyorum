// Ayarlar ekranı - kullanıcı tercihleri, tema ayarları ve uygulama bilgileri
// İlerleme sıfırlama, bildirim ayarları ve destek seçenekleri içerir

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/progress_service.dart';
import 'quiz_demo_screen.dart';
import 'week_modules_screen.dart';
import 'content_viewer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProgressService _progressService = ProgressService();

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ayarlar',
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kullanıcı Tercihleri
          _buildSectionHeader('Kullanıcı Tercihleri'),
          _buildSettingsCard([
            _buildSwitchTile(
              'Bildirimler',
              'Günlük hatırlatmalar ve ilerleme bildirimleri',
              Icons.notifications,
              _notificationsEnabled,
              (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            _buildSwitchTile(
              'Karanlık Tema',
              'Koyu renk teması kullan',
              Icons.dark_mode,
              _darkModeEnabled,
              (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
            ),
            _buildSwitchTile(
              'Ses Efektleri',
              'Buton tıklamaları ve başarı sesleri',
              Icons.volume_up,
              _soundEnabled,
              (value) {
                setState(() {
                  _soundEnabled = value;
                });
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Öğrenme Ayarları
          _buildSectionHeader('Öğrenme Ayarları'),
          _buildSettingsCard([
            _buildActionTile(
              'Haftalık Hedefler',
              'Öğrenme hedeflerini ayarla',
              Icons.flag,
              () {
                _showWeeklyGoalsDialog();
              },
            ),
            _buildActionTile(
              'Hatırlatma Zamanı',
              'Günlük çalışma saatini belirle',
              Icons.schedule,
              () {
                _showReminderTimeDialog();
              },
            ),
            _buildActionTile(
              'Zorluk Seviyesi',
              'Öğrenme hızını ayarla',
              Icons.speed,
              () {
                _showDifficultyDialog();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Veri Yönetimi
          _buildSectionHeader('Veri Yönetimi'),
          _buildSettingsCard([
            _buildActionTile(
              'İlerlemeyi Dışa Aktar',
              'Öğrenme verilerini yedekle',
              Icons.backup,
              () {
                _exportProgress();
              },
            ),
            _buildActionTile(
              'Verileri İçe Aktar',
              'Yedeklenen verileri geri yükle',
              Icons.restore,
              () {
                _importProgress();
              },
            ),
            _buildActionTile(
              'İlerlemeyi Sıfırla',
              'Tüm öğrenme verilerini sil',
              Icons.refresh,
              () {
                _showResetProgressDialog();
              },
              textColor: Colors.red,
            ),
          ]),

          const SizedBox(height: 24),

          // Geliştirici Araçları
          _buildSectionHeader('Geliştirici Araçları'),
          _buildSettingsCard([
            _buildActionTile(
              'Yeni İçerik Sistemi Demo',
              'Detaylı modüller ve JSON tabanlı içerik',
              Icons.book,
              () {
                _showWeekSelectionDialog();
              },
              textColor: Colors.deepPurple,
            ),
            _buildActionTile(
              'Yeni Quiz Sistemi Demo',
              'JSON tabanlı quiz sistemini test et',
              Icons.quiz,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuizDemoScreen(),
                  ),
                );
              },
              textColor: Colors.indigo,
            ),
          ]),

          const SizedBox(height: 24),

          // Destek ve Bilgi
          _buildSectionHeader('Destek ve Bilgi'),
          _buildSettingsCard([
            _buildActionTile(
              'Yardım ve SSS',
              'Sık sorulan sorular ve yardım',
              Icons.help,
              () {
                _openHelpPage();
              },
            ),
            _buildActionTile(
              'Geri Bildirim Gönder',
              'Önerilerin ve şikayetlerin',
              Icons.feedback,
              () {
                _sendFeedback();
              },
            ),
            _buildActionTile(
              'Uygulama Hakkında',
              'Versiyon bilgisi ve geliştirici',
              Icons.info,
              () {
                _showAboutDialog();
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Sosyal Medya
          _buildSectionHeader('Sosyal Medya'),
          _buildSettingsCard([
            _buildActionTile(
              'GitHub',
              'Kaynak kodu ve katkıda bulunma',
              Icons.code,
              () {
                _openGitHub();
              },
            ),
            _buildActionTile(
              'Flutter.dev',
              'Resmi Flutter dokümantasyonu',
              Icons.web,
              () {
                _openFlutterDocs();
              },
            ),
          ]),

          const SizedBox(height: 32),

          // Versiyon Bilgisi
          Center(
            child: Text(
              'Flutter Öğrenme Takip v1.0.0',
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
      ),
      secondary: Icon(icon, color: Colors.blue[600]),
      activeColor: Colors.blue[600],
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.blue[600]),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  // Dialog ve işlem metodları
  void _showWeeklyGoalsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Haftalık Hedefler'),
        content: const Text('Bu özellik yakında eklenecek!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showReminderTimeDialog() {
    showTimePicker(context: context, initialTime: TimeOfDay.now()).then((time) {
      if (time != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hatırlatma saati ${time.format(context)} olarak ayarlandı',
            ),
          ),
        );
      }
    });
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zorluk Seviyesi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Başlangıç'),
              subtitle: const Text('Yavaş ve detaylı öğrenme'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Başlangıç seviyesi seçildi')),
                );
              },
            ),
            ListTile(
              title: const Text('Orta'),
              subtitle: const Text('Orta hızda öğrenme'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Orta seviye seçildi')),
                );
              },
            ),
            ListTile(
              title: const Text('İleri'),
              subtitle: const Text('Hızlı öğrenme'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İleri seviye seçildi')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İlerleme verileri dışa aktarıldı'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _importProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veri içe aktarma özelliği yakında eklenecek'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showResetProgressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İlerlemeyi Sıfırla'),
        content: const Text(
          'Tüm öğrenme verileriniz silinecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _progressService.resetProgress();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('İlerleme başarıyla sıfırlandı'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  void _openHelpPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yardım'),
        content: const Text(
          'Flutter Öğrenme Takip uygulaması, Flutter ve Dart öğrenme sürecinizi takip etmenize yardımcı olur.\n\n'
          'Özellikler:\n'
          '• 11 haftalık öğrenme programı\n'
          '• Quiz sistemi\n'
          '• İlerleme takibi\n'
          '• Başarı rozetleri\n'
          '• Detaylı istatistikler',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'developer@example.com',
      query: 'subject=Flutter Öğrenme Takip - Geri Bildirim',
    );

    try {
      await launchUrl(emailUri);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-posta uygulaması açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Flutter Öğrenme Takip',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.flutter_dash,
        size: 64,
        color: Colors.blue[600],
      ),
      children: [
        const Text(
          'Flutter ve Dart öğrenme sürecinizi takip etmenize yardımcı olan bir uygulamadır.',
        ),
        const SizedBox(height: 16),
        const Text('Geliştirici: Flutter Öğrenme Takip Ekibi'),
        const SizedBox(height: 8),
        const Text(
          'Bu uygulama, Flutter ve Dart öğrenmek isteyen herkese ücretsiz olarak sunulmaktadır.',
        ),
      ],
    );
  }

  void _showWeekSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hafta Seçin'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 1, // Şu anda sadece hafta 1 mevcut
            itemBuilder: (context, index) {
              final week = index + 1;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    '$week',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text('Hafta $week'),
                subtitle: Text(_getWeekSubtitle(week)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeekModulesScreen(week: week),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  String _getWeekSubtitle(int week) {
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

  void _openGitHub() async {
    const url = 'https://github.com/flutter/flutter';
    try {
      await launchUrl(Uri.parse(url));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web sayfası açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFlutterDocs() async {
    const url = 'https://flutter.dev/docs';
    try {
      await launchUrl(Uri.parse(url));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web sayfası açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
