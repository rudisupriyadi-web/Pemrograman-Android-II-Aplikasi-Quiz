import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'quiz_screen.dart';
import 'review_quiz_screen.dart';

class DashboardMahasiswaPage extends StatelessWidget {
  const DashboardMahasiswaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0F3BB1),
        elevation: 0,
        title: Text(
          'UNIVAL QUIZ (MAHASISWA)',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Top Profil
            Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 32,
                top: 10,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0F3BB1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang Mahasiswa,',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          user?.displayName ?? 'Rudi Supriyadi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Konten Kuis Mata Kuliah
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Kuis Mata Kuliah',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // STREAMBUILDER DAFTAR KUIS UTAMA
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('quizzes')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              'Belum ada kuis yang tersedia saat ini.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }

                      final quizDocs = snapshot.data!.docs;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: quizDocs.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 2,
                          childAspectRatio: isMobile
                              ? 2.0
                              : 2.5, // Disesuaikan agar muat layout bertingkat baru
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemBuilder: (context, index) {
                          var quizData =
                              quizDocs[index].data() as Map<String, dynamic>;
                          String title = quizData['title'] ?? 'Mata Kuliah';
                          String subtitle =
                              quizData['subtitle'] ?? 'Detail Bab';
                          String quizId = quizDocs[index].id;
                          int duration = quizData['duration'] ?? 10;

                          IconData quizIcon =
                              title.toLowerCase().contains('citra')
                              ? Icons.image_search
                              : Icons.assignment_outlined;

                          // NESTED STREAMBUILDER: Membaca status rekam nilai hasil kuis
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('results')
                                .doc('${user?.uid}_$quizId')
                                .snapshots(),
                            builder: (context, resultSnapshot) {
                              bool isCompleted =
                                  resultSnapshot.hasData &&
                                  resultSnapshot.data!.exists;
                              int savedGrade = 0;
                              Map<String, dynamic> studentAnswers = {};

                              if (isCompleted) {
                                var resultData =
                                    resultSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                savedGrade = resultData['grade'] ?? 0;
                                studentAnswers = resultData['answers'] ?? {};
                              }

                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: isCompleted
                                    ? () {
                                        // SUDAH SELESAI -> MASUK HALAMAN REVIEW
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ReviewQuizScreen(
                                                  quizId: quizId,
                                                  quizTitle: title,
                                                  studentAnswers:
                                                      studentAnswers,
                                                ),
                                          ),
                                        );
                                      }
                                    : () {
                                        // BELUM SELESAI -> MULAI UJIAN KUIS
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (final context) =>
                                                QuizScreen(
                                                  quizId: quizId,
                                                  quizTitle: title,
                                                  durationMinutes: duration,
                                                ),
                                          ),
                                        );
                                      },
                                child: _buildQuizCard(
                                  title,
                                  subtitle, // Tetap mengirim subtitle asli (Keterangan Bab/Materi)
                                  quizIcon,
                                  isCompleted
                                      ? Colors.grey
                                      : const Color(0xFF0F3BB1),
                                  isCompleted: isCompleted,
                                  grade: savedGrade,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isCompleted = false,
    int grade = 0,
  }) {
    return Card(
      elevation: 2,
      color: isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted ? const Color(0xFFCBD5E1) : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                // Icon Kuis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),

                // Konten Teks Bertingkat
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle, // Menampilkan Keterangan Bab / Materi asli kuis
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Jika sudah selesai, selipkan status "Quiz Selesai" di bawahnya
                      if (isCompleted) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Quiz Selesai",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Badges Nilai jika kuis sudah selesai
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nilai: $grade',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),

            // Tambahan footer Review Interaktif untuk kuis yang sudah diselesaikan
            if (isCompleted) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Lihat Review Soal',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F3BB1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Color(0xFF0F3BB1),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
