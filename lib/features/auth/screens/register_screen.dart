import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = SupabaseService();
  String _role = 'buyer';
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _role,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  // RegisterScreen-এর build মেথডের ভেতর এই অংশটুকু আপডেট করুন
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
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // --- ব্যাক বাটন শেষ ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: _buildGlassCard(),
            ),
          ),
        ],
      ),
    );
  }

  // Background and Field widgets same as LoginScreen...
  Widget _buildBackground() => Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: NetworkImage('https://i.ibb.co.com/mrqpG5fg/image.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: Container(color: Colors.black.withOpacity(0.4)),
  );

  Widget _buildGlassCard() => ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 25),
            _buildField(_nameController, "Full Name", Icons.person_outline),
            const SizedBox(height: 15),
            _buildField(_emailController, "Email", Icons.email_outlined),
            const SizedBox(height: 15),
            _buildField(
              _passwordController,
              "Password",
              Icons.lock_outline,
              isObscure: true,
            ),
            const SizedBox(height: 20),
            _buildRoleDropdown(),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : _buildButton("Register", _register),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Already have an account? Login",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildRoleDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _role,
        dropdownColor: Colors.blueGrey.shade900,
        isExpanded: true,
        style: const TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: 'buyer', child: Text("I am a Buyer")),
          DropdownMenuItem(value: 'seller', child: Text("I am a Seller/Agent")),
        ],
        onChanged: (v) => setState(() => _role = v!),
      ),
    ),
  );

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isObscure = false,
  }) => TextField(
    controller: controller,
    obscureText: isObscure,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    ),
  );

  Widget _buildButton(String text, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
