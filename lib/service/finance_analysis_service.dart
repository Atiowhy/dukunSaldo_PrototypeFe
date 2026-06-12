import 'package:fl_chart/fl_chart.dart';

import '../models/summary_model.dart';
import '../models/transactions_model.dart';

class AdvisorModel {
  final double nextMonthForecast;
  final double level;
  final double trend;
  final double percentageChange;
  final bool isDeficit;
  final double deficitAmount;
  final List<double> last3MonthsActual;
  final List<double> last3MonthsForecast;
  final List<String> last3MonthsLabels;
  final bool hasEnoughData;

  AdvisorModel({
    required this.nextMonthForecast,
    required this.level,
    required this.trend,
    required this.percentageChange,
    required this.isDeficit,
    required this.deficitAmount,
    required this.last3MonthsActual,
    required this.last3MonthsForecast,
    required this.last3MonthsLabels,
    required this.hasEnoughData,
  });
}

class RecommendationModel {
  final double lifestyleIncreasePercent;
  final double lifestyleSavings;
  final int subscriptionCount;
  final double subscriptionSavings;
  final double surplusAmount;
  final double savingsTarget;
  final double totalPotentialSavings;
  final double efficiencyProgress;

  RecommendationModel({
    required this.lifestyleIncreasePercent,
    required this.lifestyleSavings,
    required this.subscriptionCount,
    required this.subscriptionSavings,
    required this.surplusAmount,
    required this.savingsTarget,
    required this.totalPotentialSavings,
    required this.efficiencyProgress,
  });
}

class ReportModel {
  final double currentMonthExpense;
  final double lastMonthExpense;
  final double expenseTrend;
  final int accuracyScore;
  final List<MapEntry<String, double>> topCategories;
  final Map<String, double> categoryPercentages;

  ReportModel({
    required this.currentMonthExpense,
    required this.lastMonthExpense,
    required this.expenseTrend,
    required this.accuracyScore,
    required this.topCategories,
    required this.categoryPercentages,
  });
}

