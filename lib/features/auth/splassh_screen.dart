import 'dart:ui';
import 'package:dukunsaldo_fe/core/constants/app_assets.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
import 'package:dukunsaldo_fe/features/home/home_screen.dart';
import 'package:dukunsaldo_fe/features/onboarding/onboarding_screen.dart';
import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    
    if (!Preference.hasSeenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else if (!Preference.isLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Warna aksen untuk gradient/blob
    final primaryAccent = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ==============================
          // BACKGROUND ABSTRACT BLOBS
          // ==============================
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(isDarkMode ? 0.2 : 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF00875A,
                ).withOpacity(isDarkMode ? 0.3 : 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF4C9AFF,
                ).withOpacity(isDarkMode ? 0.2 : 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ==============================
          // GLASSMORPHISM BLUR LAYER
          // ==============================
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
              child: Container(
                color: theme.scaffoldBackgroundColor.withOpacity(0.6),
              ),
            ),
          ),

          // ==============================
          // FOREGROUND CONTENT
          // ==============================
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bagian Atas: Logo
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Image.asset(
                          AppAssets.logo,
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "DUKUN SALDO",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bagian Tengah: Ilustrasi
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDarkMode ? 0.05 : 0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.splash,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Bagian Bawah: Teks & Loading
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 60,
                    left: 32,
                    right: 32,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Kendalikan Masa Depan Finansial Anda",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Prediksi arus kas cerdas dengan algoritma DES dan sistem peringatan dini (EWS) untuk keamanan dana Anda.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Indikator Loading Custom
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryAccent,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
