import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // এনিমেশন সেটআপ
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
);

    _controller.forward();

    // ৪ সেকেন্ড পর নেভিগেশন
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
          // ১. আপনার দেওয়া ইমেজটি ব্যাকগ্রাউন্ড হিসেবে (NetworkImage)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://i.ibb.co.com/tw3btv3g/image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ২. ইমেজের ওপর ব্লার এবং ডার্ক লেয়ার (Professional Glass Look)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(0.4), // ইমেজকে হালকা ডার্ক করা
              ),
            ),
          ),

          // ৩. মেইন কন্টেন্ট (Logo and Text)
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // আপডেট করা লোগো ডিজাইন
                    _buildPremiumLogo(),
                    const SizedBox(height: 25),
                    
                    // ব্র্যান্ড নেম
                    const Text(
                      "EstateX",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(blurRadius: 15, color: Colors.black54, offset: Offset(2, 4))
                        ],
                      ),
                    ),
                    
                    // স্লোগান
                    Text(
                      "Elevating Your Living Experience",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    
                    const SizedBox(height: 100),
                    
                    // লোডিং এনিমেশন
                    const SpinKitFoldingCube(
                      color: Colors.white,
                      size: 35.0,
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

  Widget _buildPremiumLogo() {
    return Container(
      height: 130,
      width: 130,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Icon(
              Icons.home_work_rounded, // এস্টেট রিলেটেড আইকন
              size: 75,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}