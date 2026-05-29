import 'package:flutter/material.dart';

// Import model advisor agar class AdviceModel bisa dikenali
import '../models/advisor_model.dart';

// DUMMY DATA BERDASARKAN DESAIN FIGMA
final List<AdviceModel> adviceList = [
  AdviceModel(
    id: 'ADV-001',
    icon: Icons.coffee,
    title: 'Gaya Hidup',
    type: AdviceType.urgent,
    description:
        'Pengeluaran kopi meningkat 20% bulan ini. Coba batasi jajan di luar minggu ini untuk menghemat Rp 240k.',
    primaryButtonText: 'Terapkan Saran',
    secondaryButtonText: 'Ingatkan Saya',
  ),
  AdviceModel(
    id: 'ADV-002',
    icon: Icons.play_circle_outline,
    title: 'Subscription Management',
    type: AdviceType.optimasi,
    description:
        'Ditemukan 2 langganan streaming video yang jarang digunakan. Potensi penghematan Rp 159k per bulan jika dinonaktifkan.',
    primaryButtonText: 'Kelola Langganan',
    secondaryButtonText: 'Nanti',
  ),
  AdviceModel(
    id: 'ADV-003',
    icon: Icons.savings_outlined,
    title: 'Tabungan',
    type: AdviceType.growth,
    description:
        'Kamu punya potensi surplus saldo bulan ini. Masukkan Rp 500k ke tabungan darurat untuk capai target lebih cepat.',
    primaryButtonText: 'Pindahkan',
    secondaryButtonText: 'Ingatkan Besok',
  ),
];

// Data untuk bagian "Potensi Hemat" di paling bawah
final Map<String, dynamic> savingPotential = {
  'amount': 899000,
  'progressPercentage': 0.65, // 65%
};
