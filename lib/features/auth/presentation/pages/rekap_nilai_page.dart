import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RekapNilaiPage extends StatelessWidget {
  const RekapNilaiPage({super.key});

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime) + ' WIB';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Rekap Nilai Mahasiswa',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('results')
            .orderBy('completedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Belum ada rekap nilai tersedia.',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                ),
              ),
            );
          }

          final resultDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: resultDocs.length,
            itemBuilder: (context, index) {
              var resultData = resultDocs[index].data() as Map<String, dynamic>;
              String quizId = resultData['quizId'] ?? '';
              String studentName =
                  resultData['studentName'] ??
                  'Nama Tidak Terdata'; // Baca field nama
              int grade = resultData['grade'] ?? 0;
              var completedAt = resultData['completedAt'];

              // Mengambil info detail kuis untuk memastikan kuisnya masih ada
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('quizzes')
                    .doc(quizId)
                    .get(),
                builder: (context, quizSnapshot) {
                  // REVISI UTAMA: Jika data kuis sudah dihapus dosen, hilangkan dari list rekap nilai
                  if (quizSnapshot.hasData && !quizSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  String quizTitle = 'Mata Kuliah';
                  String quizSubtitle = '';

                  if (quizSnapshot.hasData && quizSnapshot.data!.exists) {
                    var quizData =
                        quizSnapshot.data!.data() as Map<String, dynamic>;
                    quizTitle = quizData['title'] ?? 'Mata Kuliah';
                    quizSubtitle = quizData['subtitle'] ?? '';
                  }

                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEDF2F7),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Menampilkan Nama Mahasiswa di baris paling atas
                                Text(
                                  studentName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Menampilkan Info Kuis Mata Kuliah
                                Text(
                                  '$quizTitle ($quizSubtitle)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _formatTimestamp(completedAt),
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: grade >= 70
                                  ? const Color(0xFF10B981)
                                  : Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Score: $grade',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
