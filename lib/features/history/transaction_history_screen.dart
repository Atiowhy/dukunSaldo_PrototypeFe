import 'package:dukunsaldo_fe/database/firebase_db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/transactions_model.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedCategory = "Semua";

  List<TransactionModel> _allTransactions = [];
  final List<dynamic> _listItems = [];
  bool _isLoading = true;

  final List<String> _kategoryList = [
    "Semua",
    "Pengeluaran",
    "Pemasukkan",
    "Makanan",
    "Transportasi",
    "Belanja",
    "Tagihan",
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    final data = await FirebaseDbHelper.instance.getTransactionsByUserId(
      Preference.userId,
    );
    // Urutkan berdasarkan tanggal input user (descending)
    data.sort((a, b) {
      final dateA =
          DateTime.tryParse(a.date) ??
          DateTime.fromMillisecondsSinceEpoch(a.id ?? 0);
      final dateB =
          DateTime.tryParse(b.date) ??
          DateTime.fromMillisecondsSinceEpoch(b.id ?? 0);
      return dateB.compareTo(dateA);
    });

    if (!mounted) return;
    setState(() {
      _allTransactions = data;
      _isLoading = false;
      _applyFilters();
    });
  }

  // logic filter kategori riwayat transaksi
  void _applyFilters() {
    setState(() {
      final filtered = _allTransactions.where((trx) {
        if (_selectedCategory == "Semua") return true;

        if (_selectedCategory == "Pemasukkan") {
          return trx.type == "income";
        }
        if (_selectedCategory == "Pengeluaran") {
          return trx.type == "expense";
        }

        return trx.category.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();

      _listItems.clear();
      String currentMonth = "";

      for (var trx in filtered) {
        try {
          final date = DateTime.parse(trx.date);
          final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(date);
          if (monthStr != currentMonth) {
            currentMonth = monthStr;
            _listItems.add(monthStr); // Tambahkan header bulan
          }
        } catch (e) {
          if (currentMonth != "Lainnya") {
            currentMonth = "Lainnya";
            _listItems.add(currentMonth);
          }
        }
        _listItems.add(trx);
      }
    });
  }

  // fungsi format Rupiah
  String formatRupiah(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Riwayat Transaksi",
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xff6BFB9A)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: _kategoryList.map((kategori) {
                        final isSelected = _selectedCategory == kategori;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = kategori;
                                _applyFilters();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDarkMode
                                          ? const Color(0xff6BFB9A)
                                          : const Color(0xFF005E2D))
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : theme.dividerColor,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                kategori,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDarkMode
                                            ? const Color(0xFF0A1219)
                                            : Colors.white)
                                      : theme.primaryColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: _listItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: theme.dividerColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Tidak ada transaksi",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Belum ada transaksi di kategori ini.",
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _listItems.length,
                          itemBuilder: (context, index) {
                            final item = _listItems[index];

                            if (item is String) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 16,
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              );
                            }

                            final trx = item as TransactionModel;
                            final bool isIncome = trx.type == "income";

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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trx.merchantName,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          trx.category,
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
                                                DateTime.parse(trx.date),
                                              );
                                            } catch (e) {
                                              return trx.date;
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
                                    "${isIncome ? '+' : '-'} Rp ${formatRupiah(trx.amount.toInt())}",
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
                ),
              ],
            ),
    );
  }
}
