import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/splassh_screen.dart'; // Typo dari file aslimu tetap dipertahankan agar tidak error import
import 'package:dukunsaldo_fe/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("id_id", null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Preference.init();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Dukun Saldo',
      debugShowCheckedModeBanner: false,

      // ==========================================
      // LIGHT THEME (Mode Terang)
      // ==========================================
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightScaffoldBackgroundColor,
        cardColor: AppColors.lightCardColor,
        primaryColor: AppColors.lightPrimaryTextColor,
        dividerColor: AppColors.lightBorderColor,
        shadowColor: AppColors.shadowCard,

        // ColorScheme Modern
        colorScheme: ColorScheme.light(
          primary: AppColors.lightPrimaryButtonColor,
          onPrimary: AppColors.lightButtonTextColor,
          surface: AppColors.lightCardColor,
          error: Colors.redAccent,
        ),

        // Pengaturan Text Global
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.lightPrimaryTextColor),
          bodyMedium: TextStyle(color: AppColors.lightSecondaryTextColor),
          headlineSmall: TextStyle(
            color: AppColors.lightPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Pengaturan AppBar Terang
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.lightPrimaryTextColor),
          titleTextStyle: TextStyle(
            color: AppColors.lightPrimaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),

        // Pengaturan Tombol
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightPrimaryButtonColor,
            foregroundColor: AppColors.lightButtonTextColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),

      // ==========================================
      // DARK THEME (Mode Gelap)
      // ==========================================
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkScaffoldBackgroundColor,
        cardColor: AppColors.darkCardColor,
        primaryColor: AppColors.darkPrimaryTextColor,
        dividerColor: AppColors.darkBorderColor,

        // ColorScheme Modern
        colorScheme: ColorScheme.dark(
          primary: AppColors.darkPrimaryButtonColor,
          onPrimary: AppColors.darkButtonTextColor,
          surface: AppColors.darkCardColor,
          error: const Color(0xFFFF6B6B),
        ),

        // Pengaturan Text Global
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.darkPrimaryTextColor),
          bodyMedium: TextStyle(color: AppColors.darkSecondaryTextColor),
          headlineSmall: TextStyle(
            color: AppColors.darkPrimaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Pengaturan AppBar Gelap
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.darkPrimaryTextColor),
          titleTextStyle: TextStyle(
            color: AppColors.darkPrimaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),

        // Pengaturan Tombol
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkPrimaryButtonColor,
            foregroundColor: AppColors.darkButtonTextColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
        ),
      ),

      // Mode Tema Dinamis
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