class FinanceAnalysisService {
  // --- FUNGSI 1: UNTUK HALAMAN HOME ---
  static SummaryModel calculateDashboard(List<TransactionModel> transactions) {
    double tempIncome = 0;
    double tempExpense = 0;
    Map<String, double> monthlyNet = {};

    for (var trx in transactions) {
      bool isIncome = trx.type == 'income';

      if (isIncome) {
        tempIncome += trx.amount;
      } else {
        tempExpense += trx.amount;
      }

      DateTime date = DateTime.tryParse(trx.date) ?? DateTime.now();
      String monthKey = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      if (!monthlyNet.containsKey(monthKey)) {
        monthlyNet[monthKey] = 0.0;
      }

      if (isIncome) {
        monthlyNet[monthKey] = monthlyNet[monthKey]! + trx.amount;
      } else {
        monthlyNet[monthKey] = monthlyNet[monthKey]! - trx.amount;
      }
    }

    List<FlSpot> spots = [];
    List<double> actualCumulative = [];
    List<double> actualNet = [];
    List<String> chartLabels = [];
    double cumulative = 0;

    List<String> sortedMonths = monthlyNet.keys.toList()..sort();
    List<String> monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agt",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];

    int currentY = DateTime.now().year;
    int currentM = DateTime.now().month;

    // Construct continuous timeline
    if (sortedMonths.isNotEmpty) {
      String firstMonthStr = sortedMonths.first;
      String lastMonthStr = sortedMonths.last;

      int startYear = int.parse(firstMonthStr.split('-')[0]);
      int startMonth = int.parse(firstMonthStr.split('-')[1]);
      int endYear = int.parse(lastMonthStr.split('-')[0]);
      int endMonth = int.parse(lastMonthStr.split('-')[1]);

      currentY = startYear;
      currentM = startMonth;
      int index = 0;

      while (currentY < endYear ||
          (currentY == endYear && currentM <= endMonth)) {
        String key = "$currentY-${currentM.toString().padLeft(2, '0')}";
        double netValue = monthlyNet[key] ?? 0.0;

        cumulative += netValue;
        double scaledValue = cumulative / 1000000;
        double scaledNet = netValue / 1000000;

        spots.add(FlSpot(index.toDouble(), scaledValue));
        actualCumulative.add(scaledValue);
        actualNet.add(scaledNet);
        chartLabels.add(monthNames[currentM - 1]);

        index++;
        currentM++;
        if (currentM > 12) {
          currentM = 1;
          currentY++;
        }
      }
    } else {
      // Fallback for empty data
      spots.add(const FlSpot(0, 0));
      actualCumulative.add(0);
      chartLabels.add(monthNames[currentM - 1]);
    }

    List<FlSpot> predictionSpots = [];

    // Logika DES
    // 1. Algoritma TIDAK memprediksi total saldo secara mentah, karena hal itu
    //    akan menghasilkan garis lurus (linear) dan gagal mendeteksi "akselerasi"
    //    jika pemasukan sedang turun atau pengeluaran sedang naik drastis.
    // 2. Sebagai gantinya, AI melakukan simulasi DES pada "Kas Bersih Bulanan" (actualNet).
    //    Ini membuat AI mampu mengenali Tren kecepatan defisit/surplus Anda.
    // 3. Setelah AI berhasil menebak Prediksi Kas Bersih bulan depan (forecastNetMonth),
    //    angka tersebut baru diakumulasikan (ditambahkan) ke Total Saldo Saat Ini (lastCum).

    // Syarat utama: AI butuh minimal 2 bulan data historis untuk bisa menganalisis tren
    if (actualCumulative.length >= 2) {
      // Alpha (α): Seberapa besar AI mempercayai data terbaru untuk menghitung nilai rata-rata (Level)
      double alpha = 0.5;

      // Beta (β): Seberapa besar AI mempercayai pergerakan data untuk menghitung kecepatan (Trend)
      double beta = 0.3;

      // Inisialisasi awal saat AI baru mulai belajar:
      // Anggap 'Level' (rata-rata uang sisa) di awal adalah sisa uang di bulan pertama
      double level = actualNet[0];

      // Anggap 'Trend' (kecepatan uang sisa berubah) di awal adalah selisih uang sisa bulan ke-2 dan bulan ke-1
      double trend = actualNet[1] - actualNet[0];

      // Mulai iterasi (pelatihan AI) dengan menelusuri data dari bulan ke-2 sampai bulan terakhir
      for (int i = 1; i < actualNet.length; i++) {
        // Simpan nilai rata-rata (Level) bulan sebelumnya sebelum diperbarui
        double lastLevel = level;

        // UPDATE LEVEL: AI menebak sisa uang (Level) di bulan ini berdasarkan perpaduan antara data asli bulan ini dan tebakan bulan lalu
        level = alpha * actualNet[i] + (1 - alpha) * (lastLevel + trend);

        // UPDATE TREND: AI mengoreksi tebakan akselerasi (Tren) berdasarkan pergeseran Level yang baru saja terjadi
        trend = beta * (level - lastLevel) + (1 - beta) * trend;
      }

      // -- FASE FORECASTING (PREDIKSI MASA DEPAN) --
      // Prediksi sisa uang (kas bersih) 1 bulan ke depan: Level terakhir ditambah 1x kecepatan Tren
      double forecastNetMonth6 = level + (1 * trend);

      // Prediksi sisa uang (kas bersih) 2 bulan ke depan: Level terakhir ditambah 2x kecepatan Tren
      double forecastNetMonth7 = level + (2 * trend);

      // Ambil titik grafik terakhir (Total Saldo riil terakhir yang dimiliki user)
      FlSpot lastReal = spots.last;

      // Ambil angka Y-nya (yaitu Saldo Kumulatif saat ini)
      double lastCum = lastReal.y;

      // Konversi tebakan "Kas Bersih" tadi menjadi tebakan "Total Saldo Akhir"
      // Prediksi Saldo bulan 1 = Saldo saat ini + tebakan sisa uang bulan 1
      double forecastCum6 = lastCum + forecastNetMonth6;

      // Prediksi Saldo bulan 2 = Prediksi Saldo bulan 1 + tebakan sisa uang bulan 2
      double forecastCum7 = forecastCum6 + forecastNetMonth7;

      // Masukkan titik-titik prediksi ini ke dalam data visualisasi grafik (garis putus-putus)
      predictionSpots.add(lastReal); // Titik sambung dari garis riil
      predictionSpots.add(
        FlSpot(lastReal.x + 1, forecastCum6),
      ); // Titik prediksi bulan + 1
      predictionSpots.add(
        FlSpot(lastReal.x + 2, forecastCum7),
      ); // Titik prediksi bulan + 2

      // Tambahkan teks nama bulan untuk 2 bulan prediksi tersebut di sumbu X grafik
      int nextM1 = currentM;
      int nextM2 = currentM + 1;
      if (nextM1 > 12) nextM1 -= 12;
      if (nextM2 > 12) nextM2 -= 12;
      chartLabels.add(monthNames[nextM1 - 1]);
      chartLabels.add(monthNames[nextM2 - 1]);
    }

    return SummaryModel(
      totalIncome: tempIncome,
      totalExpense: tempExpense,
      currentBalance: tempIncome - tempExpense,
      realChartSpots: spots,
      predictChartSpots: predictionSpots,
      chartLabels: chartLabels,
    );
  }

