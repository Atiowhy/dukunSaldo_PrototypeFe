import 'package:fl_chart/fl_chart.dart';
import '../models/transactions_model.dart';
import '../models/summary_model.dart';

class AdvisorModel {
  final double nextMonthForecast;
  final double level;
  final double trend;
  final double percentageChange;
  final bool isDeficit;
  final double deficitAmount;
  final List<double> last3MonthsActual;
  final List<double> last3MonthsForecast;

  AdvisorModel({
    required this.nextMonthForecast,
    required this.level,
    required this.trend,
    required this.percentageChange,
    required this.isDeficit,
    required this.deficitAmount,
    required this.last3MonthsActual,
    required this.last3MonthsForecast,
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

class FinanceAnalysisService {
  // --- FUNGSI 1: UNTUK HALAMAN HOME ---
  static SummaryModel calculateDashboard(List<TransactionModel> transactions) {
    double tempIncome = 0;
    double tempExpense = 0;
    Map<int, double> monthlyNet = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var trx in transactions) {
      bool isIncome = trx.type == 'income';

      if (isIncome) {
        tempIncome += trx.amount;
      } else {
        tempExpense += trx.amount;
      }

      DateTime date = DateTime.tryParse(trx.date) ?? DateTime.now();
      if (monthlyNet.containsKey(date.month)) {
        if (isIncome) {
          monthlyNet[date.month] = monthlyNet[date.month]! + trx.amount;
        } else {
          monthlyNet[date.month] = monthlyNet[date.month]! - trx.amount;
        }
      }
    }

    List<FlSpot> spots = [];
    List<double> actualCumulative = [];
    double cumulative = 0;

    for (int i = 1; i <= 5; i++) {
      cumulative += (monthlyNet[i] ?? 0);
      double scaledValue = cumulative / 1000000;

      spots.add(FlSpot((i - 1).toDouble(), scaledValue));
      actualCumulative.add(scaledValue);
    }

    List<FlSpot> predictionSpots = [];

    if (actualCumulative.length >= 2) {
      double alpha = 0.5;
      double beta = 0.3;

      double level = actualCumulative[0];
      double trend = actualCumulative[1] - actualCumulative[0];

      for (int i = 1; i < actualCumulative.length; i++) {
        double lastLevel = level;
        level = alpha * actualCumulative[i] + (1 - alpha) * (lastLevel + trend);
        trend = beta * (level - lastLevel) + (1 - beta) * trend;
      }

      double forecastMonth6 = level + (1 * trend);
      double forecastMonth7 = level + (2 * trend);

      FlSpot lastReal = spots.last;
      predictionSpots.add(lastReal);
      predictionSpots.add(FlSpot(lastReal.x + 1, forecastMonth6));
      predictionSpots.add(FlSpot(lastReal.x + 2, forecastMonth7));
    }

    return SummaryModel(
      totalIncome: tempIncome,
      totalExpense: tempExpense,
      currentBalance: tempIncome - tempExpense,
      realChartSpots: spots,
      predictChartSpots: predictionSpots,
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
      );
    }

    List<String> sortedMonths = monthlyExpense.keys.toList()..sort();
    List<double> actualExpenses = sortedMonths
        .map((key) => monthlyExpense[key]!)
        .toList();

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

    return AdvisorModel(
      nextMonthForecast: nextMonthForecast,
      level: level,
      trend: trend,
      percentageChange: percentageChange,
      isDeficit: currentTotalBalance > 0 ? isDeficit : false,
      deficitAmount: deficitAmount,
      last3MonthsActual: last3Actual,
      last3MonthsForecast: last3Forecast,
    );
  }

  
  static RecommendationModel generateRecommendations(
    List<TransactionModel> transactions,
  ) {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;

    double currentFood = 0;
    double lastFood = 0;
    double currentDigital = 0;
    double currentIncome = 0;
    double currentExpense = 0;

    for (var trx in transactions) {
      DateTime date = DateTime.tryParse(trx.date) ?? now;
      if (date.month == currentMonth) {
        if (trx.type == 'income') currentIncome += trx.amount;
        if (trx.type == 'expense') currentExpense += trx.amount;
        if (trx.category == 'Food') currentFood += trx.amount;
        if (trx.category == 'Digital') currentDigital += trx.amount;
      } else if (date.month == lastMonth) {
        if (trx.category == 'Food') lastFood += trx.amount;
      }
    }

    double lifestyleIncrease = 0;
    if (lastFood > 0 && currentFood > lastFood) {
      lifestyleIncrease = ((currentFood - lastFood) / lastFood) * 100;
    }
    double lifestyleSavings = currentFood > 0 ? currentFood * 0.2 : 0;

    int subCount = currentDigital > 0 ? (currentDigital / 75000).ceil() : 0;
    double subscriptionSavings = currentDigital > 0 ? currentDigital * 0.3 : 0;

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
}
