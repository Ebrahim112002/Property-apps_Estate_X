import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  final List<String> bannerImages = [
    'https://i.ibb.co.com/zHh1Ymhn/image.png',
    'https://i.ibb.co.com/zH8DrSVx/image.png',
    'https://i.ibb.co.com/KxrTn5rS/image.png',
    'https://i.ibb.co.com/p6v4T8Lc/image.png',
    'https://i.ibb.co.com/60yPRTLT/image.png',
  ];

  int _currentIndex = 0;
  late Timer _timer;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner Carousel - Infinite Loop
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % bannerImages.length;
              });
            },
            itemCount: bannerImages.length * 100, // Large number for smooth infinite scroll
            itemBuilder: (context, index) {
              final realIndex = index % bannerImages.length;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    bannerImages[realIndex],
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 280,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 280,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Smooth Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            bannerImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: _currentIndex == index ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index ? AppColors.primary : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}