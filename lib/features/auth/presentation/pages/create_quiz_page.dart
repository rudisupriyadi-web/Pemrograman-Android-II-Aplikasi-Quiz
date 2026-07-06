import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. MODEL DATA UNTUK MENAMPUNG STRUKTUR SOAL SECARA DINAMIS
class QuestionModel {
  TextEditingController questionController = TextEditingController();
  List<TextEditingController> optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int correctAnswerIndex = 0;

  void dispose() {
    questionController.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
  }
}

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _durationController =
      TextEditingController(); // Controller untuk waktu menit

  // List dinamis untuk menampung kumpulan soal
  final List<QuestionModel> _questionsList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Secara default, otomatis tambahkan soal pertama saat halaman dibuka
    _addNewQuestion();
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

  // Fungsi menambah form soal baru
  void _addNewQuestion() {
    setState(() {
      _questionsList.add(QuestionModel());
    });
  }

  // Fungsi menghapus soal berdasarkan index tertentu
  void _removeQuestion(int index) {
    if (_questionsList.length > 1) {
      setState(() {
        _questionsList[index].dispose();
        _questionsList.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kuis minimal harus memiliki 1 soal!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _submitQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Simpan header Utama Kuis ke Dokumen Induk 'quizzes'
      final quizRef = await FirebaseFirestore.instance
          .collection('quizzes')
          .add({
            'title': _titleController.text.trim(),
            'subtitle': _subtitleController.text.trim(),
            'duration': int.parse(_durationController.text.trim()),
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 2. Loop & Simpan seluruh soal yang ada di list ke Sub-Koleksi 'questions'
      for (var questionData in _questionsList) {
        List<String> options = questionData.optionControllers
            .map((c) => c.text.trim())
            .toList();

        await quizRef.collection('questions').add({
          'questionText': questionData.questionController.text.trim(),
          'options': options,
          'correctAnswerIndex': questionData.correctAnswerIndex,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuis Berhasil Dipublikasikan Bersama Semua Soal!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat kuis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          'Buat Kuis Baru',
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informasi Kuis',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(fontSize: 14),
                validator: (value) => value == null || value.isEmpty
                    ? 'Nama mata kuliah tidak boleh kosong'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Nama Mata Kuliah',
                  hintText: 'Contoh: Pengelolaan Citra Digital',
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
                  hintText: 'Contoh: Bab 2: Pembentukan Citra',
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
                keyboardType: TextInputType.number, // Memaksa keyboard angka
                style: GoogleFonts.inter(fontSize: 14),
                validator: (value) => value == null || value.isEmpty
                    ? 'Durasi waktu tidak boleh kosong'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Durasi Kuis (Dalam Menit)',
                  hintText: 'Contoh: 30',
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

              // LIST DINAMIS FORM INPUT PERTANYAAN-PERTANYAAN
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questionsList.length,
                itemBuilder: (context, qIndex) {
                  var questionItem = _questionsList[qIndex];
                  return Card(
                    color: Colors.white,
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Soal (Nomor & Tombol Hapus)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Input Pertanyaan (Soal ${qIndex + 1})',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F3BB1),
                                ),
                              ),
                              // Tombol Hapus Soal Terkait
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Hapus Soal Ini',
                                onPressed: () => _removeQuestion(qIndex),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Input Text Soal
                          TextFormField(
                            controller: questionItem.questionController,
                            maxLines: 2,
                            style: GoogleFonts.inter(fontSize: 14),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Teks pertanyaan tidak boleh kosong'
                                : null,
                            decoration: InputDecoration(
                              hintText: 'Ketik pertanyaan kuis di sini...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Pilihan Jawaban & Kunci',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Form 4 Pilihan Ganda (A, B, C, D)
                          Column(
                            children: List.generate(4, (oIndex) {
                              String label = String.fromCharCode(65 + oIndex);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: oIndex,
                                      groupValue:
                                          questionItem.correctAnswerIndex,
                                      activeColor: const Color(0xFF1E56DE),
                                      onChanged: (value) {
                                        setState(() {
                                          questionItem.correctAnswerIndex =
                                              value ?? 0;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: questionItem
                                            .optionControllers[oIndex],
                                        style: GoogleFonts.inter(fontSize: 13),
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Pilihan $label wajib diisi'
                                            : null,
                                        decoration: InputDecoration(
                                          labelText: 'Pilihan $label',
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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

              // BUTTON TAMBAH SOAL BARU
              OutlinedButton.icon(
                onPressed: _addNewQuestion,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF1E56DE), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, color: Color(0xFF1E56DE)),
                label: Text(
                  'TAMBAH PERTANYAAN BARU',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E56DE),
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(thickness: 1.5),
              const SizedBox(height: 16),

              // BUTTON SIMPAN DAN PUBLIKASIKAN KUIS
              ElevatedButton(
                onPressed: _isLoading ? null : _submitQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E56DE),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'SIMPAN & PUBLIKASIKAN KUIS',
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
