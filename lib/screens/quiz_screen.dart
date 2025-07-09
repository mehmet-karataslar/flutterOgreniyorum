// Quiz ekranı - modül quiz'lerini gösterir ve kullanıcının cevaplarını değerlendirir
// Çoktan seçmeli sorular, puanlama sistemi ve sonuç gösterimi içerir

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/module.dart';
import '../services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  final Module module;

  const QuizScreen({super.key, required this.module});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ProgressService _progressService = ProgressService();
  final PageController _pageController = PageController();

  // Quiz durum değişkenleri
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  bool _isQuizCompleted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    // Kullanıcı cevapları listesini başlat (null = cevapsız)
    _userAnswers = List.filled(widget.module.quiz.questions.length, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.module.title} Quiz'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isQuizCompleted ? _buildResultScreen() : _buildQuizContent(),
    );
  }

  // Ana quiz içeriği - soru gösterimi
  Widget _buildQuizContent() {
    final questions = widget.module.quiz.questions;

    return Column(
      children: [
        // Üst bilgi paneli - ilerleme göstergesi
        _buildProgressHeader(),

        // Soru içeriği
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentQuestionIndex = index;
              });
            },
            itemCount: questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionCard(questions[index], index);
            },
          ),
        ),

        // Alt navigasyon butonları
        _buildNavigationButtons(),
      ],
    );
  }

  // Üst ilerleme göstergesi
  Widget _buildProgressHeader() {
    final totalQuestions = widget.module.quiz.questions.length;
    final answeredQuestions =
        _userAnswers.where((answer) => answer != null).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Soru sayısı bilgisi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${_currentQuestionIndex + 1} / $totalQuestions',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                'Cevaplanan: $answeredQuestions',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // İlerleme çubuğu
          LinearPercentIndicator(
            animation: true,
            lineHeight: 8.0,
            animationDuration: 300,
            percent: (_currentQuestionIndex + 1) / totalQuestions,
            progressColor: Colors.blue[600],
            backgroundColor: Colors.grey[300],
            barRadius: const Radius.circular(4),
          ),
        ],
      ),
    );
  }

  // Tek bir soru kartı
  Widget _buildQuestionCard(Question question, int questionIndex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Soru metni
              Text(
                question.question,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Cevap seçenekleri
              ...question.options.asMap().entries.map((entry) {
                final optionIndex = entry.key;
                final optionText = entry.value;
                final isSelected = _userAnswers[questionIndex] == optionIndex;

                return _buildOptionCard(
                  optionText,
                  optionIndex,
                  isSelected,
                  () => _selectAnswer(questionIndex, optionIndex),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // Cevap seçeneği kartı
  Widget _buildOptionCard(
    String optionText,
    int optionIndex,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.grey[50],
            border: Border.all(
              color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Seçenek harfi (A, B, C, D)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + optionIndex), // A, B, C, D
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Seçenek metni
              Expanded(
                child: Text(
                  optionText,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: isSelected ? Colors.blue[800] : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Alt navigasyon butonları
  Widget _buildNavigationButtons() {
    final isFirstQuestion = _currentQuestionIndex == 0;
    final isLastQuestion =
        _currentQuestionIndex == widget.module.quiz.questions.length - 1;
    final allQuestionsAnswered = _userAnswers.every((answer) => answer != null);

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
          // Önceki buton
          if (!isFirstQuestion)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousQuestion,
                child: const Text('Önceki'),
              ),
            ),

          if (!isFirstQuestion) const SizedBox(width: 12),

          // Sonraki/Bitir butonu
          Expanded(
            child: ElevatedButton(
              onPressed:
                  isLastQuestion
                      ? (allQuestionsAnswered ? _finishQuiz : null)
                      : _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLastQuestion ? Colors.green[600] : Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isLastQuestion ? 'Quiz\'i Bitir' : 'Sonraki',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sonuç ekranı
  Widget _buildResultScreen() {
    final totalQuestions = widget.module.quiz.questions.length;
    final scorePercentage = (_score / totalQuestions) * 100;
    final isPassed = scorePercentage >= widget.module.quiz.passScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sonuç kartı
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Başarı ikonu
                  Icon(
                    isPassed ? Icons.celebration : Icons.sentiment_dissatisfied,
                    size: 80,
                    color: isPassed ? Colors.green[600] : Colors.orange[600],
                  ),
                  const SizedBox(height: 16),

                  // Başlık
                  Text(
                    isPassed ? 'Tebrikler!' : 'Tekrar Dene',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isPassed ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sonuç mesajı
                  Text(
                    isPassed
                        ? 'Quiz\'i başarıyla tamamladınız!'
                        : 'Geçmek için %${widget.module.quiz.passScore.toInt()} puan gerekli',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Puan göstergesi
                  CircularPercentIndicator(
                    radius: 60,
                    lineWidth: 8,
                    animation: true,
                    percent: scorePercentage / 100,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_score/$totalQuestions',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${scorePercentage.toInt()}%',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    progressColor: isPassed ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 24),

                  // Detaylı sonuçlar
                  _buildDetailedResults(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Alt butonlar
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Modüle Dön'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _retakeQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tekrar Çöz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Detaylı sonuçlar
  Widget _buildDetailedResults() {
    return Column(
      children: [
        Text(
          'Soru Detayları',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...widget.module.quiz.questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final userAnswer = _userAnswers[index];
          final isCorrect = userAnswer == question.correctAnswer;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green[50] : Colors.red[50],
              border: Border.all(
                color: isCorrect ? Colors.green[200]! : Colors.red[200]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Soru ${index + 1}: ${isCorrect ? "Doğru" : "Yanlış"}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: isCorrect ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Cevap seçimi
  void _selectAnswer(int questionIndex, int optionIndex) {
    setState(() {
      _userAnswers[questionIndex] = optionIndex;
    });
  }

  // Sonraki soru
  void _nextQuestion() {
    if (_currentQuestionIndex < widget.module.quiz.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Önceki soru
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Quiz'i bitir
  Future<void> _finishQuiz() async {
    // Puanı hesapla
    _score = 0;
    for (int i = 0; i < widget.module.quiz.questions.length; i++) {
      if (_userAnswers[i] == widget.module.quiz.questions[i].correctAnswer) {
        _score++;
      }
    }

    try {
      // Sonucu kaydet
      await _progressService.saveQuizResult(
        widget.module.id,
        _score,
        widget.module.quiz.questions.length,
      );

      setState(() {
        _isQuizCompleted = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sonuç kaydedilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Quiz'i tekrar çöz
  void _retakeQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _userAnswers = List.filled(widget.module.quiz.questions.length, null);
      _isQuizCompleted = false;
      _score = 0;
    });

    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
