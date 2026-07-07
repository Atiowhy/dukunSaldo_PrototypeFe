import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/firebase_db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:dukunsaldo_fe/service/finance_analysis_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdvisorPage extends StatefulWidget {
  final int refreshTrigger;
  const AdvisorPage({super.key, required this.refreshTrigger});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  bool _isLoading = true;
  AdvisorModel? _advisorData;
  double _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _fetchAndAnalyzeData();
  }

  @override
  void didUpdateWidget(covariant AdvisorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _fetchAndAnalyzeData();
    }
  }

  Future<void> _fetchAndAnalyzeData() async {
    int activeUserId = Preference.userId;
    List<TransactionModel> transactions = await FirebaseDbHelper.instance.getTransactionsByUserId(activeUserId);
    transactions.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

    double currentBalance = 0;
    for (var trx in transactions) {
      if (trx.type == 'income') {
        currentBalance += trx.amount;
      } else {
        currentBalance -= trx.amount;
      }
    }

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
    bool isNegative = amount < 0;
    double absAmount = amount.abs();
    String prefix = isNegative ? "-" : "";
    if (absAmount >= 1000000) {
      String val = (absAmount / 1000000).toStringAsFixed(2);
      if (val.endsWith('.00')) {
        val = val.substring(0, val.length - 3);
      } else if (val.endsWith('0')) {
        val = val.substring(0, val.length - 1);
      }

      return 'Rp $prefix${val}Jt';
    }
    if (absAmount >= 1000) {
      String val = (absAmount / 1000).toStringAsFixed(2);
      if (val.endsWith('.00')) {
        val = val.substring(0, val.length - 3);
      } else if (val.endsWith('0')) {
        val = val.substring(0, val.length - 1);
      }

      return 'Rp $prefix${val}Rb';
    }
    return 'Rp $prefix${absAmount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Warna Dinamis
    final primaryAccent = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;
    final errorColor = theme.colorScheme.error;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryAccent));
    }

    final data = _advisorData!;

    double lastMonthActual = 0;
    double currentMonthActual = 0;
    if (data.last3MonthsActual.length >= 2) {
      lastMonthActual = data.last3MonthsActual[1];
      currentMonthActual = data.last3MonthsActual[2];
    }
    double realDifference = currentMonthActual - lastMonthActual;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: 120,
        ),
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
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // --- KARTU 1: PREDIKSI UTAMA (MODERN GRADIENT) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          AppColors.darkCardColor,
                          AppColors.darkScaffoldBackgroundColor,
                        ]
                      : [
                          AppColors.lightPrimaryButtonColor,
                          const Color(0xFF003B1C),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryAccent.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -10,
                    child: Icon(
                      Icons.online_prediction,
                      size: 100,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 👇 DIPERBAIKI: Dibungkus Expanded agar aman di layar kecil
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: 8,
                              ), // Jarak ke persentase
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Prediksi Pengeluaran Bulan Depan",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: data.percentageChange > 0
                                  ? errorColor.withOpacity(0.2)
                                  : primaryAccent.withOpacity(0.2),
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
                                      ? const Color(0xFFFFB3B3)
                                      : primaryAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${data.percentageChange.abs().toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: data.percentageChange > 0
                                        ? const Color(0xFFFFB3B3)
                                        : primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: data
                              .nextMonthForecast, // Target animasinya adalah nilai forecast
                        ),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutExpo,
                        builder: (context, value, child) {
                          return Text(
                            formatRupiah(
                              value,
                            ), // 'value' sudah berupa double, langsung masukkan ke formatRupiah
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        "Dihitung berdasarkan Double Exponential Smoothing",
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
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
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: errorColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Potensi Defisit Terdeteksi!",
                            style: TextStyle(
                              color: errorColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Total pengeluaran Anda diprediksi melampaui sisa saldo sebesar ${formatRupiah(data.deficitAmount)}. Segera lakukan penyesuaian anggaran.",
                            style: TextStyle(
                              color: isDarkMode ? Colors.red[200] : errorColor,
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

            // --- KARTU 3 & 4: LEVEL DAN TREND (MODERN OUTLINE) ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    // 👇 DIPERBAIKI: Padding dikurangi sedikit agar muat di HP kecil
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              color: theme.textTheme.bodyMedium?.color,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            // 👇 DIPERBAIKI: Dibungkus Expanded dan Ellipsis
                            Expanded(
                              child: Text(
                                "Level (Rata-rata)",
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatCompact(data.level),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Stabilitas pengeluaran dasar bulan ini.",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    // 👇 DIPERBAIKI: Padding dikurangi sedikit agar muat di HP kecil
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: data.trend > 0
                            ? errorColor.withOpacity(0.3)
                            : primaryAccent.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: data.trend > 0
                              ? errorColor.withOpacity(0.05)
                              : primaryAccent.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              data.trend > 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: data.trend > 0
                                  ? errorColor
                                  : primaryAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data.trend > 0
                                    ? "Trend (Kenaikan)"
                                    : "Trend (Penurunan)",
                                style: TextStyle(
                                  color: data.trend > 0
                                      ? errorColor
                                      : primaryAccent,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${data.trend > 0 ? '+' : '-'} ${formatCompact(data.trend.abs())}",
                          style: TextStyle(
                            color: data.trend > 0 ? errorColor : primaryAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Laju akselerasi pengeluaran variabel.",
                          style: TextStyle(
                            color: isDarkMode
                                ? (data.trend > 0
                                      ? errorColor.withOpacity(0.8)
                                      : primaryAccent.withOpacity(0.8))
                                : theme.textTheme.bodyMedium?.color,
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

            // --- KARTU 5: BAR CHART (ANGGARAN VS PREDIKSI) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
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
                                final labels = data.last3MonthsLabels;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    labels[value.toInt()],
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
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
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.dividerColor,
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          for (int i = 0; i < 3; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: data.last3MonthsActual[i],
                                  color: isDarkMode
                                      ? Colors.white70
                                      : const Color(0xFF0F1E29),
                                  width: 14,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: data.last3MonthsForecast[i],
                                  color: primaryAccent,
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
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white70
                              : const Color(0xFF0F1E29),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Aktual",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Prediksi",
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- KARTU 6: TIPS PROAKTIF (MODERN BANNER) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryAccent.withOpacity(0.1), theme.cardColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryAccent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: primaryAccent, size: 20),
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
                            text: data.isDeficit
                                ? "Peringatan! Pengeluaran Anda bulan ini ${realDifference > 0 ? 'naik sebesar ${formatCompact(realDifference.abs())}' : realDifference < 0 ? 'turun sebesar ${formatCompact(realDifference.abs())}' : 'cenderung stabil'}, NAMUN prediksi bulan depan (${formatCompact(data.nextMonthForecast)}) berpotensi melampaui sisa saldo Anda saat ini. Segera kurangi pengeluaran agar terhindar dari defisit!"
                                : (realDifference > 0
                                      ? "Pengeluaran Anda bulan ini nyata naik sebesar ${formatCompact(realDifference.abs())} dari bulan lalu. Jika dibiarkan, AI memprediksi pengeluaran bulan depan bisa mencapai ${formatCompact(data.nextMonthForecast)}. Pertimbangkan untuk membatasi belanja tersier."
                                      : (realDifference < 0
                                            ? "Bagus! Pengeluaran Anda bulan ini berhasil ditekan turun sebesar ${formatCompact(realDifference.abs())}. AI memprediksi Anda bisa menekan pengeluaran bulan depan hingga ${formatCompact(data.nextMonthForecast)}. Pertahankan kebiasaan baik ini!"
                                            : "Pengeluaran Anda bulan ini sangat stabil. AI memprediksi pengeluaran bulan depan akan berada di kisaran ${formatCompact(data.nextMonthForecast)}. Terus pertahankan pengelolaan keuangan Anda!")),
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
