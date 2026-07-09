import 'package:dukunsaldo_fe/core/constants/app_colors.dart';
import 'package:dukunsaldo_fe/database/db_helper.dart';
import 'package:dukunsaldo_fe/database/firebase_db_helper.dart';
import 'package:dukunsaldo_fe/database/preference.dart';
import 'package:dukunsaldo_fe/models/log_model.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// tanda untuk pembeda antara pengeluaran dan pemasukkan (di pengeluaran di kasih warna merah)
// photo profile dikasih default ketika user belum punya photo profile nya
// tulisan kategori di sesuaikan
// tambahkan tulisan nominal kalau namanya kepanjangan

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.transaction});
  final TransactionModel? transaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = "income";
  String _selectedCategory = "Gaji";
  DateTime _selectedDate = DateTime.now();
  bool _isSubscription = false;
  final bool _isLoading = false;

  final List<Map<String, dynamic>> _expenseCategories = [
    {"name": "Makanan", "icon": Icons.restaurant},
    {"name": "Transportasi", "icon": Icons.directions_car},
    {"name": "Belanja", "icon": Icons.shopping_bag},
    {"name": "Tagihan", "icon": Icons.receipt_long},
    {"name": "Pendidikan", "icon": Icons.school},
    {"name": "Hiburan", "icon": Icons.movie},
    {"name": "Kesehatan", "icon": Icons.medical_services},
    {"name": "Lain-lain", "icon": Icons.list},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {"name": "Gaji", "icon": Icons.payments},
    {"name": "Bonus", "icon": Icons.card_giftcard},
    {"name": "Investasi", "icon": Icons.trending_up},
    {"name": "Penjualan", "icon": Icons.store},
    {"name": "Lain-lain", "icon": Icons.list},
  ];

  List<Map<String, dynamic>> get _categories =>
      _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

  String _formatNumber(String s) {
    String value = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) return '';
    String formatted = '';
    int count = 0;
    for (int i = value.length - 1; i >= 0; i--) {
      formatted = value[i] + formatted;
      count++;
      if (count % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }
    return formatted;
  }

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text = _formatNumber(
        widget.transaction!.amount.toInt().toString(),
      );
      _notesController.text = widget.transaction!.merchantName;
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _selectedDate =
          DateTime.tryParse(widget.transaction!.date) ?? DateTime.now();
      _isSubscription = widget.transaction!.isSubscription;
    }
  }

  Future<void> _pickDate() async {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryAccent = isDarkMode
        ? AppColors.darkPrimaryButtonColor
        : AppColors.lightPrimaryButtonColor;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: isDarkMode
                ? ColorScheme.dark(
                    primary: primaryAccent,
                    onPrimary: AppColors.darkButtonTextColor,
                    surface: theme.cardColor,
                  )
                : ColorScheme.light(
                    primary: primaryAccent,
                    onPrimary: Colors.white,
                    surface: theme.cardColor,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() async {
    final txtAmount = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double? amount = double.tryParse(txtAmount);
    final notes = _notesController.text.trim();

    if (txtAmount.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan nominal transaksi yang valid!")),
      );
      return;
    }

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

    int generatedId =
        widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch;

    final transaksiBaru = TransactionModel(
      id: generatedId,
      userId: Preference.userId,
      merchantName: notes.isEmpty ? "Transaksi $_selectedCategory" : notes,
      category: _selectedCategory,
      amount: amount,
      type: _selectedType,
      date: _selectedDate.toIso8601String(),
      isSubscription: _isSubscription,
    );

    bool success = true;

    if (widget.transaction == null) {
      // Save locally
      await DatabaseHelper.instance.insertTransaction(transaksiBaru);
      // Save to Firebase (fire and forget)
      FirebaseDbHelper.instance.insertTransaction(transaksiBaru);
    } else {
      // Update locally
      await DatabaseHelper.instance.updateTransaction(transaksiBaru);
      // Update to Firebase (fire and forget)
      FirebaseDbHelper.instance.updateTransaction(transaksiBaru);
    }

    if (!mounted) return;
    Navigator.pop(context); // Tutup dialog loading

    if (success) {
      final logData = LogModel(
        userId: Preference.userId,
        title: widget.transaction == null
            ? "Transaksi Baru"
            : "Update Transaksi",
        message:
            "Anda mencatat ${_selectedType == 'income' ? 'pemasukan' : 'pengeluaran'} sebesar Rp $amount untuk kategori $_selectedCategory.",
        date: DateTime.now().toIso8601String(),
        type: _selectedType,
      );

      // Save log locally
      await DatabaseHelper.instance.insertLog(logData);
      // Save log to Firebase (fire and forget)
      FirebaseDbHelper.instance.insertLog(logData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.transaction == null
                ? "Transaksi ditambahkan!"
                : "Transaksi diperbarui!",
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal memproses data!"),
          backgroundColor: Theme.of(context).colorScheme.error,
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

    // Warna aksen dinamis yang senada dengan Home Screen (Merah jika pengeluaran)
    final primaryAccent = _selectedType == "expense"
        ? Colors.redAccent
        : (isDarkMode ? AppColors.darkPrimaryButtonColor : AppColors.lightPrimaryButtonColor);
    final onPrimaryAccent = _selectedType == "expense"
        ? Colors.white
        : (isDarkMode ? AppColors.darkButtonTextColor : AppColors.lightButtonTextColor);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.primaryColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.transaction == null ? "Tambah Transaksi" : "Edit Transaksi",
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true, // Dipindah ke tengah agar lebih elegan
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SEGMENTED CONTROL (TIPE TRANSAKSI) ---
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor, width: 1),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = "income";
                          _selectedCategory = _incomeCategories.first["name"];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == "income"
                              ? primaryAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedType == "income"
                              ? [
                                  BoxShadow(
                                    color: primaryAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          "Pemasukan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedType == "income"
                                ? onPrimaryAccent
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = "expense";
                          _selectedCategory = _expenseCategories.first["name"];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == "expense"
                              ? primaryAccent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedType == "expense"
                              ? [
                                  BoxShadow(
                                    color: primaryAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          "Pengeluaran",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedType == "expense"
                                ? onPrimaryAccent
                                : theme.textTheme.bodyMedium?.color,
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

            // --- INPUT NOMINAL ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nominal Transaksi",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Rp ",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryAccent,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyFormat(),
                          ],
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            letterSpacing: -1,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: "0",
                            hintStyle: TextStyle(color: theme.dividerColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- PILIH KATEGORI ---
            Text(
              "Kategori",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Menggunakan Horizontal Scroll agar tidak overflow di layar kecil
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat['name']),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryAccent.withOpacity(0.15)
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? primaryAccent
                                    : theme.dividerColor,
                                width: isSelected ? 2 : 1.5,
                              ),
                            ),
                            child: Icon(
                              cat['icon'],
                              color: isSelected
                                  ? primaryAccent
                                  : theme.textTheme.bodyMedium?.color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? theme.primaryColor
                                  : theme.textTheme.bodyMedium?.color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // --- BIAYA LANGGANAN TETAP ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.autorenew, color: primaryAccent, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Biaya Langganan Tetap",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Aktifkan untuk analisis DES Engine",
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSubscription,
                    activeThumbColor: primaryAccent,
                    onChanged: (val) => setState(() => _isSubscription = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- PILIH TANGGAL ---
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tanggal Transaksi",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy',
                            'id_ID',
                          ).format(_selectedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- CATATAN ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, color: theme.textTheme.bodyMedium?.color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Catatan (Opsional)",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 11,
                          ),
                        ),
                        TextField(
                          controller: _notesController,
                          maxLines: null,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.primaryColor,
                          ),
                          decoration: InputDecoration(
                            hintText: "Tambahkan rincian belanja...",
                            hintStyle: TextStyle(
                              color: theme.dividerColor,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.only(top: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- SMART PREDICTION BANNER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryAccent.withOpacity(0.1), theme.cardColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: primaryAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "SMART PREDICTION",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "\"DES Engine akan menyesuaikan ramalan pengeluaran Anda jika ini ditandai sebagai langganan.\"",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN (GRADIENT) ---
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: _selectedType == "expense"
                      ? [Colors.red.shade700!, Colors.redAccent]
                      : [
                          AppColors.darkPrimaryButtonColor,
                          AppColors.lightPrimaryButtonColor,
                        ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_selectedType == "expense"
                            ? Colors.redAccent
                            : AppColors.darkPrimaryButtonColor)
                        .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent, // Matikan shadow bawaan
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        widget.transaction == null
                            ? "Simpan Transaksi"
                            : "Perbarui Transaksi",
                        style: const TextStyle(
                          color: Colors
                              .white, // Karena gradient selalu gelap/hijau, teks harus putih
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class CurrencyFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }
    String value = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    int count = 0;
    for (int i = value.length - 1; i >= 0; i--) {
      formatted = value[i] + formatted;
      count++;
      if (count % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
