import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserModelFirebase {
  final int? id;
  final String? uid;
  final String email;
  final String username;
  final String password;
  
  UserModelFirebase({
    this.id,
    this.uid,
    required this.email,
    required this.username,
    this.password = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'name': username,
      'email': email,
      // Password tidak disimpan ke database untuk keamanan
    };
  }

  factory UserModelFirebase.fromMap(Map<String, dynamic> map) {
    return UserModelFirebase(
      id: map['id'] != null ? map['id'] as int : null,
      uid: map['uid'] as String?,
      email: map['email'] as String,
      username: map['name'],
      // Password tidak ada di db, jadi kita beri default
      password: '', 
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModelFirebase.fromJson(String source) =>
      UserModelFirebase.fromMap(json.decode(source) as Map<String, dynamic>);
}
