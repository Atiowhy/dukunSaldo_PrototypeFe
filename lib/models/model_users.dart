import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserModelSql {
  final int? id;
  final String email;
  final String username;
  final String password;
  UserModelSql({
    this.id,
    required this.email,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      "name": username,
      'email': email,
      'password': password,
    };
  }

  factory UserModelSql.fromMap(Map<String, dynamic> map) {
    return UserModelSql(
      id: map['id'] != null ? map['id'] as int : null,
      email: map['email'] as String,
      username: map['name'],
      password: map['password'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModelSql.fromJson(String source) =>
      UserModelSql.fromMap(json.decode(source) as Map<String, dynamic>);
}
