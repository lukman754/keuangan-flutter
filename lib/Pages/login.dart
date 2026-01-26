import 'package:flutter/material.dart';
import 'package:flutter_tugas_uas/Components/custom_text_field.dart';
import 'package:flutter_tugas_uas/Components/custom_button.dart';
import 'package:flutter_tugas_uas/Database/database_helper.dart';
import 'package:flutter_tugas_uas/Services/auth_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'home.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password harus diisi!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;
      final user = await db.getUserByEmail(email);

      if (user == null) {
        _showMessage('Email tidak terdaftar!');
        setState(() => _isLoading = false);
        return;
      }

      final hashedPassword = _hashPassword(password);
      if (user['password'] != hashedPassword) {
        _showMessage('Password salah!');
        setState(() => _isLoading = false);
        return;
      }

      // Save session
      await AuthService.saveUserSession(
        userId: user['id'] as int,
        name: user['name'] as String,
        email: user['email'] as String,
      );

      if (!mounted) return;

      // Navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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

          // Login Content
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
                  children: [
                    // Logo Container
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E88E5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Finance Tracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const Text(
                      'Masuk ke akun Anda',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 30),

                    // Login Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : CustomButton(text: 'Masuk', onPressed: _handleLogin),
                    const SizedBox(height: 20),

                    // Register Link
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                      child: Text(
                        'Belum punya akun? Daftar',
                        style: TextStyle(
                          color: _isLoading
                              ? Colors.grey
                              : const Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold,
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
}
