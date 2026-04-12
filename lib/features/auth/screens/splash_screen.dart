import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // ৪ সেকেন্ড পর হোম স্ক্রিনে যাবে
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://i.ibb.co/XZqp0N2s/image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark Overlay + Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          ),

          // Gradient Overlay (Top to Bottom)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),

          // Main Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(_controller),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPremiumLogo(),
                      const SizedBox(height: 28),

                      // Brand Name
                      const Text(
                        "EstateX",
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.black87,
                              offset: Offset(3, 6),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Slogan
                      Text(
                        "Elevating Your Living Experience",
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      const SizedBox(height: 90),

                      // Loading Indicator
                      const SpinKitFoldingCube(color: Colors.white, size: 38),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumLogo() {
    return Container(
      height: 138,
      width: 138,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.transparent,
            child: const Center(
              child: Icon(
                Icons.home_work_rounded,
                size: 78,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
