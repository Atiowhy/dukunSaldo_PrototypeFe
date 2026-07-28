import 'dart:convert';
import 'dart:typed_data';

import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
import 'package:dukunsaldo_fe/core/providers/theme_provider.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/features/auth/login.dart';
import 'package:dukunsaldo_fe/features/notification/notification_screen.dart';
import 'package:dukunsaldo_fe/features/profile/profile_screen.dart';
import 'package:dukunsaldo_fe/features/report/report_screen.dart';
import 'package:dukunsaldo_fe/features/transactions/add_transaction_screen.dart';
import 'package:dukunsaldo_fe/models/log_model.dart';
import 'package:dukunsaldo_fe/models/summary_model.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:dukunsaldo_fe/service/finance_analysis_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../database/db_helper.dart';
import '../../database/firebase_db_helper.dart';
import '../history/transaction_history_screen.dart';
import '../prediction(EWS)/prediction_screen.dart';
import '../recomendation/recomendation_screen.dart';

// tambahin fitur hapus akun

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _refreshCounter = 0;
  List<Map<String, dynamic>> _localTransactions = [];

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _currentBalance = 0;
  List<FlSpot> _realChartSpots = [const FlSpot(0, 0)];
  List<FlSpot> _predictChartSpots = [];
  List<String> _chartLabels = [];

  int _uniqueMonthsCount = 0;
  int _notificationCount = 0;
  int _totalLogsCount = 0;
  bool _isBalanceHidden = false;

  Uint8List? _profileImageBytes;
  String _cachedPhotoUrl = "";

  ImageProvider? _getProfileImageProvider() {
    if (Preference.photoUrl.isEmpty) {
      return null;
    }
    if (Preference.photoUrl.startsWith('http')) {
      return NetworkImage(Preference.photoUrl);
    }
    if (_cachedPhotoUrl != Preference.photoUrl) {
      _cachedPhotoUrl = Preference.photoUrl;
      _profileImageBytes = base64Decode(Preference.photoUrl);
    }
    return MemoryImage(_profileImageBytes!);
  }

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
    String prefix = amount < 0 ? "-" : "";
    return prefix +
        amount.abs().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String formatCompact(double amount) {
    bool isNegative = amount < 0;
    double absAmount = amount.abs();
    String prefix = isNegative ? "-" : "";
    if (absAmount >= 1000000000) {
      String val = (absAmount / 1000000000).toStringAsFixed(2);
      if (val.endsWith('.00'))
        val = val.substring(0, val.length - 3);
      else if (val.endsWith('0'))
        val = val.substring(0, val.length - 1);
      return '$prefix${val}M';
    } else if (absAmount >= 1000000) {
      String val = (absAmount / 1000000).toStringAsFixed(2);
      if (val.endsWith('.00'))
        val = val.substring(0, val.length - 3);
      else if (val.endsWith('0'))
        val = val.substring(0, val.length - 1);
      return '$prefix${val}Jt';
    } else if (absAmount >= 1000) {
      String val = (absAmount / 1000).toStringAsFixed(2);
      if (val.endsWith('.00'))
        val = val.substring(0, val.length - 3);
      else if (val.endsWith('0'))
        val = val.substring(0, val.length - 1);
      return '$prefix${val}Rb';
    }
    return '$prefix${absAmount.toStringAsFixed(0)}';
  }

  Future<void> _fetchTransactions() async {
    int activeUserId = Preference.userId;

    // Fetch directly from Firebase
    List<TransactionModel> transactionModels = await FirebaseDbHelper.instance
        .getTransactionsByUserId(activeUserId);

    // Urutkan dari yang terbaru (id DESC)
    transactionModels.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    // Bikin format list map untuk UI compatibility (karena sebelumnya pakai db.query yg nge-return List<Map>)
    List<Map<String, dynamic>> maps = transactionModels
        .map((t) => t.toMap())
        .toList();

    // 👇 LOGIKA BARU: Hitung ada berapa bulan unik di dalam database
    Set<String> uniqueMonths = {};
    for (var trx in transactionModels) {
      DateTime date = DateTime.tryParse(trx.date) ?? DateTime.now();
      // Format kuncinya: Tahun-Bulan (misal: "2026-05")
      uniqueMonths.add("${date.year}-${date.month}");
    }

    SummaryModel calculatedSummary = FinanceAnalysisService.calculateDashboard(
      transactionModels,
    );

    setState(() {
      _localTransactions = maps;
      _refreshCounter++;

      // Update data jumlah bulan untuk progress bar
      _uniqueMonthsCount = uniqueMonths.length;

      _totalIncome = calculatedSummary.totalIncome;
      _totalExpense = calculatedSummary.totalExpense;
      _currentBalance = calculatedSummary.currentBalance;
      _realChartSpots = calculatedSummary.realChartSpots;
      _predictChartSpots = calculatedSummary.predictChartSpots;
      _chartLabels = calculatedSummary.chartLabels;
    });
  }

  void _deleteTransaction(Map<String, dynamic> trx) async {
    int id = trx['id'];
    double amount = (trx['amount'] as num).toDouble();
    String type = trx['type'];
    String category = trx['category'];

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              "Hapus Transaksi?",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            content: Text(
              "Tindakan ini akan menghapus catatan kas ini secara permanen.",
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Batal",
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Hapus",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      );

      await DatabaseHelper.instance.deleteTransaction(id);
      FirebaseDbHelper.instance.deleteTransaction(id); // Fire and forget

      // Simpan log penghapusan transaksi
      final logData = LogModel(
        userId: Preference.userId,
        title: "Hapus Transaksi",
        message:
            "Anda menghapus transaksi ${type == 'income' ? 'pemasukan' : 'pengeluaran'} sebesar Rp $amount untuk kategori $category.",
        date: DateTime.now().toIso8601String(),
        type: type,
      );

      // Save log locally
      await DatabaseHelper.instance.insertLog(logData);
      // Save log to Firebase (fire and forget)
      FirebaseDbHelper.instance.insertLog(logData);

      await _fetchTransactions();
      _fetchNotifications();

      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog loading
    }
  }

  Future<void> _fetchNotifications() async {
    int activeUserId = Preference.userId;
    // Fetch logs from Firebase
    final logs = await FirebaseDbHelper.instance.getLogsByUserId(activeUserId);

    if (mounted) {
      setState(() {
        _totalLogsCount = logs.length;
        int unread = logs.length - Preference.lastReadLogCount;
        _notificationCount = unread > 0 ? unread : 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isBalanceHidden = Preference.isBalanceHidden;
    _fetchTransactions();
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final List<Widget> pages = [
      _buildHomeContent(theme, isDarkMode),
      AdvisorPage(refreshTrigger: _refreshCounter),
      RecommendationPage(refreshTrigger: _refreshCounter),
      ReportScreen(refreshTrigger: _refreshCounter),
    ];

    final String userEmail = Preference.email.isEmpty
        ? "Guest"
        : Preference.email;
    final String userName = Preference.username;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 70, // Memberikan sedikit ruang tambahan
        title: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
          ), // Sejajarkan dengan tepi konten
          child: Text(
            ["Dashboard", "Prediksi", "Rekomendasi", "Report"][_selectedIndex],
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
        actions: [
          // Icon Notification dengan container border halus
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor, width: 1.5),
            ),
            child: IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: _notificationCount > 0
                  ? Badge(
                      label: Text(_notificationCount.toString()),
                      backgroundColor: Colors.redAccent,
                      child: const Icon(Icons.notifications_active),
                    )
                  : const Icon(Icons.notifications_none),
              color: theme.primaryColor,
              onPressed: () async {
                await Preference.setLastReadLogCount(_totalLogsCount);
                setState(() {
                  _notificationCount = 0;
                });

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
                _fetchNotifications();
              },
            ),
          ),
          const SizedBox(width: 12),
          // Foto Profil
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) {
                setState(() {});
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.cardColor,
                backgroundImage: _getProfileImageProvider(),
                child: Preference.photoUrl.isEmpty
                    ? Icon(Icons.person, color: theme.primaryColor)
                    : null,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(
        userEmail,
        userName,
        theme,
        themeProvider,
        isDarkMode,
      ),
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: pages),

      // FAB Modern
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              AppColors.darkPrimaryButtonColor,
              AppColors.lightPrimaryButtonColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPrimaryButtonColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(
            Icons.add,
            color: isDarkMode
                ? AppColors.darkScaffoldBackgroundColor
                : AppColors.lightCardColor,
            size: 32,
          ),
          onPressed: () async {
            final bool? isDataChanged = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTransactionScreen(),
              ),
            );
            if (isDataChanged == true) {
              _fetchTransactions();
              _fetchNotifications();
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? AppColors.darkCardColor
                : AppColors.lightCardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, "Home", Icons.home_outlined, isDarkMode, theme),
              _buildNavItem(
                1,
                "Prediksi",
                Icons.lightbulb_outline,
                isDarkMode,
                theme,
              ),
              _buildNavItem(
                2,
                "Rekomendasi",
                Icons.star_outline,
                isDarkMode,
                theme,
              ),
              _buildNavItem(
                3,
                "Report",
                Icons.analytics_outlined,
                isDarkMode,
                theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData icon,
    bool isDarkMode,
    ThemeData theme,
  ) {
    bool isSelected = _selectedIndex == index;

    Color activeBgColor = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;
    Color activeContentColor = isDarkMode
        ? AppColors.darkScaffoldBackgroundColor
        : Colors.white;
    Color inactiveContentColor =
        theme.textTheme.bodyMedium?.color ?? Colors.grey;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeContentColor : inactiveContentColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeContentColor : inactiveContentColor,
              ),
            ),
          ],
        ),
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
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              image: Preference.photoUrl.isNotEmpty
                  ? DecorationImage(
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.4),
                        BlendMode.darken,
                      ),
                      image: _getProfileImageProvider()!,
                    )
                  : null,
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.5),
                backgroundImage: _getProfileImageProvider(),
                child: Preference.photoUrl.isEmpty
                    ? Icon(Icons.person, size: 36, color: theme.primaryColor)
                    : null,
              ),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              userEmail,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: theme.primaryColor),
            title: Text("Beranda", style: TextStyle(color: theme.primaryColor)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.person, color: theme.primaryColor),
            title: Text(
              "Profil Pengguna",
              style: TextStyle(color: theme.primaryColor),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) {
                // Refresh if username changed
                setState(() {});
              });
            },
          ),

          Padding(
            padding: const EdgeInsets.only(left: 24, top: 24),
            child: Row(
              children: [
                Switch(
                  value: isDarkMode,
                  activeThumbColor: AppColors.darkPrimaryButtonColor,
                  onChanged: (bool value) => themeProvider.toggleTheme(value),
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
    final String userName = Preference.username.isEmpty
        ? "Guest"
        : Preference.username;

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
          children:
              [
                    _buildBalanceCard(theme, isDarkMode),
                    const SizedBox(height: 24),

                    // 👇 WIDGET TRACKER DES ENGINE BARU DIPANGGIL DI SINI
                    _buildDESProgressBar(theme, isDarkMode),
                    const SizedBox(height: 24),

                    _buildPredictionChart(theme, isDarkMode),
                    const SizedBox(height: 24),
                    _buildSummaryCards(theme, isDarkMode),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Riwayat Transaksi",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TransactionHistoryScreen(),
                            ),
                          ),
                          child: Text(
                            "Lihat Semua",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? AppColors.darkPrimaryButtonColor
                                  : AppColors.lightPrimaryButtonColor,
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
                                  Lottie.asset(
                                    'assets/lottie/empty1.json',
                                    height: 120,
                                    repeat: true,
                                    animate: true,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    "Belum ada transaksi",
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Mulai catat pemasukan dan pengeluaran\nAnda dengan menekan tombol + di bawah.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayList.length > 4
                                ? 4
                                : displayList.length,
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
                                          ? (isDarkMode
                                                ? AppColors
                                                      .darkPrimaryButtonColor
                                                : AppColors
                                                      .lightPrimaryButtonColor)
                                          : theme.primaryColor,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            merchantName,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            category,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            (() {
                                              try {
                                                return DateFormat(
                                                  'dd MMM yyyy',
                                                  'id_ID',
                                                ).format(
                                                  DateTime.parse(
                                                    trx['date'] ?? '',
                                                  ),
                                                );
                                              } catch (e) {
                                                return trx['date'] ?? '';
                                              }
                                            })(),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontSize: 11,
                                                  color: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withOpacity(0.6),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "${isIncome ? '+' : '-'} Rp ${formatCompact(amount)}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isIncome
                                            ? (isDarkMode
                                                  ? AppColors
                                                        .darkPrimaryButtonColor
                                                  : AppColors
                                                        .lightPrimaryButtonColor)
                                            : theme.colorScheme.error,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: theme.dividerColor,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          final bool?
                                          isChanged = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddTransactionScreen(
                                                    transaction:
                                                        TransactionModel.fromMap(
                                                          trx,
                                                        ),
                                                  ),
                                            ),
                                          );
                                          if (isChanged == true)
                                            _fetchTransactions();
                                        } else if (value == 'delete') {
                                          _deleteTransaction(trx);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: theme.primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: theme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: theme.colorScheme.error,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Hapus',
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ]
                  .animate(interval: 100.ms)
                  .fade(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
        ),
      ),
    );
  }

  // 👇 FUNGSI BARU: Progress Bar Kesiapan Algoritma
  Widget _buildDESProgressBar(ThemeData theme, bool isDarkMode) {
    const int targetMonths = 2; // Syarat minimal untuk DES
    int current = _uniqueMonthsCount > targetMonths
        ? targetMonths
        : _uniqueMonthsCount;
    double progress = targetMonths == 0 ? 0 : (current / targetMonths);
    bool isUnlocked = current >= targetMonths;
    final Color primaryAccent = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? primaryAccent.withOpacity(0.5)
              : theme.dividerColor,
          width: isUnlocked ? 1.5 : 1.0,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: primaryAccent.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle : Icons.insights,
                    color: isUnlocked ? primaryAccent : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Kesiapan Prediksi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? primaryAccent.withOpacity(0.1)
                      : theme.dividerColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isUnlocked ? "Aktif" : "$current/$targetMonths Bulan",
                  style: TextStyle(
                    color: isUnlocked
                        ? primaryAccent
                        : theme.textTheme.bodyMedium?.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom Animated Progress Bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Latar Belakang Progress Bar (Kosong)
                  Container(
                    height: 8,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Indikator Isi (Beranimasi)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.fastOutSlowIn,
                    height: 8,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: primaryAccent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: primaryAccent.withOpacity(0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            isUnlocked
                ? "Bagus! Algoritma AI prediksi arus kas (DES) sekarang dapat melacak tren keuanganmu."
                : "Catat transaksi dari minimal $targetMonths bulan berbeda agar Sistem dapat mengaktifkan fitur prediksi.",
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- BALANCE CARD DINAMIS ---
  Widget _buildBalanceCard(ThemeData theme, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [AppColors.darkCardColor, AppColors.darkScaffoldBackgroundColor]
              : [AppColors.lightPrimaryButtonColor, const Color(0xFF003B1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (isDarkMode
                        ? AppColors.darkPrimaryButtonColor
                        : AppColors.lightPrimaryButtonColor)
                    .withOpacity(0.15),
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
              Icons.account_balance_wallet,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Total Saldo Saat Ini",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        _isBalanceHidden = !_isBalanceHidden;
                      });
                      await Preference.setIsBalanceHidden(_isBalanceHidden);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isBalanceHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _isBalanceHidden
                  ? const Text(
                      "Rp ***.***",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: _currentBalance,
                      ), //gerak dari 0 sampe saldo user
                      duration: const Duration(
                        milliseconds: 1500,
                      ), // durasinya 1.5 detik
                      curve: Curves
                          .easeOutExpo, // Memulai cepat, melambat di akhir seperti meteran
                      builder: (context, value, child) {
                        return Text(
                          "Rp ${formatRupiah(value.toInt())}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _currentBalance >= 0
                          ? (isDarkMode
                                    ? AppColors.darkPrimaryButtonColor
                                    : AppColors.lightPrimaryButtonColor)
                                .withOpacity(0.2)
                          : theme.colorScheme.error.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentBalance >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: _currentBalance >= 0
                          ? (isDarkMode
                                ? AppColors.darkPrimaryButtonColor
                                : AppColors.lightButtonTextColor)
                          : theme.colorScheme.error,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentBalance >= 0
                        ? "Update Realtime • Sehat"
                        : "Defisit Terdeteksi",
                    style: TextStyle(
                      color: _currentBalance >= 0
                          ? (isDarkMode
                                ? AppColors.darkPrimaryButtonColor
                                : AppColors.lightButtonTextColor)
                          : theme.colorScheme.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CHART DINAMIS ---
  Widget _buildPredictionChart(ThemeData theme, bool isDarkMode) {
    final Color chartPrimaryColor = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;

    double maxReal = _realChartSpots.isEmpty
        ? 0
        : _realChartSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double maxPredict = _predictChartSpots.isEmpty
        ? 0
        : _predictChartSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double maxYValue = maxReal > maxPredict ? maxReal : maxPredict;

    double minReal = _realChartSpots.isEmpty
        ? 0
        : _realChartSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double minPredict = _predictChartSpots.isEmpty
        ? 0
        : _predictChartSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double minYValue = minReal < minPredict ? minReal : minPredict;

    double calculatedMaxY = (maxYValue > 0 ? maxYValue * 1.5 : 0.0).clamp(
      10.0,
      double.infinity,
    );
    double calculatedMinY = minYValue < 0 ? (minYValue * 1.5) : 0.0;

    final realBarData = LineChartBarData(
      spots: _realChartSpots,
      showingIndicators: List.generate(_realChartSpots.length, (i) => i),
      isCurved: true,
      color: chartPrimaryColor,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: chartPrimaryColor.withOpacity(0.15),
      ),
    );

    final predictBarData = LineChartBarData(
      spots: _predictChartSpots,
      showingIndicators: List.generate(_predictChartSpots.length, (i) => i),
      isCurved: true,
      color: isDarkMode ? Colors.white70 : AppColors.lightPrimaryTextColor,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: [8, 4],
    );

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
                      "Melihat tren saldo riil dan proyeksi masa depan berdasarkan kebiasaan Anda.",
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_uniqueMonthsCount >= 2)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: chartPrimaryColor,
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
          if (_uniqueMonthsCount < 2)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              child: Column(
                children: [
                  Lottie.asset(
                    'assets/lottie/empty2.json',
                    height: 100,
                    repeat: true,
                    animate: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Data Belum Cukup",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sistem butuh data transaksi minimal 3 bulan untuk meramal arus kas Anda secara akurat.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: calculatedMinY,
                  maxY: calculatedMaxY,
                  showingTooltipIndicators: [
                    ..._realChartSpots.map(
                      (spot) => ShowingTooltipIndicators([
                        LineBarSpot(realBarData, 0, spot),
                      ]),
                    ),
                    ..._predictChartSpots.map(
                      (spot) => ShowingTooltipIndicators([
                        LineBarSpot(predictBarData, 1, spot),
                      ]),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: false,
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((index) {
                            return TouchedSpotIndicatorData(
                              const FlLine(color: Colors.transparent),
                              FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                          radius: 4,
                                          color: barData.color ?? Colors.blue,
                                          strokeWidth: 2,
                                          strokeColor: Colors.white,
                                        ),
                              ),
                            );
                          }).toList();
                        },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            formatCompact(spot.y * 1000000),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
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
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value != value.toInt()) {
                            return const SizedBox.shrink();
                          }
                          final index = value.toInt();
                          if (index < 0 || index >= _chartLabels.length) {
                            return const SizedBox.shrink();
                          }
                          final style = theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          );
                          bool isLastReal = index == _realChartSpots.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _chartLabels[index],
                              style: isLastReal
                                  ? theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    )
                                  : style,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [realBarData, predictBarData],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Info: Garis putus-putus adalah prediksi masa depan. AI menggunakan sistem peredam (smoothing) otomatis agar ramalan saldo tidak langsung rusak/anjlok drastis hanya karena pengeluaran kaget sesaat di bulan ini.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        height: 1.4,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- SUMMARY CARDS ---
  Widget _buildSummaryCards(ThemeData theme, bool isDarkMode) {
    final Color incomeColor = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;
    final Color expenseColor = theme.colorScheme.error;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: incomeColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: incomeColor.withOpacity(0.05),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: incomeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_downward,
                        color: incomeColor,
                        size: 18,
                      ),
                    ),
                    Icon(
                      Icons.show_chart,
                      color: incomeColor.withOpacity(0.5),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Pemasukan",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBalanceHidden
                      ? "Rp ***.***"
                      : "Rp ${formatCompact(_totalIncome)}",
                  style: TextStyle(
                    color: incomeColor,
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
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: expenseColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: expenseColor.withOpacity(0.05),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: expenseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        color: expenseColor,
                        size: 18,
                      ),
                    ),
                    Icon(
                      Icons.show_chart,
                      color: expenseColor.withOpacity(0.5),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Pengeluaran",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isBalanceHidden
                      ? "Rp ***.***"
                      : "Rp ${formatCompact(_totalExpense)}",
                  style: TextStyle(
                    color: expenseColor,
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
