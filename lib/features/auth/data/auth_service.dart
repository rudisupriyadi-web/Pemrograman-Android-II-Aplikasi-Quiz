import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db =
      FirebaseFirestore.instance; // Instansiasi Firestore

  // =================================================================
  // 1. FUNGSI LOGIN DENGAN PENGECEKAN ROLE
  // =================================================================
  Future<Map<String, dynamic>> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = result.user;

      if (user != null) {
        // Tarik data dokumen pengguna dari Firestore berdasarkan UID
        DocumentSnapshot userDoc = await _db
            .collection('users')
            .doc(user.uid)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw 'Koneksi ke database habis waktu. Periksa jaringan Anda.',
            );

        if (userDoc.exists) {
          // Ambil data user termasuk role-nya
          return userDoc.data() as Map<String, dynamic>;
        } else {
          throw 'Data profil pengguna tidak ditemukan di database.';
        }
      }
      throw 'Gagal mendapatkan data pengguna.';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'Email tidak terdaftar.';
      } else if (e.code == 'wrong-password') {
        throw 'Password yang Anda masukkan salah.';
      } else if (e.code == 'invalid-email') {
        throw 'Format email tidak valid.';
      } else {
        throw 'Terjadi kesalahan: ${e.message}';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // =================================================================
  // 2. FUNGSI REGISTER DENGAN MENYIMPAN DATA KE FIRESTORE
  // =================================================================
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role, // Tambah parameter role
  ) async {
    try {
      // Mendaftarkan akun di Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = result.user;

      if (user != null) {
        // Perbarui Display Name di Firebase Auth
        await user.updateDisplayName(name);

        // Simpan data tambahan (nama, email, role) ke Cloud Firestore
        await _db
            .collection('users')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'nama': name,
              'email': email.trim(),
              'role': role,
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw 'Gagal menyimpan data ke server (Timeout).',
            );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw 'Password terlalu lemah. Minimal 6 karakter.';
      } else if (e.code == 'email-already-in-use') {
        throw 'Email tersebut sudah terdaftar oleh akun lain.';
      } else if (e.code == 'invalid-email') {
        throw 'Format email tidak valid.';
      } else {
        throw 'Terjadi kesalahan: ${e.message}';
      }
    } catch (e) {
      throw 'Tidak dapat mendaftarkan akun. Silakan coba lagi.';
    }
  }
}
