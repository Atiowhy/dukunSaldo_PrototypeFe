class TransactionModel {
  final int? id;
  final String merchantName;
  final String category;
  final double amount;
  final String type; // 'income' atau 'expense'
  final String date;

  TransactionModel({
    this.id,
    required this.merchantName,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantName': merchantName,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      merchantName: map['merchantName'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      date: map['date'],
    );
  }
}
