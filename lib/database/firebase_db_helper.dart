import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukunsaldo_fe/models/log_model.dart';
import 'package:dukunsaldo_fe/models/transactions_model.dart';

class FirebaseDbHelper {
  static final FirebaseDbHelper instance = FirebaseDbHelper._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseDbHelper._init();

  // ===================== TRANSACTIONS =====================

  Future<bool> insertTransaction(TransactionModel transaction) async {
    try {
      // Membuat ID integer unik berbasis waktu jika belum ada (karena model butuh int id)
      int uniqueId = transaction.id ?? DateTime.now().millisecondsSinceEpoch;

      Map<String, dynamic> data = transaction.toMap();
      data['id'] = uniqueId;

      await _firestore
          .collection('transactions')
          .doc(uniqueId.toString())
          .set(data);
      return true;
    } catch (e) {
      log("Error insert transaction: ${e.toString()}");
      return false;
    }
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      log("Error get all transactions: ${e.toString()}");
      return [];
    }
  }

  // Menggunakan tipe data dynamic agar mendukung int maupun String untuk userId
  Future<List<TransactionModel>> getTransactionsByUserId(dynamic userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      log("Error get transactions by user id: ${e.toString()}");
      return [];
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _firestore.collection('transactions').doc(id.toString()).delete();
      return true;
    } catch (e) {
      log("Error delete transaction: ${e.toString()}");
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      if (transaction.id == null) return false;
      await _firestore
          .collection('transactions')
          .doc(transaction.id.toString())
          .update(transaction.toMap());
      return true;
    } catch (e) {
      log("Error update transaction: ${e.toString()}");
      return false;
    }
  }

  // ===================== LOGS =====================

  Future<bool> insertLog(LogModel logData) async {
    try {
      int uniqueId = logData.id ?? DateTime.now().millisecondsSinceEpoch;

      Map<String, dynamic> data = logData.toMap();
      data['id'] = uniqueId;

      await _firestore.collection('logs').doc(uniqueId.toString()).set(data);
      return true;
    } catch (e) {
      log("Error insert log: ${e.toString()}");
      return false;
    }
  }

  Future<List<LogModel>> getLogsByUserId(dynamic userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('logs')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => LogModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      log("Error get logs by user id: ${e.toString()}");
      return [];
    }
  }
}
