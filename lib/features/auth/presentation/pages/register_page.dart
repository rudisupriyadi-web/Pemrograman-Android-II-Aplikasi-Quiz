import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/auth_service.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'mahasiswa';

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // FUNGSI UNTUK REGISTRASI (INI YANG BENAR UNTUK HALAMAN REGISTER)
  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi Berhasil! Silakan masuk menggunakan akun Anda.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); 
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            ClipPath(
              clipper: KubahClipper(),
              child: Container(
                height: isMobile ? screenSize.height * 0.35 : screenSize.height * 0.42,
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
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: isMobile ? 15 : 30),
                    Text(
                      'Daftar Akun',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 28 : 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Buat akun baru UNIVAL Quiz Anda',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 13 : 15,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 35), 
                    Card(
                      color: Colors.white,
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Text(
                                  'Silakan Isi Data',
                                  style: GoogleFonts.poppins(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _nameController,
                                style: GoogleFonts.inter(fontSize: 14),
                                validator: (value) => value == null || value.isEmpty ? 'Nama lengkap tidak boleh kosong' : null,
                                decoration: InputDecoration(
                                  hintText: 'Nama Lengkap',
                                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailController,
                                style: GoogleFonts.inter(fontSize: 14),
                                validator: (value) => value == null || value.isEmpty ? 'Email tidak boleh kosong' : null,
                                decoration: InputDecoration(
                                  hintText: 'Alamat Email',
                                  prefixIcon: const Icon(Icons.mail_outline, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _selectedRole,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                                dropdownColor: Colors.white,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'mahasiswa', child: Text('Mahasiswa')),
                                  DropdownMenuItem(value: 'dosen', child: Text('Dosen')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value ?? 'mahasiswa';
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.inter(fontSize: 14),
                                validator: (value) => value == null || value.length < 6 ? 'Password minimal 6 karakter' : null,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: GoogleFonts.inter(fontSize: 14),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                                  if (value != _passwordController.text) return 'Password tidak cocok';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Konfirmasi Password',
                                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E56DE),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text('DAFTAR SEKARANG', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Sudah punya akun? ', style: GoogleFonts.inter(fontSize: 13)),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Text('Login di sini', style: GoogleFonts.inter(color: const Color(0xFF1E56DE), fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
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
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}