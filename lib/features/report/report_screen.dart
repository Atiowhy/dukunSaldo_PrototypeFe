import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:dukunsaldo_fe/service/finance_analysis_service.dart'; // 👈 Import Service-nya
import 'package:dukunsaldo_fe/service/pdf_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  final int? refreshTrigger;

  const ReportScreen({super.key, this.refreshTrigger});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isLoading = true;
  ReportModel? _reportData;

  final List<Color> _pieColors = [
    const Color(0xFF00875A),
    const Color(0xFF0F1E29),
    const Color(0xFFFF6B6B),
    const Color(0xFF4C9AFF),
    const Color(0xFFFFC400),
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  @override
  void didUpdateWidget(covariant ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _fetchReportData();
    }
  }

  Future<void> _fetchReportData() async {
    int activeUserId = Preference.userId;
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'userId = ? AND type = ?',
      whereArgs: [activeUserId, 'expense'],
    );

    List<TransactionModel> expenses = maps
        .map((e) => TransactionModel.fromMap(e))
        .toList();

    // 👇 Panggil "Dapur" Service secara rapi
    final dataMatang = FinanceAnalysisService.generateReportData(expenses);

    setState(() {
      _reportData = dataMatang;
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

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
      case 'makanan':
        return Icons.restaurant;
      case 'transport':
      case 'transportasi':
        return Icons.directions_car;
      case 'digital':
      case 'langganan':
        return Icons.devices;
      case 'shopping':
      case 'belanja':
        return Icons.shopping_bag;
      case 'gaji':
        return Icons.payments;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryAccent = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryAccent)),
      );
    }

    final data = _reportData!; // 👈 Gunakan data matang dari Model

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Laporan Bulanan",
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()),
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (data.currentMonthExpense == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Belum ada data untuk di-export bulan ini.",
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Menyiapkan PDF..."),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    await PdfService.generateAndExportReportPdf(data);
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 14),
                  label: const Text(
                    "PDF",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.grey[800]
                        : const Color(0xFF0F1E29),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KARTU TOTAL PENGELUARAN
            Container(
              width: double.infinity,
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
                    "Total Pengeluaran",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(data.currentMonthExpense),
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: data.expenseTrend <= 0
                          ? const Color(0xff6BFB9A).withOpacity(0.15)
                          : theme.colorScheme.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.expenseTrend <= 0
                              ? Icons.trending_down
                              : Icons.trending_up,
                          color: data.expenseTrend <= 0
                              ? const Color(0xFF00875A)
                              : theme.colorScheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.expenseTrend == 0
                              ? "Belum ada data bulan lalu"
                              : "${data.expenseTrend.abs().toStringAsFixed(1)}% ${data.expenseTrend <= 0 ? 'lebih rendah' : 'lebih tinggi'} dari bulan lalu",
                          style: TextStyle(
                            color: data.expenseTrend <= 0
                                ? const Color(0xFF00875A)
                                : theme.colorScheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KARTU AKURASI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    "Akurasi Prediksi DES",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: data.accuracyScore / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xff6BFB9A),
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Text(
                            "${data.accuracyScore}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Prediksi vs Realitas",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DONUT CHART
            if (data.topCategories.isNotEmpty)
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
                      "Pembagian Kategori",
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: Stack(
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                              sections: List.generate(
                                data.topCategories.length > 5
                                    ? 5
                                    : data.topCategories.length,
                                (index) {
                                  return PieChartSectionData(
                                    color:
                                        _pieColors[index % _pieColors.length],
                                    value:
                                        data.categoryPercentages[data
                                            .topCategories[index]
                                            .key] ??
                                        0,
                                    radius: 20,
                                    showTitle: false,
                                  );
                                },
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Total",
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  "${data.topCategories.length} Kat.",
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...List.generate(
                      data.topCategories.length > 5
                          ? 5
                          : data.topCategories.length,
                      (index) {
                        String catName = data.topCategories[index].key;
                        double percent = data.categoryPercentages[catName] ?? 0;
                        return _buildLegendItem(
                          catName,
                          "${percent.toStringAsFixed(1)}%",
                          _pieColors[index % _pieColors.length],
                          theme,
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (data.topCategories.isNotEmpty) const SizedBox(height: 24),

            // KATEGORI TERBOROS
            if (data.topCategories.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Kategori Terboros",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ],
              ),
            if (data.topCategories.isNotEmpty) const SizedBox(height: 16),

            ...List.generate(
              data.topCategories.length > 3 ? 3 : data.topCategories.length,
              (index) {
                var category = data.topCategories[index];
                bool isDanger = index == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildTopCategoryCard(
                    icon: _getCategoryIcon(category.key),
                    title: category.key,
                    subtitle: isDanger ? "Perlu Perhatian" : "Terpantau Aman",
                    amount: formatRupiah(category.value),
                    bgColor: isDanger
                        ? const Color(0xFFFFF5F5)
                        : theme.cardColor,
                    iconColor: isDanger ? Colors.redAccent : primaryAccent,
                    iconBgColor: isDanger
                        ? const Color(0xFFFFE5E5)
                        : primaryAccent.withOpacity(0.15),
                    borderColor: isDanger
                        ? Colors.redAccent
                        : Colors.transparent,
                    theme: theme,
                    isDanger: isDanger,
                  ),
                );
              },
            ),
            if (data.topCategories.isNotEmpty) const SizedBox(height: 20),

            // SARAN AHLI
            if (data.topCategories.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE5F9F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.psychology, color: primaryAccent),
                        const SizedBox(width: 8),
                        Text(
                          "Saran Ahli Dukun Saldo",
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF005E2D),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Pengeluaran kategori ${data.topCategories[0].key} adalah yang terbesar bulan ini (${formatRupiah(data.topCategories[0].value)}). Evaluasi kembali pengeluaran di kategori ini agar surplus bulan depan bisa lebih maksimal untuk ditabung.",
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white70
                            : const Color(0xFF005E2D),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            if (data.topCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.insert_chart_outlined,
                        size: 64,
                        color: theme.dividerColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada data pengeluaran bulan ini.",
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String title,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color bgColor,
    required Color iconColor,
    required Color iconBgColor,
    required Color borderColor,
    required ThemeData theme,
    required bool isDanger,
  }) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
            top: BorderSide(
              color: isDarkMode && !isDanger
                  ? theme.dividerColor
                  : Colors.transparent,
            ),
            right: BorderSide(
              color: isDarkMode && !isDanger
                  ? theme.dividerColor
                  : Colors.transparent,
            ),
            bottom: BorderSide(
              color: isDarkMode && !isDanger
                  ? theme.dividerColor
                  : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDanger
                          ? Colors.redAccent
                          : theme.textTheme.bodyMedium?.color,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: isDanger ? Colors.redAccent : theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
