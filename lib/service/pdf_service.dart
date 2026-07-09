import 'package:dukunsaldo_fe/service/finance_analysis_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndExportReportPdf(ReportModel data) async {
    final pdf = pw.Document();

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final String reportMonth = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  "Laporan Keuangan Bulanan - DukunSaldo",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "Bulan Laporan: $reportMonth",
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),

              // Total Pengeluaran Card
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Total Pengeluaran",
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      formatter.format(data.currentMonthExpense),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      data.lastMonthExpense == 0
                          ? "Belum ada perbandingan data bulan lalu"
                          : "${data.expenseTrend.abs().toStringAsFixed(1)}% ${data.expenseTrend <= 0 ? 'lebih rendah' : 'lebih tinggi'} dari bulan lalu",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: data.expenseTrend <= 0
                            ? PdfColors.green700
                            : PdfColors.red700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Akurasi Prediksi DES
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey900,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Akurasi Prediksi DES",
                      style: pw.TextStyle(
                        color: PdfColors.grey300,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      "${data.accuracyScore}%",
                      style: pw.TextStyle(
                        color: PdfColors.greenAccent,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Kategori Terboros
              pw.Text(
                "Rincian Pengeluaran Berdasarkan Kategori",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              data.topCategories.isEmpty
                  ? pw.Text(
                      "Belum ada transaksi pengeluaran di bulan ini.",
                      style: pw.TextStyle(color: PdfColors.grey600),
                    )
                  : pw.Table.fromTextArray(
                      headers: ['No', 'Kategori', 'Total (Rp)', 'Persentase'],
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.teal,
                      ),
                      cellAlignment: pw.Alignment.centerLeft,
                      data: List.generate(data.topCategories.length, (index) {
                        final cat = data.topCategories[index];
                        final percent = data.categoryPercentages[cat.key] ?? 0;
                        return [
                          (index + 1).toString(),
                          cat.key,
                          formatter.format(cat.value),
                          "${percent.toStringAsFixed(1)}%",
                        ];
                      }),
                    ),

              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                "Digenerate otomatis oleh sistem DukunSaldo pada ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}",
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Laporan_DukunSaldo_${DateFormat('MMM_yyyy').format(DateTime.now())}.pdf',
    );
  }
}
