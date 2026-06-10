class TransactionModel {
  final int? id;
  final int userId;
  final String merchantName;
  final String category;
  final double amount;
  final String type; // 'income' atau 'expense'
  final String date;
  final bool isSubscription;

  TransactionModel({
    this.id,
    required this.userId,
    required this.merchantName,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.isSubscription = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'merchantName': merchantName,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date,
      'isSubscription': isSubscription ? 1 : 0,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userId: map['userId'],
      merchantName: map['merchantName'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      date: map['date'],
      isSubscription: map['isSubscription'] == 1,
    );
  }
}
