import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = SupabaseService();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(_emailController.text.trim(), _passwordController.text.trim());
      if (mounted) Navigator.pushReplacementNamed(context, '/profile');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

 // LoginScreen-এর build মেথডের ভেতর এই অংশটুকু আপডেট করুন
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        _buildBackground(),
        // --- ব্যাক বাটন শুরু ---
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // --- ব্যাক বাটন শেষ ---
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: _buildGlassCard(),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildBackground() => Container(
    decoration: const BoxDecoration(image: DecorationImage(image: NetworkImage('https://i.ibb.co.com/mrqpG5fg/image.png'), fit: BoxFit.cover)),
    child: Container(color: Colors.black.withOpacity(0.4)),
  );

  Widget _buildGlassCard() => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.3))),
        child: Column(
          children: [
            const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 30),
            _buildField(_emailController, "Email", Icons.email_outlined),
            const SizedBox(height: 15),
            _buildField(_passwordController, "Password", Icons.lock_outline, isObscure: true),
            const SizedBox(height: 30),
            _isLoading ? const CircularProgressIndicator(color: Colors.white) : _buildButton("Login", _login),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text("Don't have an account? Register", style: TextStyle(color: Colors.white70))),
          ],
        ),
      ),
    ),
  );

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false}) => TextField(
    controller: controller, obscureText: isObscure, style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white60), prefixIcon: Icon(icon, color: Colors.white70), filled: true, fillColor: Colors.white.withOpacity(0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
  );

  Widget _buildButton(String text, VoidCallback onPressed) => SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(text, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))));
}