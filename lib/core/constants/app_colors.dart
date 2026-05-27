import 'package:flutter/material.dart';

class AppColors {
  // Warna Universal
  static const Color emeraldGreen = Color(0xFF10B981); // Hijau (Safe Status)
  static const Color primaryDark = Color(
    0xFF1A2B3C,
  ); // Biru Dongker (Primary LM)
  static const Color crimsonRed = Color(
    0xFFFB7185,
  ); // Merah Krimson (Danger Status)

  // Warna Aksen untuk Dark Mode
  static const Color accentGreen = Color(
    0xFF4ADE80,
  ); // Hijau Aksen Terang (Primary DM)

  // Warna Mentah Lainnya (Dari palet universal di image_10.png)
  static const Color amberYellow = Color(
    0xFFF59E0B,
  ); // (Kuning dari draf sebelumnya untuk Warning)

  // Latar belakang dan Permukaan
  static const Color lightScaffoldBackgroundColor = Color(
    0xFFF9FAFB,
  ); // Neutral (Latar Belakang)
  static const Color lightCardColor =
      Colors.white; // Permukaan Kartu / Container Putih

  // Teks
  static const Color lightPrimaryTextColor = Color(
    0xFF1A2B3C,
  ); // Primary (Hanken Grotesk / Inter)
  static const Color lightSecondaryTextColor = Color(
    0xFF475569,
  ); // Teks Sekunder (Subtitle/Label)

  // Tombol dan Aksesi
  static const Color lightPrimaryButtonColor = Color(0xFF1A2B3C); // Primary
  static const Color lightButtonTextColor = Colors.white;

  // Garis Pembatas (Border)
  static const Color lightBorderColor = Color(
    0xFFE2E8F0,
  ); // Border default mode terang

  // ==========================================================================
  // 3. PALETTE UNTUK DARK MODE (Tema Gelap - `image_11.png`)
  // ==========================================================================

  // Latar belakang dan Permukaan
  static const Color darkScaffoldBackgroundColor = Color(
    0xFF0A1219,
  ); // Secondary (Slate 950 kehitaman)
  static const Color darkCardColor = Color(
    0xFF1E293B,
  ); // Tertiary (Surface / Slate 800)

  // Teks
  static const Color darkPrimaryTextColor = Color(
    0xFFF9FAFB,
  ); // Teks Utama (Warna LM Neutral)
  static const Color darkSecondaryTextColor = Color(
    0xFF94A3B8,
  ); // Label (Slate 400 keabu-abuan)

  // Tombol dan Aksesi
  static const Color darkPrimaryButtonColor = Color(
    0xFF4ADE80,
  ); // Primary DM (Hijau Terang)
  static const Color darkButtonTextColor = Color(
    0xFF0A1219,
  ); // Teks di atas tombol hijau

  // Garis Pembatas (Border)
  static const Color darkBorderColor = Color(
    0xFF334155,
  ); // Border default mode gelap

  // shadow
  static const Color shadowCard = Color(0x33000000);
}
