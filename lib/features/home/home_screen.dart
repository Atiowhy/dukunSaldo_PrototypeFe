import 'package:dukunsaldo_fe/core/providers/theme_provider.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
import 'package:dukunsaldo_fe/features/transactions/add_transaction_screen.dart';
// import 'package:dukunsaldo_fe/models/transactions_model.dart'; // Pastikan path model ini sesuai
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../advisor/advisor_screen.dart';
import '../recomendation/recomendation_screen.dart';
import '../history/transaction_history_screen.dart';
import '../../database/db_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedDropdown;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int _selectedIndex = 0;
  List<Map<String, dynamic>> _localTransactions = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logOut() async {
    await Preference.logOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  String formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _fetchTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'id DESC',
    );

    setState(() {
      _localTransactions = maps;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildHomeContent(theme, isDarkMode),
      const AdvisorPage(),
      const RecommendationPage(),
    ];

    final String userEmail = Preference.email.isEmpty
        ? "Guest"
        : Preference.email;
    final String userName = Preference.username;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          userName,
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
        actions: [
          Icon(Icons.notifications_active, color: theme.primaryColor),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _buildDrawer(
        userEmail,
        userName,
        theme,
        themeProvider,
        isDarkMode,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F1E29),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Color(0xff6BFB9A), size: 28),
        onPressed: () async {
          final bool? isDataChanged = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );

          if (isDataChanged == true) {
            _fetchTransactions(); 
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: "Ramalan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline),
            label: "Rekomendasi",
          ),
        ],
        currentIndex: _selectedIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: const Color(0xff6BFB9A),
        onTap: _onItemTapped,
        backgroundColor: theme.cardColor,
      ),
    );
  }

  Widget _buildDrawer(
    String userEmail,
    String userName,
    ThemeData theme,
    ThemeProvider themeProvider,
    bool isDarkMode,
  ) {
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.cardColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.account_circle,
                      size: 60,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userEmail,
                  style: TextStyle(color: theme.primaryColor, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: theme.primaryColor),
            title: Text("Beranda", style: TextStyle(color: theme.primaryColor)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: theme.primaryColor),
            title: Text(
              "Pengaturan",
              style: TextStyle(color: theme.primaryColor),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.logout_outlined, color: theme.primaryColor),
            title: Text("Logout", style: TextStyle(color: theme.primaryColor)),
            onTap: _logOut,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 24),
            child: Row(
              children: [
                Switch(
                  value: isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
                Text(
                  isDarkMode ? "Dark Mode" : "Light Mode",
                  style: TextStyle(color: theme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(ThemeData theme, bool isDarkMode) {

    final List<Map<String, dynamic>> displayList = _localTransactions;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(theme, isDarkMode),
            const SizedBox(height: 24),
            _buildPredictionChart(theme, isDarkMode),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Riwayat Transaksi",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionHistoryScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Lihat Semua",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? const Color(0xff6BFB9A)
                          : const Color(0xFF005E2D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            displayList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Belum ada transaksi secara lokal.\nKlik tombol + untuk menambahkan!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.disabledColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayList.length > 4 ? 4 : displayList.length,
                    itemBuilder: (context, index) {
                      final trx = displayList[index];

                      final String merchantName =
                          trx['merchantName'] ?? 'Transaksi';
                      final String category = trx['category'] ?? 'Umum';
                      final double amount =
                          (trx['amount'] as num?)?.toDouble() ?? 0.0;
                      final bool isIncome = trx['type'] == 'income';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isIncome
                                  ? Icons.arrow_circle_down
                                  : Icons.shopping_bag_outlined,
                              size: 38,
                              color: isIncome
                                  ? const Color(0xff6BFB9A)
                                  : theme.primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    merchantName,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    category,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${isIncome ? '+' : '-'} Rp. ${formatRupiah(amount.toInt())}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isIncome
                                    ? (isDarkMode
                                          ? const Color(0xff6BFB9A)
                                          : Colors.green)
                                    : const Color(0xffBA1A1A),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? theme.cardColor : const Color(0xFF263238),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Saldo Saat Ini",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            "Rp 128.450.000",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.trending_up, color: Color(0xff6BFB9A), size: 16),
              SizedBox(width: 4),
              Text(
                "+2.4% dari bulan lalu",
                style: TextStyle(color: Color(0xff6BFB9A), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionChart(ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prediksi Arus Kas",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Analisis DES (Double Exponential Smoothing)",
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF005E2D),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Riil",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
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
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: theme.dividerColor, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final style = theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        );
                        switch (value.toInt()) {
                          case 0:
                            return Text('Jan', style: style);
                          case 1:
                            return Text('Feb', style: style);
                          case 2:
                            return Text('Mar', style: style);
                          case 3:
                            return Text('Apr', style: style);
                          case 4:
                            return Text(
                              'Mei',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 2.2),
                      FlSpot(2, 1.8),
                      FlSpot(3, 3),
                    ],
                    isCurved: true,
                    color: isDarkMode
                        ? const Color(0xff6BFB9A)
                        : const Color(0xFF005E2D),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          (isDarkMode
                                  ? const Color(0xff6BFB9A)
                                  : const Color(0xFF005E2D))
                              .withAlpha(1),
                    ),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(3, 3),
                      FlSpot(3.5, 3.8),
                      FlSpot(4, 4.2),
                    ],
                    isCurved: true,
                    color: isDarkMode ? Colors.white : const Color(0xFF0D1C2D),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const Color(0xff000000) is FlDotData
                        ? const FlDotData(show: false)
                        : const FlDotData(show: false),
                    dashArray: [8, 4],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF005E2D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Pemasukan",
                  style: TextStyle(color: Color(0xFF005E2D), fontSize: 12),
                ),
                const Text(
                  "Rp 45.2M",
                  style: TextStyle(
                    color: Color(0xFF005E2D),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
              color: const Color(0xFFFFD1D1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFA00000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Pengeluaran",
                  style: TextStyle(color: Color(0xFFA00000), fontSize: 12),
                ),
                const Text(
                  "Rp 32.1M",
                  style: TextStyle(
                    color: Color(0xFFA00000),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
