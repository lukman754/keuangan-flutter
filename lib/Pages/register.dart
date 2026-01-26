import 'package:flutter/material.dart';
import 'package:flutter_tugas_uas/Components/custom_text_field.dart';
import 'package:flutter_tugas_uas/Components/custom_button.dart';
import 'package:flutter_tugas_uas/Database/database_helper.dart';
import 'package:flutter_tugas_uas/Services/auth_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Semua field harus diisi!', isError: true);
      return;
    }

    if (!email.contains('@')) {
      _showMessage('Format email tidak valid!', isError: true);
      return;
    }

    if (password.length < 6) {
      _showMessage('Password minimal 6 karakter!', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Password tidak cocok!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;

      // Check if email already exists
      final existingUser = await db.getUserByEmail(email);
      if (existingUser != null) {
        _showMessage('Email sudah terdaftar!', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Create user
      final now = DateTime.now().toIso8601String();
      final userId = await db.createUser({
        'name': name,
        'email': email,
        'password': _hashPassword(password),
        'created_at': now,
        'updated_at': now,
      });

      // Seed default categories for new user
      await db.seedDefaultCategories(userId);

      // Save session
      await AuthService.saveUserSession(
        userId: userId,
        name: name,
        email: email,
      );

      if (!mounted) return;

      _showMessage('Registrasi berhasil!', isError: false);

      // Navigate to home
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Background Shapes
          Positioned(
            top: -50,
            right: -50,
            child: _buildShape(220, isRing: true),
          ),
          Positioned(bottom: -60, left: -30, child: _buildShape(180)),
          Positioned(
            top: 100,
            left: -40,
            child: _buildShape(100, isRing: true),
          ),
          Positioned(bottom: 150, right: -20, child: _buildShape(80)),

          // Register Content
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(30),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Daftar Akun',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ),
                    const Center(
                      child: Text(
                        'Buat akun baru untuk memulai',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _label('Nama Lengkap'),
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Budi Santoso',
                      prefixIcon: Icons.person_outline,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    _label('Email'),
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'budi.santoso@email.com',
                      prefixIcon: Icons.email_outlined,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    _label('Password'),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    _label('Konfirmasi Password'),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 30),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            text: 'Daftar',
                            onPressed: _handleRegister,
                          ),
                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Sudah punya akun? Masuk',
                          style: TextStyle(
                            color: _isLoading
                                ? Colors.grey
                                : const Color(0xFF1E88E5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShape(double size, {bool isRing = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isRing
            ? Border.all(color: Colors.white.withOpacity(0.1), width: 10.0)
            : null,
        color: isRing ? Colors.transparent : Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}