  // --- FUNGSI 2: UNTUK HALAMAN RAMALAN (ADVISOR/EWS) ---
  static AdvisorModel generateAdvisorData(
    List<TransactionModel> transactions,
    double currentTotalBalance,
  ) {
    Map<String, double> monthlyExpense = {};

    for (var trx in transactions) {
      if (trx.type == 'expense') {
        DateTime date = DateTime.tryParse(trx.date) ?? DateTime.now();
        String monthKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}";
        monthlyExpense[monthKey] = (monthlyExpense[monthKey] ?? 0) + trx.amount;
      }
    }

    if (monthlyExpense.isEmpty) {
      return AdvisorModel(
        nextMonthForecast: 0,
        level: 0,
        trend: 0,
        percentageChange: 0,
        isDeficit: false,
        deficitAmount: 0,
        last3MonthsActual: [0, 0, 0],
        last3MonthsForecast: [0, 0, 0],
        last3MonthsLabels: ["-", "-", "-"],
        hasEnoughData: false,
      );
    }

    List<String> sortedMonths = monthlyExpense.keys.toList()..sort();

    // 1. Build a continuous list of expenses filling gaps with 0.0
    List<double> actualExpenses = [];
    if (sortedMonths.isNotEmpty) {
      String firstMonthStr = sortedMonths.first;
      String lastMonthStr = sortedMonths.last;

      int startYear = int.parse(firstMonthStr.split('-')[0]);
      int startMonth = int.parse(firstMonthStr.split('-')[1]);
      int endYear = int.parse(lastMonthStr.split('-')[0]);
      int endMonth = int.parse(lastMonthStr.split('-')[1]);

      int currentY = startYear;
      int currentM = startMonth;

      while (currentY < endYear ||
          (currentY == endYear && currentM <= endMonth)) {
        String key = "$currentY-${currentM.toString().padLeft(2, '0')}";
        actualExpenses.add(monthlyExpense[key] ?? 0.0);

        currentM++;
        if (currentM > 12) {
          currentM = 1;
          currentY++;
        }
      }
    }

    double alpha = 0.5;
    double beta = 0.3;

    double level = actualExpenses[0];
    double trend = actualExpenses.length > 1
        ? actualExpenses[1] - actualExpenses[0]
        : 0;

    List<double> historicalForecasts = [level];

    if (actualExpenses.length >= 2) {
      for (int i = 1; i < actualExpenses.length; i++) {
        double lastLevel = level;
        level = alpha * actualExpenses[i] + (1 - alpha) * (lastLevel + trend);
        trend = beta * (level - lastLevel) + (1 - beta) * trend;
        historicalForecasts.add(level + trend);
      }
    }

    double nextMonthForecast = level + (1 * trend);
    if (nextMonthForecast < 0) nextMonthForecast = 0;

    double lastMonthActual = actualExpenses.last;
    double percentageChange = 0;
    if (lastMonthActual > 0) {
      percentageChange =
          ((nextMonthForecast - lastMonthActual) / lastMonthActual) * 100;
    }

    bool isDeficit = nextMonthForecast > currentTotalBalance;
    double deficitAmount = isDeficit
        ? (nextMonthForecast - currentTotalBalance)
        : 0;

    List<double> last3Actual = actualExpenses.length >= 3
        ? actualExpenses.sublist(actualExpenses.length - 3)
        : [...List.filled(3 - actualExpenses.length, 0.0), ...actualExpenses];

    List<double> last3Forecast = historicalForecasts.length >= 3
        ? historicalForecasts.sublist(historicalForecasts.length - 3)
        : [
            ...List.filled(3 - historicalForecasts.length, 0.0),
            ...historicalForecasts,
          ];

    List<String> monthNamesShort = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agt",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];
    List<String> last3Labels = ["-", "-", "-"];

    if (sortedMonths.isNotEmpty) {
      String lastMonthStr = sortedMonths.last;
      int endMonth = int.parse(lastMonthStr.split('-')[1]);
      last3Labels = [];
      for (int i = 2; i >= 0; i--) {
        int m = endMonth - i;
        while (m <= 0) {
          m += 12;
        }
        last3Labels.add(monthNamesShort[m - 1]);
      }
    }

