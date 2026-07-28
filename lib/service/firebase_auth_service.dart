import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dukunsaldo_fe/models/user_model_firebase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign In
  Future<UserModelFirebase?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Ambil data user dari Firestore
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return UserModelFirebase.fromMap(data);
        }
      }
    } on FirebaseAuthException catch (e) {
      log("FirebaseAuthException: ${e.message}");
    } catch (e) {
      log("Error sign in: ${e.toString()}");
    }
    return null;
  }

  // Sign Up
  Future<UserModelFirebase?> signUp(UserModelFirebase userModel) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: userModel.password,
      );

      if (credential.user != null) {
        String uid = credential.user!.uid;
        
        // Membuat integer ID unik agar tidak null saat masuk database
        // dan bisa berelasi dengan tabel transaksi yang memakai userId bertipe int
        int generatedId = DateTime.now().millisecondsSinceEpoch;
        
        // Simpan data tambahan ke Firestore
        Map<String, dynamic> userData = userModel.toMap();
        userData['id'] = generatedId;
        userData['uid'] = uid; // Pastikan uid tersimpan
        
        await _firestore.collection('users').doc(uid).set(userData);
        
        // Kembalikan model dengan id dan uid yang baru
        return UserModelFirebase(
          id: generatedId,
          uid: uid,
          username: userModel.username,
          email: userModel.email,
          password: userModel.password,
        );
      }
    } on FirebaseAuthException catch (e) {
      log("FirebaseAuthException: ${e.message}");
    } catch (e) {
      log("Error sign up: ${e.toString()}");
    }
    return null;
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log("Error sign out: ${e.toString()}");
    }
  }

  // Cek jika email sudah terdaftar
  Future<bool> checkEmailExist(String email) async {
    try {
      // Karena fetchSignInMethodsForEmail tidak tersedia di versi baru
      // Kita bisa mengeceknya dari collection users di Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log("Error check email: ${e.toString()}");
      return false;
    }
  }

  // Ambil user saat ini yang sedang login
  Future<UserModelFirebase?> getCurrentUser() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return UserModelFirebase.fromMap(data);
        }
      }
    } catch (e) {
      log("Error get current user: ${e.toString()}");
    }
    return null;
  }

  // Update username and photoUrl in Firebase
  Future<bool> updateUserProfile({String? newName, String? newPhotoUrl}) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Update Auth Profile
        if (newName != null) {
          await currentUser.updateDisplayName(newName);
        }
        if (newPhotoUrl != null && newPhotoUrl.startsWith('http')) {
          await currentUser.updatePhotoURL(newPhotoUrl);
        }

        // Update Firestore Document
        Map<String, dynamic> updates = {};
        if (newName != null) updates['name'] = newName; // Use 'name' to match UserModelFirebase
        if (newPhotoUrl != null) updates['photoUrl'] = newPhotoUrl;
        
        if (updates.isNotEmpty) {
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .update(updates);
        }
        return true;
      }
      return false;
    } catch (e) {
      log("Error update profile: ${e.toString()}");
      throw Exception("Gagal mengupdate ke server database: ${e.toString()}");
    }
  }

  // Hapus Akun
  Future<bool> deleteAccount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String uid = currentUser.uid;
        // Hapus data pengguna di Firestore terlebih dahulu
        await _firestore.collection('users').doc(uid).delete();
        // Hapus akun dari Firebase Auth
        await currentUser.delete();
        return true;
      }
      return false;
    } catch (e) {
      log("Error delete account: ${e.toString()}");
      return false;
    }
  }
}
