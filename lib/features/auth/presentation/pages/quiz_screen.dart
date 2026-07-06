import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int durationMinutes;

  const QuizScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.durationMinutes,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isFinished = false;
  List<QueryDocumentSnapshot> _questions = [];
  bool _isLoading = true;

  final Map<int, int> _studentAnswers = {};

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .collection('questions')
          .get();

      setState(() {
        _questions = snapshot.docs;
        _isLoading = false;
      });

      if (_questions.isNotEmpty) {
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _calculateFinalScoreAndSubmit();
      }
    });
  }

  void _calculateFinalScoreAndSubmit() {
    int totalCorrect = 0;

    for (int i = 0; i < _questions.length; i++) {
      final questionData = _questions[i].data() as Map<String, dynamic>;
      final int correctAnswerIndex = questionData['correctAnswerIndex'] ?? 0;

      if (_studentAnswers.containsKey(i) &&
          _studentAnswers[i] == correctAnswerIndex) {
        totalCorrect++;
      }
    }

    _score = totalCorrect * 10;
    _saveQuizResult();

    setState(() {
      _isFinished = true;
    });
  }

  // REVISI PENYIMPANAN NAMA MAHASISWA AGAR AMAN DARI NULL / TIDAK TERDATA
  void _saveQuizResult() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final totalMaxScore = _questions.length * 10;
    double finalGrade = (_score / totalMaxScore) * 100;

    // Strategi berlapis: Deteksi Display Name -> Jika Kosong pakai Email -> Jika Kosong pakai Nama Default Rudi
    String resolvedName = 'Rudi Supriyadi';
    if (currentUser.displayName != null &&
        currentUser.displayName!.isNotEmpty) {
      resolvedName = currentUser.displayName!;
    } else if (currentUser.email != null && currentUser.email!.isNotEmpty) {
      // Memotong domain email agar rapi (misal rudi@unival.ac.id menjadi rudi)
      resolvedName = currentUser.email!.split('@')[0];
    }

    try {
      final Map<String, int> formattedAnswers = {};
      _studentAnswers.forEach((key, value) {
        formattedAnswers[key.toString()] = value;
      });

      await FirebaseFirestore.instance
          .collection('results')
          .doc('${currentUser.uid}_${widget.quizId}')
          .set({
            'userId': currentUser.uid,
            'studentName': resolvedName, // Menyimpan nama hasil filter berlapis
            'quizId': widget.quizId,
            'score': _score,
            'maxScore': totalMaxScore,
            'grade': finalGrade.round(),
            'answers': formattedAnswers,
            'completedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Gagal menyimpan nilai: $e");
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = _studentAnswers[_currentQuestionIndex];
      });
    } else {
      _timer?.cancel();
      _calculateFinalScoreAndSubmit();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _selectedAnswerIndex = _studentAnswers[_currentQuestionIndex];
      });
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: const Color(0xFF0F3BB1),
        ),
        body: const Center(child: Text('Belum ada pertanyaan untuk kuis ini.')),
      );
    }

    if (_isFinished) {
      final totalMaxScore = _questions.length * 10;
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'Kuis Selesai!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skor Akhir Kamu:',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  '$_score / $totalMaxScore',
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F3BB1),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3BB1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Kembali ke Dashboard',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion =
        _questions[_currentQuestionIndex].data() as Map<String, dynamic>;
    final String questionText = currentQuestion['questionText'] ?? '';
    final List<dynamic> options = currentQuestion['options'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3BB1),
        automaticallyImplyLeading: false,
        title: Text(
          '${_currentQuestionIndex + 1} / ${_questions.length}',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _remainingSeconds < 60
                  ? Colors.redAccent
                  : Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_remainingSeconds),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              questionText,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedAnswerIndex == index;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF0F3BB1).withAlpha(25)
                            : Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF0F3BB1)
                              : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedAnswerIndex = index;
                          _studentAnswers[_currentQuestionIndex] = index;
                        });
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: isSelected
                                ? const Color(0xFF0F3BB1)
                                : const Color(0xFFE2E8F0),
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              options[index].toString(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1E293B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF0F3BB1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'KEMBALI',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F3BB1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedAnswerIndex == null
                        ? null
                        : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3BB1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentQuestionIndex == _questions.length - 1
                          ? 'SELESAI'
                          : 'PERTANYAAN BERIKUTNYA',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
