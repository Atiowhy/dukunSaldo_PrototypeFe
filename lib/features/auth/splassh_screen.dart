import 'package:dukunsaldo_fe/core/constants/app_assets.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
import 'package:dukunsaldo_fe/features/home/home_screen.dart';
// import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
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
    if (!Preference.isLogin) {
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // logo
          Container(
            padding: EdgeInsets.only(top: 40, left: 20, bottom: 8, right: 20),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppAssets.logo, width: 32, height: 32),
                SizedBox(width: 8),
                Text(
                  "DUKUN SALDO",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          SizedBox(height: 100),
          // image splash
          Container(
            padding: EdgeInsets.only(bottom: 32),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    AppAssets.splash,
                    width: 320,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          // title
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  "Kendalikan Masa Depan Finansial Anda",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  "Prediksi arus kas cerdas dengan algoritma DES dan sistem peringatan dini (EWS) untuk keamanan dana Anda",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight(400)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
