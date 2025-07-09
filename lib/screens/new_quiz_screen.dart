import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quiz_service.dart';
import 'dart:async';

class NewQuizScreen extends StatefulWidget {
  final int moduleId;
  final String moduleName;

  const NewQuizScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<NewQuizScreen> createState() => _NewQuizScreenState();
}

class _NewQuizScreenState extends State<NewQuizScreen> {
  final QuizService _quizService = QuizService();
  late QuizData _quizData;
  late List<QuizQuestion> _selectedQuestions;

  int _currentQuestionIndex = 0;
  Map<int, int> _userAnswers = {};

  Timer? _timer;
  int _remainingTime = 300; // 5 dakika (300 saniye)

  bool _isLoading = true;
  bool _quizCompleted = false;
  QuizResult? _quizResult;

  String _selectedDifficulty = 'mixed'; // easy, medium, hard, mixed
  int _questionsCount = 5;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    try {
      _quizData = await _quizService.loadQuizForModule(widget.moduleId);
      _selectQuestionsBasedOnDifficulty();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog();
    }
  }

  void _selectQuestionsBasedOnDifficulty() {
    switch (_selectedDifficulty) {
      case 'easy':
        _selectedQuestions = _quizService.selectQuestionsByDifficulty(
          _quizData,
          'easy',
          _questionsCount,
        );
        break;
      case 'medium':
        _selectedQuestions = _quizService.selectQuestionsByDifficulty(
          _quizData,
          'medium',
          _questionsCount,
        );
        break;
      case 'hard':
        _selectedQuestions = _quizService.selectQuestionsByDifficulty(
          _quizData,
          'hard',
          _questionsCount,
        );
        break;
      case 'mixed':
        _selectedQuestions = _quizService.selectMixedDifficultyQuestions(
          _quizData,
          _questionsCount,
        );
        break;
      default:
        _selectedQuestions = _quizService.selectRandomQuestions(
          _quizData,
          _questionsCount,
        );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _finishQuiz();
        }
      });
    });
  }

  void _answerQuestion(int answerIndex) {
    setState(() {
      _userAnswers[_selectedQuestions[_currentQuestionIndex].id] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _selectedQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    _quizResult = _quizService.calculateQuizResult(
      _selectedQuestions,
      _userAnswers,
    );
    _quizService.saveQuizResult(widget.moduleId, _quizResult!);

    setState(() {
      _quizCompleted = true;
    });
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: const Text('Quiz yüklenirken bir hata oluştu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quiz: ${widget.moduleName}',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (!_quizCompleted && !_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_quizCompleted) {
      return _buildResultScreen();
    }

    return _buildQuizScreen();
  }

  Widget _buildQuizScreen() {
    if (_selectedQuestions.isEmpty) {
      return const Center(child: Text('Bu modül için sorular bulunamadı.'));
    }

    final currentQuestion = _selectedQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _selectedQuestions.length;

    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Soru ${_currentQuestionIndex + 1}/${_selectedQuestions.length}',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(currentQuestion.difficulty),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getDifficultyText(currentQuestion.difficulty),
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Question Text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    currentQuestion.question,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Options
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, index) {
                      final isSelected =
                          _userAnswers[currentQuestion.id] == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _answerQuestion(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigo : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.indigo
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[300],
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(
                                        65 + index,
                                      ), // A, B, C, D
                                      style: GoogleFonts.roboto(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.indigo
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    currentQuestion.options[index],
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Navigation Buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              ElevatedButton(
                onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Önceki'),
              ),

              // Next/Finish Button
              ElevatedButton(
                onPressed: _userAnswers.containsKey(currentQuestion.id)
                    ? (_currentQuestionIndex == _selectedQuestions.length - 1
                          ? _finishQuiz
                          : _nextQuestion)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  _currentQuestionIndex == _selectedQuestions.length - 1
                      ? 'Bitir'
                      : 'Sonraki',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    if (_quizResult == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Result Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _quizResult!.passed ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _quizResult!.passed ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _quizResult!.passed ? Icons.check_circle : Icons.error,
                  color: _quizResult!.passed ? Colors.green : Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _quizResult!.passed ? 'TEBRİKLER!' : 'TEKRAR DENEYİN',
                  style: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _quizResult!.passed ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _quizResult!.passed
                      ? 'Quiz\'i başarıyla tamamladınız!'
                      : 'Geçmek için %70 puan gereklidir.',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistics
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Puan',
                  '${_quizResult!.percentage.toStringAsFixed(1)}%',
                  Icons.grade,
                  Colors.indigo,
                ),
                _buildStatCard(
                  'Doğru',
                  '${_quizResult!.correctAnswers}/${_quizResult!.totalQuestions}',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  'Yanlış',
                  '${_quizResult!.wrongAnswers}',
                  Icons.error,
                  Colors.red,
                ),
                _buildStatCard(
                  'Kazanılan Puan',
                  '${_quizResult!.earnedPoints}/${_quizResult!.totalPoints}',
                  Icons.stars,
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Geri Dön'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _restartQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Tekrar Dene'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _remainingTime = 300;
      _quizCompleted = false;
      _quizResult = null;
    });
    _selectQuestionsBasedOnDifficulty();
    _startTimer();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'Kolay';
      case 'medium':
        return 'Orta';
      case 'hard':
        return 'Zor';
      default:
        return 'Bilinmiyor';
    }
  }
}
