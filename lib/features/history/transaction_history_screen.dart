import 'package:flutter/material.dart';
import '../../../database/db_helper.dart';
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
  bool _isLoading = true;

  final List<String> _kategoryList = [
    "Semua",
    "Pengeluaran",
    "Pemasukkan",
    "Food",
    "Transport",
    "Digital",
    "Shopping",
  ];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() {
      _allTransactions = data;
      _isLoading = false;
    });
  }

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

    final filteredTransactions = _allTransactions.where((trx) {
      if (_selectedCategory == "Semua") return true;

      if (_selectedCategory == "Pemasukkan") {
        return trx.type == "income";
      }
      if (_selectedCategory == "Pengeluaran") {
        return trx.type == "expense";
      }

      return trx.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

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
                  child: filteredTransactions.isEmpty
                      ? Center(
                          child: Text(
                            "Tidak ada transaksi di kategori ini.",
                            style: theme.textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final trx = filteredTransactions[index];

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
