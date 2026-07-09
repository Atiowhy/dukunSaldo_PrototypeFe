# Pseudocode & Penjelasan Kode `finance_analysis_service.dart`

Berikut adalah salinan kode dari `finance_analysis_service.dart` yang telah ditambahkan **pseudocode (penjelasan bahasa manusia)** di atas setiap baris/blok logika utamanya agar Anda mudah mempelajarinya baris demi baris.

```dart
import 'package:fl_chart/fl_chart.dart';
import '../models/summary_model.dart';
import '../models/transactions_model.dart';

// (Bagian Model Data dilewati karena hanya berupa struktur data biasa)

class FinanceAnalysisService {
  
  // =========================================================================
  // FUNGSI 1: MENGHITUNG DASHBOARD (GRAFIK & TOTAL SALDO DI HOME)
  // =========================================================================
  static SummaryModel calculateDashboard(List<TransactionModel> transactions) {
    // 1. Siapkan wadah (variabel) penampung sementara
    double tempIncome = 0;   // Untuk total semua pemasukan
    double tempExpense = 0;  // Untuk total semua pengeluaran
    
    // Kamus (Map) untuk menyimpan saldo bersih per bulan. Contoh format: {"2023-10": 1500000}
    Map<String, double> monthlyNet = {};

    // 2. Baca satu per satu data transaksi yang ada
    for (var trx in transactions) {
      // Cek apakah transaksi ini adalah tipe 'income' (pemasukan)
      bool isIncome = trx.type == 'income';

      // Jika ya, tambahkan nominal uangnya ke tempIncome
      if (isIncome) {
        tempIncome += trx.amount;
      } 
      // Jika tidak (berarti pengeluaran), tambahkan ke tempExpense
      else {
        tempExpense += trx.amount;
      }

      // Ubah tanggal berupa teks ("2023-10-15") menjadi format waktu (DateTime)
      DateTime date = DateTime.tryParse(trx.date) ?? DateTime.now();
      
      // Buat kata kunci dari tanggal tersebut, bentuknya "Tahun-Bulan" (contoh: "2023-10")
      String monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      // Jika kata kunci bulan itu belum tercatat di Map, buat baru dengan saldo awal 0
      if (!monthlyNet.containsKey(monthKey)) {
        monthlyNet[monthKey] = 0.0;
      }

      // Masukkan uangnya ke catatan bulan tersebut
      if (isIncome) {
        monthlyNet[monthKey] = monthlyNet[monthKey]! + trx.amount; // Jika pemasukan, ditambah
      } else {
        monthlyNet[monthKey] = monthlyNet[monthKey]! - trx.amount; // Jika pengeluaran, dikurang
      }
    }

    // 3. Menyiapkan kerangka untuk menggambar Grafik (Chart)
    List<FlSpot> spots = []; // Titik koordinat untuk grafik garis riil
    List<double> actualCumulative = []; // Saldo total kumulatif riil
    List<double> actualNet = []; // Saldo bersih per bulan (Pemasukan - Pengeluaran)
    List<String> chartLabels = []; // Label teks sumbu X (misal: "Jan", "Feb")
    double cumulative = 0; // Wadah untuk menghitung tumpukan saldo dari bulan ke bulan

    // Urutkan catatan bulan dari yang paling lama ke yang paling baru
    List<String> sortedMonths = monthlyNet.keys.toList()..sort();
    
    // Kamus nama-nama bulan untuk label
    List<String> monthNames = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agt", "Sep", "Okt", "Nov", "Des"];

    int currentY = DateTime.now().year;
    int currentM = DateTime.now().month;

    // 4. Membangun Sumbu X (Garis waktu yang berkesinambungan tanpa ada bulan yang terputus)
    if (sortedMonths.isNotEmpty) {
      // Ambil bulan pertama (paling lama) dan bulan terakhir (paling baru)
      String firstMonthStr = sortedMonths.first;
      String lastMonthStr = sortedMonths.last;

      // Pisahkan tahun dan bulan awal
      int startYear = int.parse(firstMonthStr.split('-')[0]);
      int startMonth = int.parse(firstMonthStr.split('-')[1]);
      
      // Pisahkan tahun dan bulan akhir
      int endYear = int.parse(lastMonthStr.split('-')[0]);
      int endMonth = int.parse(lastMonthStr.split('-')[1]);

      currentY = startYear;
      currentM = startMonth;
      int index = 0; // Posisi titik di grafik (dimulai dari 0)

      // Lakukan perulangan (loop) menelusuri setiap bulan dari awal hingga akhir
      while (currentY < endYear || (currentY == endYear && currentM <= endMonth)) {
        // Buat kata kunci bulan yang sedang dicek ("Tahun-Bulan")
        String key = "$currentY-${currentM.toString().padLeft(2, '0')}";
        
        // Ambil saldo bersih bulan tersebut. Jika tidak ada transaksi sama sekali, anggap 0.
        double netValue = monthlyNet[key] ?? 0.0;

        // Tambahkan saldo bersih bulan tersebut ke tumpukan saldo (cumulative)
        cumulative += netValue;
        
        // Karena angka uang jutaan terlalu besar untuk digambar di grafik, dibagi 1 Juta
        double scaledValue = cumulative / 1000000;
        double scaledNet = netValue / 1000000;

        // Simpan data ke koordinat grafik
        spots.add(FlSpot(index.toDouble(), scaledValue)); // Titik (X: posisi bulan, Y: total saldo)
        actualCumulative.add(scaledValue); 
        actualNet.add(scaledNet);
        chartLabels.add(monthNames[currentM - 1]); // Simpan nama bulannya

        // Maju ke bulan berikutnya
        index++;
        currentM++;
        
        // Jika sudah melewati bulan Desember (12), kembali ke Januari (1) dan naikkan tahunnya
        if (currentM > 12) {
          currentM = 1;
          currentY++;
        }
      }
    } else {
      // Jika riwayat transaksi benar-benar kosong, beri grafik 0 saja
      spots.add(const FlSpot(0, 0));
      actualCumulative.add(0);
      chartLabels.add(monthNames[currentM - 1]);
    }

    // 5. ALGORITMA PREDIKSI (DOUBLE EXPONENTIAL SMOOTHING)
    List<FlSpot> predictionSpots = []; // Titik koordinat untuk grafik prediksi (putus-putus)

    // Syarat prediksi: AI butuh data minimal 2 bulan (bulan lalu dan bulan sekarang)
    if (actualCumulative.length >= 2) {
      double alpha = 0.5; // Pembobotan untuk Level (Sisa Uang Rata-rata)
      double beta = 0.3;  // Pembobotan untuk Trend (Kecepatan Perubahan)

      // Anggap Level awal adalah sisa uang di bulan pertama
      double level = actualNet[0];
      // Anggap Trend awal adalah selisih antara bulan ke-2 dan bulan pertama
      double trend = actualNet[1] - actualNet[0];

      // Pelatihan AI: Menelusuri seluruh data bulan yang ada
      for (int i = 1; i < actualNet.length; i++) {
        double lastLevel = level;
        
        // AI Menebak Level (sisa uang) berdasar data bulan ini + tebakan bulan lalu
        level = alpha * actualNet[i] + (1 - alpha) * (lastLevel + trend);
        
        // AI Mengoreksi Trend berdasar perbedaan level yang baru saja terjadi
        trend = beta * (level - lastLevel) + (1 - beta) * trend;
      }

      // MENEBAK MASA DEPAN (FORECASTING)
      // Tebakan kas bersih 1 bulan ke depan
      double forecastNetMonth6 = level + (1 * trend);
      // Tebakan kas bersih 2 bulan ke depan
      double forecastNetMonth7 = level + (2 * trend);

      // Ambil saldo pengguna yang asli di titik paling akhir (saat ini)
      FlSpot lastReal = spots.last;
      double lastCum = lastReal.y;

      // Akumulasikan tebakan: Total Saldo 1 bln depan = Saldo Sekarang + Tebakan sisa uang bln dpn
      double forecastCum6 = lastCum + forecastNetMonth6;
      // Total Saldo 2 bln depan = Total Saldo 1 bln depan + Tebakan sisa uang 2 bln dpn
      double forecastCum7 = forecastCum6 + forecastNetMonth7;

      // Simpan titik prediksi ke dalam list grafik (Mulai dari titik asli terakhir supaya nyambung)
      predictionSpots.add(lastReal); 
      predictionSpots.add(FlSpot(lastReal.x + 1, forecastCum6));
      predictionSpots.add(FlSpot(lastReal.x + 2, forecastCum7));

      // Tambahkan nama bulan untuk 2 bulan prediksi di masa depan
      int nextM1 = currentM;
      int nextM2 = currentM + 1;
      if (nextM1 > 12) nextM1 -= 12;
      if (nextM2 > 12) nextM2 -= 12;
      chartLabels.add(monthNames[nextM1 - 1]);
      chartLabels.add(monthNames[nextM2 - 1]);
    }

    // 6. Kembalikan semua data matang ke UI
    return SummaryModel(
      totalIncome: tempIncome,
      totalExpense: tempExpense,
      currentBalance: tempIncome - tempExpense,
      realChartSpots: spots,
      predictChartSpots: predictionSpots,
      chartLabels: chartLabels,
    );
  }

  // =========================================================================
  // FUNGSI 2: HALAMAN PREDIKSI EARLY WARNING SYSTEM (EWS)
  // =========================================================================
  static AdvisorModel generateAdvisorData(List<TransactionModel> transactions, double currentTotalBalance) {
    Map<String, double> monthlyExpense = {};

    // 1. Mirip seperti di atas, tapi KITA HANYA MENCARI TRANSAKSI PENGELUARAN (Expense)
    for (var trx in transactions) {
      if (trx.type == 'expense') {
        DateTime date = DateTime.tryParse(trx.date) ?? DateTime.now();
        String monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";
        // Kumpulkan total pengeluaran per bulannya
        monthlyExpense[monthKey] = (monthlyExpense[monthKey] ?? 0) + trx.amount;
      }
    }

    // Jika belum pernah ada pengeluaran, kembalikan nilai 0 semua
    if (monthlyExpense.isEmpty) {
      return AdvisorModel( ... isi nol semua ... );
    }

    List<String> sortedMonths = monthlyExpense.keys.toList()..sort();
    List<double> actualExpenses = [];
    
    // 2. Susun grafik bulan-bulan tanpa putus (sama seperti di calculateDashboard)
    if (sortedMonths.isNotEmpty) {
      // (Algoritma menyusun bulan dilewati agar pseudocode ini fokus ke intinya, persis seperti di atas)
      // ...
    }

    // 3. ALGORITMA PREDIKSI (DES) UNTUK PENGELUARAN
    double alpha = 0.5;
    double beta = 0.3;

    double level = actualExpenses[0];
    double trend = actualExpenses.length > 1 ? actualExpenses[1] - actualExpenses[0] : 0;
    
    // Simpan data jejak tebakan AI sebelumnya untuk dievaluasi
    List<double> historicalForecasts = [level];

    if (actualExpenses.length >= 2) {
      for (int i = 1; i < actualExpenses.length; i++) {
        double lastLevel = level;
        level = alpha * actualExpenses[i] + (1 - alpha) * (lastLevel + trend);
        trend = beta * (level - lastLevel) + (1 - beta) * trend;
        historicalForecasts.add(level + trend);
      }
    }

    // AI menebak total uang pengeluaran bulan depan
    double nextMonthForecast = level + (1 * trend);
    if (nextMonthForecast < 0) nextMonthForecast = 0; // Pengeluaran tak boleh minus

    // Hitung persentase tebakan bulan depan dibandingkan aslinya bulan ini
    double lastMonthActual = actualExpenses.last;
    double percentageChange = 0;
    if (lastMonthActual > 0) {
      percentageChange = ((nextMonthForecast - lastMonthActual) / lastMonthActual) * 100;
    }

    // 4. LOGIKA EARLY WARNING SYSTEM (EWS) - INTI FITUR WARNING
    // Cek: Apakah tebakan pengeluaran bulan depan LEBIH BESAR dari Sisa Saldo di dompet sekarang?
    bool isDeficit = nextMonthForecast > currentTotalBalance;

    // Jika tekor (isDeficit), kurangi tebakan bulan depan dengan saldo di dompet untuk tahu berapa uang minusnya
    double deficitAmount = isDeficit ? (nextMonthForecast - currentTotalBalance) : 0;

    // Siapkan data 3 bulan terakhir untuk ditampilkan di grafik balok
    // ... (logic memotong list array untuk mengambil 3 list terakhir)

    // Kembalikan ke UI
    return AdvisorModel(...);
  }

  // =========================================================================
  // FUNGSI 3: MEMBERIKAN REKOMENDASI PENGHEMATAN
  // =========================================================================
  static RecommendationModel generateRecommendations(List<TransactionModel> transactions) {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;
    
    // Tentukan bulan lalu (jika sekarang Januari/1, maka bulan lalunya Desember/12 tahun kemaren)
    int lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    int lastMonthYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    double currentFood = 0; // Uang makan bulan ini
    double lastFood = 0;    // Uang makan bulan lalu
    double currentIncome = 0; 
    double currentExpense = 0;
    int actualSubCount = 0; // Jumlah transaksi langganan
    double actualSubTotal = 0; // Total uang transaksi langganan

    // 1. Baca seluruh transaksi
    for (var trx in transactions) {
      DateTime date = DateTime.tryParse(trx.date) ?? now;
      
      // Jika ini transaksi BULAN INI
      if (date.month == currentMonth && date.year == currentYear) {
        if (trx.type == 'income') currentIncome += trx.amount;
        if (trx.type == 'expense') {
          currentExpense += trx.amount;
          
          // Jika ditandai sebagai langganan bulanan
          if (trx.isSubscription) {
            actualSubCount++;
            actualSubTotal += trx.amount;
          }
        }
        // Kumpulkan total pengeluaran makanan bulan ini
        if (trx.category == 'Food' || trx.category == 'Makanan') currentFood += trx.amount;
      } 
      // Jika ini transaksi BULAN LALU
      else if (date.month == lastMonth && date.year == lastMonthYear) {
        // Kumpulkan total pengeluaran makanan bulan lalu
        if (trx.category == 'Food' || trx.category == 'Makanan') lastFood += trx.amount;
      }
    }

    // 2. LOGIKA REKOMENDASI AI
    
    // Hitung Kenaikan Gaya Hidup: (Uang makan sekarang dikurang uang makan dulu) dibagi uang makan dulu x 100%
    double lifestyleIncrease = 0;
    if (lastFood > 0 && currentFood > lastFood) {
      lifestyleIncrease = ((currentFood - lastFood) / lastFood) * 100;
    }
    
    // Sarankan untuk menabung 20% dari anggaran makanan saat ini
    double lifestyleSavings = currentFood > 0 ? currentFood * 0.2 : 0;

    // Hitung sisa uang (surplus) bulan ini
    double surplus = currentIncome - currentExpense;
    
    // Sarankan target menabung 30% dari sisa uang bulan ini
    double savingsTarget = surplus > 0 ? surplus * 0.3 : 0;

    // Total Potensi Uang Hemat jika user menuruti saran di atas
    double totalHemat = lifestyleSavings + actualSubTotal + savingsTarget;
    
    // Menghitung kemajuan (progress bar) dengan batas maksimal rekomendasi hemat Rp 1.500.000
    double progress = (totalHemat / 1500000).clamp(0.0, 1.0);

    return RecommendationModel(...);
  }
}
```
