import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. IMPORT FIRESTORE
import 'login_page.dart';
import 'create_quiz_page.dart';
import 'edit_quiz_page.dart';
import 'rekap_nilai_page.dart';

class DashboardDosenPage extends StatelessWidget {
  const DashboardDosenPage({super.key});

  // FUNGSI UNTUK MENGHAPUS KUIS DAN SUB-KOLEKSI SOALNYA
  void _deleteQuiz(BuildContext context, String quizId) async {
    try {
      // Ambil referensi kuis
      final quizRef = FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId);

      // Hapus semua soal di dalam sub-koleksi 'questions' terlebih dahulu
      final questionsSnapshot = await quizRef.collection('questions').get();
      for (var doc in questionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Hapus dokumen utama kuis
      await quizRef.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuis berhasil dihapus secara permanen.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus kuis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // DIALOG KONFIRMASI SEBELUM MENGHAPUS
  void _showDeleteDialog(
    BuildContext context,
    String quizId,
    String quizTitle,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Kuis?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus kuis "$quizTitle"? Mahasiswa tidak akan bisa mengakses kuis ini lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteQuiz(context, quizId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          'PANEL DOSEN UNIVAL',
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
            // Banner Profil Dosen
            Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 32,
                top: 10,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.supervisor_account,
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
                          'Selamat Datang Dosen,',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          user?.displayName ?? 'Dosen Pengajar',
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

            // Menu Utama Dosen
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Manajemen Kuis',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobile ? 1 : 2,
                    childAspectRatio: isMobile ? 2.5 : 3.0,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildMenuCard(
                        'Buat Soal Kuis Baru',
                        'Tambah kuis & pertanyaan baru',
                        Icons.add,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateQuizPage(),
                            ),
                          );
                        },
                      ),
                      _buildMenuCard(
                        'Rekap Nilai Mahasiswa',
                        'Lihat hasil pengerjaan kuis',
                        Icons.analytics_outlined,
                        Colors.orange,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RekapNilaiPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 2. DAFTAR KUIS YANG SUDAH DIBUAT (REAL-TIME STREAM)
                  Text(
                    'Daftar Kuis Aktif Anda',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('quizzes')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          alignment: Alignment.center,
                          child: Text(
                            'Anda belum mempublikasikan kuis apa pun.',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      final quizDocs = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: quizDocs.length,
                        itemBuilder: (context, index) {
                          var quizData =
                              quizDocs[index].data() as Map<String, dynamic>;
                          String title = quizData['title'] ?? 'Mata Kuliah';
                          String subtitle =
                              quizData['subtitle'] ?? 'Keterangan';
                          String quizId = quizDocs[index].id;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFEDF2F7),
                                child: Icon(
                                  Icons.assignment,
                                  color: Color(0xFF4A5568),
                                ),
                              ),
                              title: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                subtitle,
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Agar row tidak memakan space full kesamping
                                children: [
                                  // TOMBOL EDIT KUIS (BARU)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blueAccent,
                                    ),
                                    tooltip: 'Edit Kuis',
                                    onPressed: () {
                                      int duration = quizData['duration'] ?? 10;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditQuizPage(
                                            quizId: quizId,
                                            currentTitle: title,
                                            currentSubtitle: subtitle,
                                            currentDuration: duration,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // TOMBOL HAPUS KUIS (YANG LAMA TETAP ADA)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_sweep,
                                      color: Colors.redAccent,
                                    ),
                                    tooltip: 'Hapus Kuis',
                                    onPressed: () => _showDeleteDialog(
                                      context,
                                      quizId,
                                      title,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Widget _buildMenuCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