    return AdvisorModel(
      nextMonthForecast: nextMonthForecast,
      level: level,
      trend: trend,
      percentageChange: percentageChange,
      isDeficit: isDeficit,
      deficitAmount: deficitAmount,
      last3MonthsActual: last3Actual,
      last3MonthsForecast: last3Forecast,
      last3MonthsLabels: last3Labels,
      hasEnoughData: actualExpenses.length >= 2,
    );
  }

  static RecommendationModel generateRecommendations(
    List<TransactionModel> transactions,
  ) {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;
    int lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    int lastMonthYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    double currentFood = 0;
    double lastFood = 0;
    double currentDigital = 0;
    double currentIncome = 0;
    double currentExpense = 0;
    int actualSubCount = 0;
    double actualSubTotal = 0;

    for (var trx in transactions) {
      DateTime date = DateTime.tryParse(trx.date) ?? now;
      if (date.month == currentMonth && date.year == currentYear) {
        if (trx.type == 'income') currentIncome += trx.amount;
        if (trx.type == 'expense') {
          currentExpense += trx.amount;
          if (trx.isSubscription) {
            actualSubCount++;
            actualSubTotal += trx.amount;
          }
        }
        if (trx.category == 'Food') currentFood += trx.amount;
        if (trx.category == 'Digital') currentDigital += trx.amount;
      } else if (date.month == lastMonth && date.year == lastMonthYear) {
        if (trx.category == 'Food') lastFood += trx.amount;
      }
    }

    double lifestyleIncrease = 0;
    if (lastFood > 0 && currentFood > lastFood) {
      lifestyleIncrease = ((currentFood - lastFood) / lastFood) * 100;
    }
    double lifestyleSavings = currentFood > 0 ? currentFood * 0.2 : 0;

    int subCount = actualSubCount;
    double subscriptionSavings = actualSubTotal;

    double surplus = currentIncome - currentExpense;
    double savingsTarget = surplus > 0 ? surplus * 0.3 : 0;

    double totalHemat = lifestyleSavings + subscriptionSavings + savingsTarget;
    double progress = (totalHemat / 1500000).clamp(0.0, 1.0);

    return RecommendationModel(
      lifestyleIncreasePercent: lifestyleIncrease,
      lifestyleSavings: lifestyleSavings,
      subscriptionCount: subCount,
      subscriptionSavings: subscriptionSavings,
      surplusAmount: surplus,
      savingsTarget: savingsTarget,
      totalPotentialSavings: totalHemat,
      efficiencyProgress: progress,
    );
  }

  // Tambahkan fungsi ini DI DALAM class FinanceAnalysisService
  static ReportModel generateReportData(List<TransactionModel> transactions) {
    DateTime now = DateTime.now();
    double tempCurrentExpense = 0;
    double tempLastMonthExpense = 0;
    Map<String, double> tempCategoryTotals = {};

    for (var trx in transactions) {
      if (trx.type == 'expense') {
        DateTime date = DateTime.tryParse(trx.date) ?? now;

        // 1. Hitung pengeluaran bulan INI
        if (date.year == now.year && date.month == now.month) {
          tempCurrentExpense += trx.amount;
          tempCategoryTotals[trx.category] =
              (tempCategoryTotals[trx.category] ?? 0) + trx.amount;
        }
        // 2. Hitung pengeluaran bulan LALU
        else if ((now.month == 1 &&
                date.year == now.year - 1 &&
                date.month == 12) ||
            (date.year == now.year && date.month == now.month - 1)) {
          tempLastMonthExpense += trx.amount;
        }
      }
    }

    // 3. Hitung Persentase Tren
    // 3. Hitung Persentase Tren & Logika Akurasi AI
    double trend = 0;
    int calculatedAccuracy = 0; // Default 0% jika database benar-benar kosong

    if (tempLastMonthExpense > 0) {
      // Jika ada data bulan lalu, algoritma bisa membandingkan
      trend =
          ((tempCurrentExpense - tempLastMonthExpense) / tempLastMonthExpense) *
          100;
      calculatedAccuracy = tempCurrentExpense > 0
          ? 100
          : 45; // Akurasi penuh jika data berkesinambungan
    } else if (tempCurrentExpense > 0) {
      // Jika baru ada data bulan ini saja, AI sedang dalam masa "belajar"
      calculatedAccuracy = 45;
    }

    // 4. Urutkan Kategori Terboros (Dari terbesar ke terkecil)
    List<MapEntry<String, double>> sortedCategories =
        tempCategoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // 5. Hitung Persentase untuk Donut Chart
    Map<String, double> percentages = {};
    if (tempCurrentExpense > 0) {
      for (var entry in sortedCategories) {
        percentages[entry.key] = (entry.value / tempCurrentExpense) * 100;
      }
    }

    return ReportModel(
      currentMonthExpense: tempCurrentExpense,
      lastMonthExpense: tempLastMonthExpense,
      expenseTrend: trend,
      accuracyScore: calculatedAccuracy,
      topCategories: sortedCategories,
      categoryPercentages: percentages,
    );
  }
}
