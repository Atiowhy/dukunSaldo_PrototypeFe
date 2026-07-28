# Materi Presentasi: Dukun Saldo - Prediksi Keuangan & Early Warning System (EWS)

Berikut adalah kerangka presentasi yang bisa Anda gunakan untuk memaparkan proyek Dukun Saldo. Materi ini difokuskan pada bagian inti aplikasi: algoritma, logika prediksi keuangan, dan *Early Warning System* (EWS).

---

## 1. Pendahuluan
* **Tujuan Aplikasi:** Dukun Saldo bukan sekadar pencatat keuangan biasa, melainkan asisten pintar yang dapat membaca tren pengeluaran dan memberikan peringatan dini sebelum pengguna mengalami masalah keuangan.
* **Fitur Unggulan:** 
  * Visualisasi data interaktif.
  * Prediksi Pengeluaran berbasis algoritma *Machine Learning* sederhana.
  * **EWS (Early Warning System)** untuk mendeteksi potensi defisit.
  * Rekomendasi efisiensi gaya hidup secara proaktif.

---

## 2. Pemilihan Algoritma: *Double Exponential Smoothing*
Untuk melakukan *forecasting* (prediksi) pengeluaran di masa depan, Dukun Saldo menggunakan algoritma **Double Exponential Smoothing** (Metode Holt).

**Mengapa memilih algoritma ini?**
* Data keuangan pribadi (seperti pengeluaran bulanan) memiliki dua komponen utama:
  1. **Level:** Rata-rata dasar pengeluaran.
  2. **Trend:** Kecenderungan laju pengeluaran (apakah makin boros atau makin hemat).
* Algoritma ini sangat cocok untuk memproses data berderet waktu (*time-series*) yang memiliki *trend* namun tidak harus memiliki pola musiman (seperti pengeluaran mendadak).

**Parameter Algoritma yang Digunakan:**
* **Alpha ($\alpha$) = 0.5** : Ini adalah bobot pemulusan untuk **Level**. Nilai 0.5 adalah *sweet spot* yang menyeimbangkan antara kestabilan historis dan responsivitas terhadap pengeluaran terbaru.
* **Beta ($\beta$) = 0.3** : Ini adalah bobot pemulusan untuk **Trend**. Nilai yang relatif kecil (0.3) memastikan bahwa jika pengguna tiba-tiba melakukan transaksi besar dalam satu bulan, *trend* tidak akan langsung melonjak secara drastis (mencegah fluktuasi palsu).

---

## 3. Logika Prediksi Pengeluaran
Bagaimana tepatnya Dukun Saldo meramal pengeluaran bulan depan? Berikut langkah-langkah logika pemrogramannya:

1. **Agregasi Data Bulanan:** Semua transaksi bertipe `expense` (pengeluaran) ditarik dari *database* lokal (SQLite) dan dijumlahkan per bulan.
2. **Inisialisasi:** 
   * `Level` awal = Pengeluaran bulan ke-1.
   * `Trend` awal = Pengeluaran bulan ke-2 dikurangi pengeluaran bulan ke-1.
3. **Perhitungan Iteratif:** Untuk setiap bulan berikutnya, algoritma akan memperbarui nilai Level dan Trend:
   * **Update Level:** Mencampur data aktual bulan ini dengan prediksi Level sebelumnya.
   * **Update Trend:** Mengevaluasi selisih Level baru dan lama, lalu memperbarui laju kecepatan pengeluaran.
4. **Hasil Prediksi (`nextMonthForecast`):** 
   Prediksi bulan depan didapatkan dari rumus sederhana: `Level Terakhir + (1 * Trend Terakhir)`.
   *Nilai ini kemudian dihitung persentase kenaikan/penurunannya terhadap bulan aktual terakhir untuk ditampilkan di UI.*

---

## 4. *Early Warning System* (EWS) - Sistem Peringatan Dini Defisit
Ini adalah fitur *highlight* dari Dukun Saldo yang menyelamatkan pengguna dari kebangkrutan bulanan.

**Logika EWS:**
1. **Pengecekan Saldo Real-time:** Aplikasi menghitung `currentTotalBalance` (Total Pemasukan dikurangi Total Pengeluaran sepanjang waktu).
2. **Komparasi Algoritmik:** Sistem mengambil hasil `nextMonthForecast` (Prediksi Pengeluaran Bulan Depan) dan membandingkannya dengan `currentTotalBalance`.
3. **Trigger Defisit:**
   * **JIKA** `Prediksi Pengeluaran > Total Saldo Saat Ini`:
   * Maka status `isDeficit` menjadi **TRUE**.
4. **Aksi Sistem:** 
   * Aplikasi langsung menghitung `deficitAmount` (Berapa banyak uang yang kurang).
   * Memunculkan *Warning Banner* berwarna merah pada halaman *Prediction/Advisor*.
   * Mengingatkan pengguna: *"Total pengeluaran Anda diprediksi melampaui sisa saldo sebesar Rp X. Segera lakukan penyesuaian anggaran."*

---

## 5. Dukun Saldo Proaktif (Rekomendasi & Insight)
Selain prediksi angka, aplikasi menerjemahkan nilai **Trend** menjadi saran yang bisa dipahami orang awam:
* Jika **Trend Positif ($>0$)**: Aplikasi memperingatkan bahwa pengeluaran cenderung naik konstan setiap bulan, dan menyarankan pembatasan belanja tersier (kebutuhan non-esensial).
* Jika **Trend Negatif ($<0$)**: Aplikasi memuji pengguna karena berhasil menekan angka pengeluaran (berhemat).
* Sistem juga mendeteksi "Kenaikan Gaya Hidup" (*Lifestyle Inflation*) dengan membandingkan pengeluaran kategori makanan (*Food*) serta total biaya *Subscription* (Langganan Digital) antara bulan ini dan bulan lalu.

---

## Tips Presentasi
* **Tunjukkan Layar (Demo):** Saat membahas algoritma, tunjukkan grafik *Bar Chart* (Aktual vs Prediksi) di halaman Analisis Prediksi. Ini membuktikan bahwa algoritma benar-benar memetakan data dengan akurat.
* **Tunjukkan EWS:** Buatlah sebuah transaksi fiktif dengan pengeluaran yang besar sehingga saldo tersisa sangat sedikit, lalu buka halaman Prediksi untuk memicu *Warning Defisit* menyala secara *real-time*. Ini akan sangat mengesankan audiens/dosen penguji!
