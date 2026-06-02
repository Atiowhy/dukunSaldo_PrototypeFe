import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dukunsaldo_fe/database/db_helper.dart';
// import 'package:dukunsaldo_fe/models/transactions_model.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = "expense";
  String _selectedCategory = "Food";
  DateTime _selectedDate = DateTime.now();
  bool _isSubscription = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {"name": "Food", "icon": Icons.restaurant},
    {"name": "Transport", "icon": Icons.directions_car},
    {"name": "Digital", "icon": Icons.devices},
    {"name": "Shopping", "icon": Icons.shopping_bag},
    {"name": "Gaji", "icon": Icons.money},
  ];

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() async {
    final txtAmount = _amountController.text.trim();
    final double? amount = double.tryParse(txtAmount);
    final notes = _notesController.text.trim();

    if (txtAmount.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Masukkan nominal transaksi yang valid dan lebih dari 0!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final transaksiBaru = TransactionModel(
      merchantName: notes.isEmpty ? "Transaksi $_selectedCategory" : notes,
      category: _selectedCategory,
      amount: amount,
      type: _selectedType,
      date: _selectedDate.toIso8601String(),
    );

    bool success = await DatabaseHelper.instance.insertTransaction(
      transaksiBaru,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Transaksi berhasil disimpan!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal menyimpan data ke database lokal!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tambah Transaksi",
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: theme.primaryColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: theme.primaryColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = "expense"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == "expense"
                              ? const Color(0xFF0F1E29)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Pengeluaran",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedType == "expense"
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = "income"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == "income"
                              ? const Color(0xFF0F1E29)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Pemasukan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedType == "income"
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nominal Transaksi",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Rp ",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff6BFB9A),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Kategori",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Lihat Semua",
                    style: TextStyle(
                      color: Color(0xff6BFB9A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name']),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff6BFB9A).withOpacity(0.15)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xff6BFB9A)
                                : theme.dividerColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          cat['icon'],
                          color: isSelected
                              ? const Color(0xff6BFB9A)
                              : theme.primaryColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xff6BFB9A).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff6BFB9A).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xff6BFB9A),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Biaya Langganan Tetap",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Aktifkan untuk analisis DES Engine Pro",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSubscription,
                    activeColor: const Color(0xff6BFB9A),
                    onChanged: (val) => setState(() => _isSubscription = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.grey),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tanggal",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MM/dd/yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Catatan (Opsional)",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        TextField(
                          controller: _notesController,
                          maxLines: null,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "Tambahkan rincian belanja...",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.only(top: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [const Color(0xFF14222E), theme.cardColor]
                      : [Colors.grey[100]!, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.auto_awesome,
                        color: Color(0xff6BFB9A),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "SMART PREDICTION",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "\"DES Engine memprediksi ini adalah tagihan rutin Anda setiap bulan.\"",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1E29),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan Transaksi",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
