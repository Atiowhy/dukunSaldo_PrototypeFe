import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/splassh_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_colors.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("id_id", null);
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Dukun Saldo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Light Mode
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightScaffoldBackgroundColor,
        cardColor: AppColors.lightCardColor,
        primaryColor: AppColors.lightPrimaryTextColor,
        dividerColor: AppColors.lightBorderColor,
        shadowColor: AppColors.shadowCard,

        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: AppColors.lightPrimaryTextColor,
            fontFamily: 'Inter',
          ),
          bodyMedium: TextStyle(
            color: AppColors.lightSecondaryTextColor,
            fontFamily: "Inter",
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightPrimaryButtonColor,
            foregroundColor: AppColors.lightButtonTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkScaffoldBackgroundColor,
        cardColor: AppColors.darkCardColor,
        primaryColor: AppColors.darkPrimaryTextColor,
        dividerColor: AppColors.darkBorderColor,

        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: AppColors.darkPrimaryTextColor,
            fontFamily: 'Inter',
          ),
          bodyMedium: TextStyle(
            color: AppColors.darkSecondaryTextColor,
            fontFamily: 'Inter',
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkPrimaryButtonColor,
            foregroundColor: AppColors.darkButtonTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: SplashScreen(),
    );
  }
}
