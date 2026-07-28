# Analisis Sistem Proyek Frontend "Dukun Saldo"

Dokumen ini berisi rangkuman analisis sistem dari proyek aplikasi Dukun Saldo (Flutter), mencakup alur aplikasi secara keseluruhan, mekanisme navigasi antar-halaman (beserta cara mengirim/menerima data), serta bagaimana sistem terhubung ke database Firebase dan cara memasukkan data ke dalamnya.

---

## 1. Alur Sistem Secara Keseluruhan (System Flow)

1. **Inisialisasi (main.dart):**
   - Saat aplikasi pertama kali dijalankan, sistem menginisialisasi **Firebase** dan **SharedPreferences** (`Preference.init()`).
   - Aplikasi dibungkus dengan state management **Provider** (`ChangeNotifierProvider` untuk `ThemeProvider`), yang menangani pengaturan mode terang/gelap (Light/Dark Mode).
2. **Alur Halaman Utama:**
   - **SplashScreen:** Halaman pertama yang muncul (loading screen). Pada titik ini, aplikasi mengecek status sesi pengguna (apakah sudah login atau belum, atau apakah pertama kali menggunakan aplikasi).
   - **Onboarding / Authentication:** Jika pengguna belum login, diarahkan ke alur Onboarding atau Login/Register.
   - **HomeScreen:** Halaman utama yang menjadi pusat interaksi pengguna. Dari sini, pengguna dapat menavigasi ke fitur-fitur lain seperti:
     - Transaksi (Input Pemasukan / Pengeluaran)
     - Riwayat (History)
     - Target Tabungan (Savings)
     - Analisis/Prediksi (Prediction EWS)
     - Profil (Profile)

---

## 2. Navigasi dan Perpindahan Halaman

Proyek ini tidak menggunakan pustaka routing pihak ketiga (seperti GoRouter atau GetX), melainkan mengandalkan sistem navigasi asli (native) dari Flutter, yaitu **Navigator 1.0**.

### A. Cara Berpindah Halaman
- **Pindah Halaman Biasa (Bisa di-back):**
  Menggunakan `Navigator.push()`. Ini menumpuk (push) halaman baru di atas halaman sebelumnya, sehingga AppBar otomatis memiliki tombol back.
  ```dart
  Navigator.push(
    context, 
    MaterialPageRoute(builder: (context) => TargetScreen()),
  );
  ```
- **Pindah Halaman & Hapus Riwayat (Tidak bisa di-back):**
  Menggunakan `Navigator.pushReplacement()` atau `pushAndRemoveUntil()`. Biasanya dipakai dari SplashScreen ke Home, atau setelah Logout.
  ```dart
  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
  ```

### B. Mengambil & Mengirim Data Antar Halaman
- **Melalui Parameter Konstruktor (Kirim Data):**
  Ketika menavigasi ke halaman detail atau halaman edit, data yang ada dipassing langsung ke constructor widget tujuan.
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => EditScreen(dataId: 123, userName: "Budi")),
  );
  ```
- **Melalui Callback/Return Navigasi (Menerima Data Kembali):**
  Ketika halaman sebelumnya (misal HomeScreen) butuh direfresh (refresh data) setelah aksi di halaman berikutnya selesai. Menggunakan keyword `await`.
  ```dart
  final bool? isDataChanged = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => InputTransactionScreen()),
  );
  
  if (isDataChanged == true) {
    // Jalankan ulang fungsi pengambilan data (refresh UI)
    _loadTransactions();
  }
  ```

---

## 3. Koneksi ke Database (Firebase)

Aplikasi ini menggunakan **Firebase** sebagai backend (Backend-as-a-Service), yang meliputi:
- **Firebase Authentication** untuk login dan register.
- **Cloud Firestore** untuk menyimpan basis data NoSQL dokumen.

### Setup Koneksi
Semua operasi di-handle melalui kelas *Service* atau *Helper* bersistem Singleton agar instansiasi terpusat.
- **FirebaseAuthService** (`lib/service/firebase_auth_service.dart`): Mengelola operasi Sign In, Sign Up, Sign Out, dan membaca profil Auth.
- **FirebaseDbHelper** (`lib/database/firebase_db_helper.dart`): Mengelola operasi CRUD (Create, Read, Update, Delete) koleksi `transactions` dan `logs`.

Koneksi dideklarasikan melalui inisialisasi instance:
```dart
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
```

---

## 4. Cara Memasukkan Data ke Database

Karena ini menggunakan Firestore (NoSQL), data disimpan dalam bentuk koleksi (collection) yang berisi dokumen-dokumen (document). Berikut adalah cara sistem aplikasi ini memasukkan data:

### A. Registrasi User Baru (Sign Up)
Terletak pada `FirebaseAuthService`.
1. Sistem mendaftarkan email & password melalui `_auth.createUserWithEmailAndPassword()`.
2. Jika berhasil, ID pengguna (`uid`) didapat.
3. Objek `UserModelFirebase` (berisi nama, email, dsb) diubah menjadi Map (JSON) lewat fungsi `toMap()`.
4. Disimpan ke dalam Firestore pada *Collection* `users` dengan *Document ID* yang sama persis dengan `uid` dari sistem autentikasi.
   ```dart
   await _firestore.collection('users').doc(uid).set(userData);
   ```

### B. Menyimpan Data Transaksi
Terletak pada `FirebaseDbHelper.insertTransaction(TransactionModel transaction)`.
1. Sistem menghasilkan `uniqueId` bertipe integer yang dibuat dari `DateTime.now().millisecondsSinceEpoch`. 
2. Memanggil fungsi `toMap()` dari model untuk di-konversi menjadi Map String dinamis.
3. Data dilempar ke Firestore *Collection* `transactions` dengan spesifik ID tersebut menggunakan `set()`.
   ```dart
   Map<String, dynamic> data = transaction.toMap();
   data['id'] = uniqueId;

   await _firestore
        .collection('transactions')
        .doc(uniqueId.toString())
        .set(data);
   ```

### C. Menyimpan Data Log
Terletak pada `FirebaseDbHelper.insertLog(LogModel logData)`.
Konsepnya sama persis dengan memasukkan Transaksi, namun diarahkan ke *Collection* `logs`.
```dart
await _firestore.collection('logs').doc(uniqueId.toString()).set(data);
```

**Catatan Integrasi Data:**
Setiap kali melakukan *Insert*, *Update*, ataupun *Query* ke Firestore, fungsi-fungsi ini dibungkus menggunakan blok `try { ... } catch (e) { ... }` untuk menangani *error* serta mencetak *log* ke dalam console, sehingga mempermudah proses _debugging_.
