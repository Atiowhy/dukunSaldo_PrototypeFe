// import 'package:dukunsaldo_fe/core/providers/theme_provider.dart';
import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:dukunsaldo_fe/service/finance_analysis_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';

class AdvisorPage extends StatefulWidget {
  final int refreshTrigger;
  const AdvisorPage({super.key, required this.refreshTrigger});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  bool _isLoading = true;
  AdvisorModel? _advisorData;

  @override
  void initState() {
    super.initState();
    _fetchAndAnalyzeData();
  }

  @override
  void didUpdateWidget(covariant AdvisorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika sinyal dari HomePage berubah (karena ada transaksi baru/dihapus)
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      // Tarik ulang data dari SQLite secara diam-diam di latar belakang!
      _fetchAndAnalyzeData();
    }
  }

  Future<void> _fetchAndAnalyzeData() async {
    int activeUserId = Preference.userId;
    final db = await DatabaseHelper.instance.database;

    // Ambil semua transaksi user ini
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [activeUserId],
      orderBy: 'id ASC',
    );

    List<TransactionModel> transactions = maps
        .map((e) => TransactionModel.fromMap(e))
        .toList();

    // Hitung total saldo saat ini untuk logika defisit
    double currentBalance = 0;
    for (var trx in transactions) {
      if (trx.type == 'income') {
        currentBalance += trx.amount;
      } else {
        currentBalance -= trx.amount;
      }
    }

    // Proses data melalui otak algoritma DES
    final data = FinanceAnalysisService.generateAdvisorData(
      transactions,
      currentBalance,
    );

    setState(() {
      _advisorData = data;
      _isLoading = false;
    });
  }

  String formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatCompact(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    }

    if (amount >= 1000) return 'Rp ${(amount / 1000).toStringAsFixed(1)}k';
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff6BFB9A)),
      );
    }

    final data = _advisorData!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text(
              "Analisis Prediksi",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Data terupdate hari ini pukul ${DateFormat('HH:mm').format(DateTime.now())} WIB",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),

            // --- KARTU 1: PREDIKSI UTAMA ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Prediksi Pengeluaran Bulan Depan",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: data.percentageChange > 0
                              ? const Color(0xFFFFD1D1)
                              : const Color(0xff6BFB9A).withAlpha(1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              data.percentageChange > 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 14,
                              color: data.percentageChange > 0
                                  ? const Color(0xFFA00000)
                                  : const Color(0xFF005E2D),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${data.percentageChange.abs().toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: data.percentageChange > 0
                                    ? const Color(0xFFA00000)
                                    : const Color(0xFF005E2D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatRupiah(data.nextMonthForecast),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Dihitung berdasarkan Double Exponential Smoothing",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- KARTU 2: WARNING DEFISIT (EWS) ---
            if (data.isDeficit)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB3B3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFA00000),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Potensi Defisit Terdeteksi!",
                            style: TextStyle(
                              color: Color(0xFFA00000),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Total pengeluaran Anda diprediksi melampaui sisa saldo sebesar ${formatRupiah(data.deficitAmount)}. Segera lakukan penyesuaian anggaran.",
                            style: const TextStyle(
                              color: Color(0xFFA00000),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (data.isDeficit) const SizedBox(height: 16),

            // --- KARTU 3 & 4: LEVEL DAN TREND ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bar_chart, color: Colors.grey, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Level (Rata-rata)",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatCompact(data.level),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Stabilitas pengeluaran dasar bulan ini.",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff6BFB9A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.trending_up,
                              color: Color(0xFF005E2D),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Trend (Kenaikan)",
                              style: TextStyle(
                                color: Color(0xFF005E2D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${data.trend >= 0 ? '+' : ''} ${formatCompact(data.trend)}",
                          style: const TextStyle(
                            color: Color(0xFF005E2D),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Laju akselerasi pengeluaran variabel.",
                          style: TextStyle(
                            color: Color(0xFF005E2D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            //  BAR CHART (ANGGARAN VS PREDIKSI) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Aktual vs Prediksi",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY:
                            (data.last3MonthsActual.reduce(
                                      (a, b) => a > b ? a : b,
                                    ) *
                                    1.5)
                                .clamp(100000.0, double.infinity),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = [
                                  'Bulan 1',
                                  'Bulan 2',
                                  'Bulan 3',
                                ];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    labels[value.toInt()],
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontSize: 12,
                                      fontWeight: value == 2
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) =>
                              FlLine(color: theme.dividerColor, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          for (int i = 0; i < 3; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: data.last3MonthsActual[i],
                                  color: const Color(0xFF0F1E29),
                                  width: 14,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: data.last3MonthsForecast[i],
                                  color: const Color(0xFFFF6B6B),
                                  width: 14,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F1E29),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Aktual",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B6B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Prediksi",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- KARTU 6: TIPS PROAKTIF ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.dividerColor.withAlpha(1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF0F1E29),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "Dukun Saldo Proaktif: ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text:
                                "Berdasarkan grafik tren, pengeluaran Anda cenderung naik ${formatCompact(data.trend)} tiap bulannya. Pertimbangkan untuk membatasi belanja tersier bulan depan.",
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                      style: TextStyle(color: theme.primaryColor),
                    ),
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
}
