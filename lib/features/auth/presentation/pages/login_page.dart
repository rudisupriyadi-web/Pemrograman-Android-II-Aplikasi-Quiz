import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/auth_service.dart';
// 1. IMPORT REGISTER PAGE: Agar halaman login mengenali halaman register
import 'register_page.dart';
import 'dashboard_mahasiswa_page.dart';
import 'dashboard_dosen_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Panggil fungsi login yang mengambil data user dari Firestore
      Map<String, dynamic> userData = await _authService
          .loginWithEmailAndPassword(
            _identifierController.text,
            _passwordController.text,
          );

      String role = userData['role'] ?? 'mahasiswa';
      String nama = userData['nama'] ?? 'Pengguna';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login Berhasil! Selamat Datang $nama.'),
            backgroundColor: Colors.green,
          ),
        );

        // PENGALIHAN HALAMAN ASLI BERDASARKAN ROLE FIRESTORE
        if (role == 'dosen') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardDosenPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardMahasiswaPage(),
            ),
          );
        }
      }
    } catch (errorMessage) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage.toString()),
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
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Background Lengkungan Kubah
            ClipPath(
              clipper: KubahClipper(),
              child: Container(
                height: isMobile
                    ? screenSize.height * 0.54
                    : screenSize.height * 1.0,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0F3BB1), Color(0xFF1E56DE)],
                  ),
                ),
              ),
            ),

            // Konten Utama
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: isMobile ? 10 : 24),

                    // Logo Universitas
                    Center(
                      child: Image.asset(
                        'assets/images/logo_unival.png',
                        height: isMobile ? 100 : 130,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.school,
                            size: 60,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Judul Aplikasi
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 24 : 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        children: const [
                          TextSpan(
                            text: 'UNIVAL ',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'QUIZ',
                            style: TextStyle(color: Color(0xFFFFDE00)),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDE00),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    Text(
                      'Aplikasi Quiz Online\nUniversitas Al-Khairiyah',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),

                    SizedBox(height: isMobile ? 15 : 25),

                    // Kartu Form Login
                    Card(
                      color: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Text(
                                  'Selamat Datang!',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Center(
                                child: Text(
                                  'Silakan masuk untuk melanjutkan',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 12 : 14,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobile ? 20 : 28),

                              // Input Email atau NIM
                              TextFormField(
                                controller: _identifierController,
                                style: GoogleFonts.inter(fontSize: 14),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Email/NIM tidak boleh kosong'
                                    : null,
                                decoration: InputDecoration(
                                  hintText: 'Email atau NIM',
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.mail_outline,
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Input Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.inter(fontSize: 14),
                                validator: (value) =>
                                    value == null || value.length < 6
                                    ? 'Password minimal 6 karakter'
                                    : null,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Ingat Saya & Lupa Password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: const Color(0xFF1E56DE),
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ingat saya',
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'Lupa password?',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF1E56DE),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Tombol MASUK
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E56DE),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                                        'MASUK',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // ATAU
                              const Row(
                                children: [
                                  Expanded(child: Divider()),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Text(
                                      'ATAU',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Tombol Google
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/logo_google.png',
                                      height: 18,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.g_mobiledata,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Masuk dengan Google',
                                      style: GoogleFonts.inter(
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Belum punya akun? Daftar sekarang
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Belum punya akun? ',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                  // 2. DI SINI PERUBAHANNYA: Navigator diaktifkan untuk pindah ke RegisterPage
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegisterPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Daftar sekarang',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF1E56DE),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Footer
                    const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF1E56DE),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Versi 1.0.0',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '© 2026 Universitas Al-Khairiyah',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KubahClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 35);

    var controlPoint = Offset(size.width / 2, size.height + 25);
    var endPoint = Offset(size.width, size.height - 35);

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
