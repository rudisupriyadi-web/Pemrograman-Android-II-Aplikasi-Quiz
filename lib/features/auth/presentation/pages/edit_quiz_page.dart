import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// MODEL DATA UNTUK STRUKTUR EDIT SOAL
class EditQuestionModel {
  String? id; // Menyimpan ID Dokumen soal asli dari Firebase
  TextEditingController questionController;
  List<TextEditingController> optionControllers;
  int correctAnswerIndex;

  EditQuestionModel({
    this.id,
    required String question,
    required List<dynamic> options,
    required this.correctAnswerIndex,
  }) : questionController = TextEditingController(text: question),
       optionControllers = List.generate(
         4,
         (i) => TextEditingController(text: options[i].toString()),
       );

  void dispose() {
    questionController.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
  }
}

class EditQuizPage extends StatefulWidget {
  final String quizId;
  final String currentTitle;
  final String currentSubtitle;
  final int currentDuration;

  const EditQuizPage({
    super.key,
    required this.quizId,
    required this.currentTitle,
    required this.currentSubtitle,
    required this.currentDuration,
  });

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _durationController;

  final List<EditQuestionModel> _questionsList = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _subtitleController = TextEditingController(text: widget.currentSubtitle);
    _durationController = TextEditingController(
      text: widget.currentDuration.toString(),
    );
    // Ambil data soal dari sub-koleksi Firebase Firestore
    _fetchQuestions();
  }

  // FUNGSI UNTUK MENARIK DATA SOAL DARI FIREBASE
  void _fetchQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .collection('questions')
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data();
        _questionsList.add(
          EditQuestionModel(
            id: doc.id,
            question: data['questionText'] ?? '',
            options: data['options'] ?? ['', '', '', ''],
            correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal mengambil soal: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _durationController.dispose();
    for (var q in _questionsList) {
      q.dispose();
    }
    super.dispose();
  }

  // FUNGSI UNTUK MENYIMPAN PERUBAHAN KE FIREBASE
  void _updateQuizAndQuestions() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Update Data Utama Kuis
      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .update({
            'title': _titleController.text.trim(),
            'subtitle': _subtitleController.text.trim(),
            'duration': int.parse(_durationController.text.trim()),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // 2. Update Setiap Soal di Sub-Koleksi 'questions'
      final batch = FirebaseFirestore.instance.batch();

      for (var questionItem in _questionsList) {
        if (questionItem.id != null) {
          List<String> options = questionItem.optionControllers
              .map((c) => c.text.trim())
              .toList();

          DocumentReference docRef = FirebaseFirestore.instance
              .collection('quizzes')
              .doc(widget.quizId)
              .collection('questions')
              .doc(questionItem.id);

          batch.update(docRef, {
            'questionText': questionItem.questionController.text.trim(),
            'options': options,
            'correctAnswerIndex': questionItem.correctAnswerIndex,
          });
        }
      }

      await batch.commit(); // Eksekusi update massal data soal

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuis dan semua soal berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data kuis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Edit Informasi Kuis',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Efek loading saat tarik data soal
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ubah Data Kuis',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleController,
                      style: GoogleFonts.inter(fontSize: 14),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nama mata kuliah tidak boleh kosong'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Nama Mata Kuliah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _subtitleController,
                      style: GoogleFonts.inter(fontSize: 14),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Keterangan bab tidak boleh kosong'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Keterangan Bab / Materi',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(fontSize: 14),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Durasi kuis tidak boleh kosong'
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Durasi Kuis (Dalam Menit)',
                        prefixIcon: const Icon(Icons.timer),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Divider(thickness: 2),
                    const SizedBox(height: 12),

                    Text(
                      'Daftar Soal Pertanyaan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // RENDER FORM EDIT SOAL SECARA DINAMIS BERDASARKAN HASIL DATABASE
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _questionsList.length,
                      itemBuilder: (context, qIndex) {
                        var questionItem = _questionsList[qIndex];
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pertanyaan Soal ${qIndex + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F3BB1),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: questionItem.questionController,
                                  maxLines: 2,
                                  style: GoogleFonts.inter(fontSize: 14),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Teks pertanyaan tidak boleh kosong'
                                      : null,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Pilihan Jawaban & Kunci',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: List.generate(4, (oIndex) {
                                    String label = String.fromCharCode(
                                      65 + oIndex,
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<int>(
                                            value: oIndex,
                                            groupValue:
                                                questionItem.correctAnswerIndex,
                                            activeColor: const Color(
                                              0xFF1E56DE,
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                questionItem
                                                        .correctAnswerIndex =
                                                    value ?? 0;
                                              });
                                            },
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              controller: questionItem
                                                  .optionControllers[oIndex],
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                              ),
                                              validator: (value) =>
                                                  value == null || value.isEmpty
                                                  ? 'Pilihan $label wajib diisi'
                                                  : null,
                                              decoration: InputDecoration(
                                                labelText: 'Pilihan $label',
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 12,
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
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

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _updateQuizAndQuestions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E56DE),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'SIMPAN PERUBAHAN',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
