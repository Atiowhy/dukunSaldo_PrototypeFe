// ============================================================
// DUKUN SALDO - Dummy Data Riwayat Transaksi
// ============================================================

// ============================================================
// ENUM
// ============================================================

enum TransactionType { income, expense }

enum TransactionCategory {
  belanjaBulanan,
  makanMinum,
  transportasi,
  tagihan,
  transferMasuk,
  investasi,
  hiburan,
  kesehatan,
}

// ============================================================
// MODEL
// ============================================================

class TransactionModel {
  final String id;
  final String merchantName;
  final String category;
  final TransactionCategory categoryEnum;
  final TransactionType type;
  final double amount;
  final DateTime dateTime;

  const TransactionModel({
    required this.id,
    required this.merchantName,
    required this.category,
    required this.categoryEnum,
    required this.type,
    required this.amount,
    required this.dateTime,
  });

  bool get isIncome => type == TransactionType.income;
}

// ============================================================
// MONTHLY SUMMARY
// ============================================================

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;

  const MonthlySummary({required this.totalIncome, required this.totalExpense});
}

// ============================================================
// DUMMY DATA
// ============================================================

class TransactionDummyData {
  // ----------------------------------------------------------
  // RINGKASAN BULAN INI (Oktober 2023)
  // ----------------------------------------------------------
  static const MonthlySummary summary = MonthlySummary(
    totalIncome: 12450000,
    totalExpense: 8240500,
  );

  // ----------------------------------------------------------
  // LIST TRANSAKSI
  // Dikelompokkan per hari, urutan terbaru di atas
  // ----------------------------------------------------------
}
