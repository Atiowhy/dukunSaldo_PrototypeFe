class LogModel {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final String date;
  final String type; // 'income', 'expense', 'system'

  LogModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'date': date,
      'type': type,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      message: map['message'],
      date: map['date'],
      type: map['type'],
    );
  }
}
