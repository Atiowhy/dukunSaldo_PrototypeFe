import 'package:fl_chart/fl_chart.dart';

class SummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double currentBalance;
  final List<FlSpot> realChartSpots;
  final List<FlSpot> predictChartSpots;

  SummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.currentBalance,
    required this.realChartSpots,
    required this.predictChartSpots,
  });
}
