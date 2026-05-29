import '../models/transactions_model.dart';

final List<TransactionModel> transactions = [
  // ── Hari Ini, 24 Oktober 2023 ──────────────────────────
  TransactionModel(
    id: 'TRX-001',
    merchantName: 'Supermarket Hero',
    category: 'Belanja Bulanan',
    categoryEnum: TransactionCategory.belanjaBulanan,
    type: TransactionType.expense,
    amount: 450000,
    dateTime: DateTime(2023, 10, 24, 14, 20),
  ),
  TransactionModel(
    id: 'TRX-002',
    merchantName: 'Gaji Pokok',
    category: 'Transfer Perusahaan',
    categoryEnum: TransactionCategory.transferMasuk,
    type: TransactionType.income,
    amount: 10000000,
    dateTime: DateTime(2023, 10, 24, 9, 0),
  ),

  // ── Kemarin, 23 Oktober 2023 ───────────────────────────
  TransactionModel(
    id: 'TRX-003',
    merchantName: 'Starbucks Coffee',
    category: 'Makan & Minum',
    categoryEnum: TransactionCategory.makanMinum,
    type: TransactionType.expense,
    amount: 65000,
    dateTime: DateTime(2023, 10, 23, 16, 45),
  ),
  TransactionModel(
    id: 'TRX-004',
    merchantName: 'Shell Indonesia',
    category: 'Transportasi',
    categoryEnum: TransactionCategory.transportasi,
    type: TransactionType.expense,
    amount: 350000,
    dateTime: DateTime(2023, 10, 23, 10, 15),
  ),

  // ── 22 Oktober 2023 ────────────────────────────────────
  TransactionModel(
    id: 'TRX-005',
    merchantName: 'PLN Pascabayar',
    category: 'Tagihan Listrik',
    categoryEnum: TransactionCategory.tagihan,
    type: TransactionType.expense,
    amount: 1250000,
    dateTime: DateTime(2023, 10, 22, 20, 30),
  ),
  TransactionModel(
    id: 'TRX-006',
    merchantName: 'GrabFood',
    category: 'Makan & Minum',
    categoryEnum: TransactionCategory.makanMinum,
    type: TransactionType.expense,
    amount: 78000,
    dateTime: DateTime(2023, 10, 22, 12, 10),
  ),

  // ── 20 Oktober 2023 ────────────────────────────────────
  TransactionModel(
    id: 'TRX-007',
    merchantName: 'Netflix',
    category: 'Hiburan',
    categoryEnum: TransactionCategory.hiburan,
    type: TransactionType.expense,
    amount: 54000,
    dateTime: DateTime(2023, 10, 20, 8, 0),
  ),
  TransactionModel(
    id: 'TRX-008',
    merchantName: 'Reksa Dana Syariah',
    category: 'Investasi',
    categoryEnum: TransactionCategory.investasi,
    type: TransactionType.expense,
    amount: 500000,
    dateTime: DateTime(2023, 10, 20, 9, 0),
  ),

  // ── 18 Oktober 2023 ────────────────────────────────────
  TransactionModel(
    id: 'TRX-009',
    merchantName: 'Bonus Kinerja',
    category: 'Transfer Masuk',
    categoryEnum: TransactionCategory.transferMasuk,
    type: TransactionType.income,
    amount: 2000000,
    dateTime: DateTime(2023, 10, 18, 11, 30),
  ),

  // ── 15 Oktober 2023 ────────────────────────────────────
  TransactionModel(
    id: 'TRX-010',
    merchantName: 'Apotek K-24',
    category: 'Kesehatan',
    categoryEnum: TransactionCategory.kesehatan,
    type: TransactionType.expense,
    amount: 120000,
    dateTime: DateTime(2023, 10, 15, 14, 0),
  ),
  TransactionModel(
    id: 'TRX-011',
    merchantName: 'Indomaret',
    category: 'Belanja Bulanan',
    categoryEnum: TransactionCategory.belanjaBulanan,
    type: TransactionType.expense,
    amount: 95000,
    dateTime: DateTime(2023, 10, 15, 18, 45),
  ),

  // ── 10 Oktober 2023 ────────────────────────────────────
  TransactionModel(
    id: 'TRX-012',
    merchantName: 'Tokopedia',
    category: 'Belanja Bulanan',
    categoryEnum: TransactionCategory.belanjaBulanan,
    type: TransactionType.expense,
    amount: 320000,
    dateTime: DateTime(2023, 10, 10, 13, 20),
  ),
  TransactionModel(
    id: 'TRX-013',
    merchantName: 'Grab',
    category: 'Transportasi',
    categoryEnum: TransactionCategory.transportasi,
    type: TransactionType.expense,
    amount: 45000,
    dateTime: DateTime(2023, 10, 10, 8, 30),
  ),

  // ── 5 Oktober 2023 ─────────────────────────────────────
  TransactionModel(
    id: 'TRX-014',
    merchantName: 'Dividen Saham',
    category: 'Transfer Masuk',
    categoryEnum: TransactionCategory.transferMasuk,
    type: TransactionType.income,
    amount: 450000,
    dateTime: DateTime(2023, 10, 5, 10, 0),
  ),
  TransactionModel(
    id: 'TRX-015',
    merchantName: 'Spotify',
    category: 'Hiburan',
    categoryEnum: TransactionCategory.hiburan,
    type: TransactionType.expense,
    amount: 29000,
    dateTime: DateTime(2023, 10, 5, 7, 0),
  ),
];

// ----------------------------------------------------------
// HELPER: Kelompokkan transaksi berdasarkan tanggal
// Digunakan untuk menampilkan header tanggal di ListView
// ----------------------------------------------------------
Map<DateTime, List<TransactionModel>> groupByDate() {
  final Map<DateTime, List<TransactionModel>> grouped = {};

  for (final trx in transactions) {
    final date = DateTime(
      trx.dateTime.year,
      trx.dateTime.month,
      trx.dateTime.day,
    );
    grouped.putIfAbsent(date, () => []).add(trx);
  }

  // Urutkan key dari terbaru ke terlama
  final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

  return {for (final key in sortedKeys) key: grouped[key]!};
}

// ----------------------------------------------------------
// HELPER: Filter berdasarkan tipe (Semua / Pemasukan / Pengeluaran)
// ----------------------------------------------------------
List<TransactionModel> filterByType(TransactionType? type) {
  if (type == null) return transactions;
  return transactions.where((t) => t.type == type).toList();
}
