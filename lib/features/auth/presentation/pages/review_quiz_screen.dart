import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewQuizScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final Map<String, dynamic>
  studentAnswers; // Menerima data jawaban dari dashboard

  const ReviewQuizScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.studentAnswers,
  });

  @override
  State<ReviewQuizScreen> createState() => _ReviewQuizScreenState();
}

class _ReviewQuizScreenState extends State<ReviewQuizScreen> {
  List<QueryDocumentSnapshot> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3BB1),
        title: Text(
          'Review Kuis: ${widget.quizTitle}',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final questionData =
                    _questions[index].data() as Map<String, dynamic>;
                final String questionText = questionData['questionText'] ?? '';
                final List<dynamic> options = questionData['options'] ?? [];
                final int correctAnswerIndex =
                    questionData['correctAnswerIndex'] ?? 0;

                // Ambil jawaban mahasiswa untuk nomor ini (bisa bertipe int atau null kalau tidak dijawab)
                final int? studentAnswerIndex =
                    widget.studentAnswers[index.toString()];

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Nomor Soal & Status Benar/Salah/Kosong
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Soal Nomor ${index + 1}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            if (studentAnswerIndex == null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Tidak Dijawab',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (studentAnswerIndex == correctAnswerIndex)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Benar',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Salah',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          questionText,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Menampilkan Pilihan Opsi Ganda dengan Indikator Warna Warna Cerdas
                        Column(
                          children: List.generate(options.length, (oIndex) {
                            final isCorrectOption =
                                oIndex == correctAnswerIndex;
                            final isStudentChoice =
                                oIndex == studentAnswerIndex;

                            Color itemColor = Colors.transparent;
                            Color borderColor = const Color(0xFFE2E8F0);
                            Widget? trailingIcon;

                            if (isCorrectOption) {
                              // Kunci jawaban asli selalu disorot hijau lembut
                              itemColor = Colors.green.withValues(alpha: 0.15);
                              borderColor = Colors.green;
                              trailingIcon = const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              );
                            } else if (isStudentChoice && !isCorrectOption) {
                              // Pilihan mahasiswa salah disorot merah lembut
                              itemColor = Colors.red.withValues(alpha: 0.15);
                              borderColor = Colors.red;
                              trailingIcon = const Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 20,
                              );
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: itemColor,
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isCorrectOption
                                        ? Colors.green
                                        : (isStudentChoice
                                              ? Colors.red
                                              : const Color(0xFFE2E8F0)),
                                    child: Text(
                                      String.fromCharCode(65 + oIndex),
                                      style: TextStyle(
                                        color:
                                            isCorrectOption || isStudentChoice
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      options[oIndex].toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (trailingIcon != null) trailingIcon,
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
