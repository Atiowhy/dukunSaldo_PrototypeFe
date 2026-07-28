import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
import 'package:dukunsaldo_fe/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "icon": Icons.account_balance_wallet_outlined,
      "lottie": "assets/lottie/onboarding_1.json",
      "title": "Catat Keuangan Cerdas",
      "description":
          "Pantau setiap pemasukan dan pengeluaran Anda dengan mudah. Kategorikan transaksi untuk analisis yang lebih baik.",
    },
    {
      "icon": Icons.insights,
      "lottie": "assets/lottie/onboarding_2.json",
      "title": "Prediksi Masa Depan (DES)",
      "description":
          "Dengan algoritma Double Exponential Smoothing (DES), kami memprediksi arus kas Anda bulan depan secara akurat.",
    },
    {
      "icon": Icons.security,
      "lottie": "assets/lottie/onboarding_3.json",
      "title": "Sistem Peringatan Dini",
      "description":
          "Dapatkan peringatan otomatis (Early Warning System) jika pengeluaran Anda berisiko defisit. Aman & terkendali!",
    },
    {
      "icon": Icons.auto_awesome,
      "lottie": "assets/lottie/onboarding_4.json",
      "title": "AI Advisor Pribadi",
      "description":
          "Dapatkan rekomendasi untuk menghemat langganan dan gaya hidup agar target tabungan Anda cepat tercapai.",
    },
  ];

  void _onNext() async {
    if (_currentPage == _onboardingData.length - 1) {
      // Selesai onboarding
      await Preference.setHasSeenOnboarding(true);
      if (!mounted) return;
      if (Preference.isLogin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      }
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryAccent = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () async {
                  await Preference.setHasSeenOnboarding(true);
                  if (!mounted) return;
                  if (Preference.isLogin) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                    );
                  }
                },
                child: Text(
                  "Lewati",
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Container
                        TweenAnimationBuilder<double>(
                          key: ValueKey('icon_$index'),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutBack,
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width:
                                250, // Diperbesar sedikit agar Lottie terlihat jelas
                            height: 250,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Lottie.asset(
                                _onboardingData[index]["lottie"],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback ke Icon jika file lottie belum ada
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: primaryAccent.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _onboardingData[index]["icon"],
                                        size: 80,
                                        color: primaryAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        TweenAnimationBuilder<double>(
                          key: ValueKey('title_$index'),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _onboardingData[index]["title"],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          key: ValueKey('desc_$index'),
                          duration: const Duration(
                            milliseconds: 800,
                          ), // Slightly longer for staggered effect
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _onboardingData[index]["description"],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation (Dots & Button)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryAccent
                              : theme.dividerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Start Button
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _currentPage == _onboardingData.length - 1
                              ? "Mulai"
                              : "Lanjut",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_currentPage != _onboardingData.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
