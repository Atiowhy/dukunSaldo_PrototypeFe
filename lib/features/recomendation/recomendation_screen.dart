import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:dukunsaldo_fe/service/finance_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecommendationPage extends StatefulWidget {
  final int refreshTrigger;

  const RecommendationPage({super.key, required this.refreshTrigger});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  bool _isLoading = true;
  RecommendationModel? _recData;

  @override
  void initState() {
    super.initState();
    _fetchAndAnalyzeData();
  }

  // 👈 DENGARKAN SINYAL PERUBAHAN SECARA REALTIME
  @override
  void didUpdateWidget(covariant RecommendationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _fetchAndAnalyzeData();
    }
  }

  Future<void> _fetchAndAnalyzeData() async {
    int activeUserId = Preference.userId;
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [activeUserId],
    );

    List<TransactionModel> transactions = maps
        .map((e) => TransactionModel.fromMap(e))
        .toList();

    // Jalankan kalkulator rekomendasi
    final data = FinanceAnalysisService.generateRecommendations(transactions);

    setState(() {
      _recData = data;
      _isLoading = false;
    });
  }

  String formatK(double amount) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)}k';
  }

  String formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff6BFB9A)),
      );
    }

    final data = _recData!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text(
              "Dukun Saldo Advisor",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Saran Cerdas untuk Keuanganmu",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),

            // --- HERO CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff6BFB9A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "AI Powered",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005E2D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Ramalan Dukun Saldo",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Dukun Saldo menganalisis riwayat transaksi Anda untuk memberikan ramalan penghematan terbaik.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(
                      Icons.settings_suggest,
                      size: 80,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- REKOMENDASI 1: GAYA HIDUP ---
            _buildSuggestionCard(
              theme: theme,
              isDarkMode: isDarkMode,
              colorBorder: const Color(0xFFFF6B6B),
              icon: Icons.coffee,
              iconBg: const Color(0xFFFFE5E5),
              iconColor: const Color(0xFFA00000),
              title: "Gaya Hidup",
              badgeText: "Urgent",
              badgeColor: const Color(0xFFA00000),
              description: data.lifestyleSavings > 0
                  ? "Pengeluaran Food & Beverage (termasuk kopi harian) ${data.lifestyleIncreasePercent > 0 ? 'meningkat ${data.lifestyleIncreasePercent.toStringAsFixed(0)}%' : 'mencapai ${formatRupiah(data.lifestyleSavings * 5)}'} bulan ini. Coba batasi jajan di luar minggu ini untuk menghemat ${formatK(data.lifestyleSavings)}."
                  : "Pengeluaran makanan bulan ini masih aman atau belum ada data. Teruskan kebiasaan berhematmu!",
              btn1Text: "Terapkan Saran",
              btn2Text: "Ingatkan Saya",
            ),
            const SizedBox(height: 16),

            // --- REKOMENDASI 2: SUBSCRIPTION ---
            _buildSuggestionCard(
              theme: theme,
              isDarkMode: isDarkMode,
              colorBorder: const Color(0xFF4C9AFF),
              icon: Icons.subscriptions,
              iconBg: const Color(0xFFE5F0FF),
              iconColor: const Color(0xFF0052CC),
              title: "Subscription Management",
              badgeText: "Optimasi",
              badgeColor: const Color(0xFF5A6B82),
              description: data.subscriptionCount > 0
                  ? "Ditemukan ${data.subscriptionCount} langganan layanan digital/streaming yang terdeteksi. Potensi penghematan ${formatK(data.subscriptionSavings)} per bulan jika ada yang dinonaktifkan."
                  : "Belum ada pengeluaran langganan digital yang membebani bulan ini. Pastikan tidak ada auto-debet terselubung!",
              btn1Text: "Kelola Langganan",
              btn2Text: "Nanti",
            ),
            const SizedBox(height: 16),

            // --- REKOMENDASI 3: TABUNGAN ---
            _buildSuggestionCard(
              theme: theme,
              isDarkMode: isDarkMode,
              colorBorder: const Color(0xff6BFB9A),
              icon: Icons.savings,
              iconBg: const Color(0xff6BFB9A).withOpacity(0.2),
              iconColor: const Color(0xFF005E2D),
              title: "Tabungan",
              badgeText: "Growth",
              badgeColor: const Color(0xFF005E2D),
              description: data.savingsTarget > 0
                  ? "Kamu punya potensi surplus saldo bulan ini. Masukkan ${formatK(data.savingsTarget)} ke tabungan darurat untuk capai target lebih cepat."
                  : "Saat ini pengeluaranmu cukup besar dibanding pemasukan bulan ini, atau belum ada surplus. Coba kurangi pengeluaran agar bisa menabung!",
              btn1Text: "Pindahkan Sekarang",
              btn2Text: "Ingatkan Besok",
            ),
            const SizedBox(height: 16),

            // --- BOTTOM CARD: POTENSI HEMAT ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4C9AFF).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Potensi Hemat",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupiah(data.totalPotentialSavings),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00875A),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          "/ bulan",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: data.totalPotentialSavings > 0 ? data.efficiencyProgress : 0.0,
                      backgroundColor: Colors.grey[300],
                      color: const Color(0xFF00875A),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.totalPotentialSavings > 0
                        ? "${(data.efficiencyProgress * 100).toStringAsFixed(0)}% dari target efisiensi keuangan Anda tercapai."
                        : "Belum ada cukup data untuk menghitung efisiensi bulan ini.",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // --- WIDGET REUSABLE UNTUK CARD SARAN (SUDAH DIPERBAIKI) ---
  // --- WIDGET REUSABLE UNTUK CARD SARAN (SUDAH DIPERBAIKI 100%) ---
  Widget _buildSuggestionCard({
    required ThemeData theme,
    required bool isDarkMode,
    required Color colorBorder,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required String description,
    required String btn1Text,
    required String btn2Text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: colorBorder, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 👇 BUNGKUSAN EXPANDED PERTAMA UNTUK ICON & JUDUL
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        // 👇 BUNGKUSAN EXPANDED KEDUA KHUSUS UNTUK TEKS AGAR TERPOTONG (...)
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 👇 BADGE TETAP AMAN DI KANAN
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F1E29),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {},
                      child: Text(
                        btn1Text,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        foregroundColor: theme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {},
                      child: Text(
                        btn2Text,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
