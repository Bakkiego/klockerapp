import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  // Generates and immediately opens a Share/Save dialog for the PDF
  static Future<void> generateAndSharePayslip({
    required Map<String, dynamic> payslip,
    required String employeeName,
    String? companyName, // 🚀 Made optional so we can cleanly fallback
    required String currencySymbol,
    List<Map<String, dynamic>>?
    itemizedBreakdown, // 🚀 NEW: Dynamic line items!
  }) async {
    // 1. Create a new PDF document
    final pdf = pw.Document();

    // 2. Safe Company Name Fallback
    final String finalCompanyName =
        (companyName == null ||
            companyName.trim().isEmpty ||
            companyName == "Management Record")
        ? "KLOCKERAPP"
        : companyName.trim();

    // 3. Safely parse the core numbers
    final gross = double.tryParse(payslip['gross_pay'].toString()) ?? 0.0;
    final net = double.tryParse(payslip['net_pay'].toString()) ?? 0.0;
    final totalDeductions =
        double.tryParse(payslip['deductions'].toString()) ?? 0.0;
    final month = payslip['month_year'] ?? "Unknown Month";

    // 4. 🚀 DYNAMIC TABLE GENERATOR
    List<List<String>> tableData = [];

    // Always start with Gross / Base Pay
    tableData.add([
      'Gross Earnings / Base',
      '$currencySymbol${gross.toStringAsFixed(2)}',
    ]);

    // If we have detailed line items (from payslip_items and salary_configs)
    if (itemizedBreakdown != null && itemizedBreakdown.isNotEmpty) {
      for (var item in itemizedBreakdown) {
        final String name = item['item_name'] ?? item['name'] ?? 'Adjustment';
        final double amount =
            double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        final bool isDeduction = item['is_deduction'] == true;

        final String prefix = isDeduction ? '-' : '+';
        tableData.add([
          name,
          '$prefix$currencySymbol${amount.toStringAsFixed(2)}',
        ]);
      }
    } else {
      // Fallback if no specific line items were provided but deductions exist
      if (totalDeductions > 0) {
        tableData.add([
          'Total Deductions',
          '-$currencySymbol${totalDeductions.toStringAsFixed(2)}',
        ]);
      }
    }

    // 5. Draw the Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    finalCompanyName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "PAYSLIP",
                    style: pw.TextStyle(fontSize: 24, color: PdfColors.grey),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // --- EMPLOYEE INFO ---
              pw.Text(
                "Employee: $employeeName",
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                "Pay Period: $month",
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 40),

              // --- FINANCIAL TABLE ---
              pw.Table.fromTextArray(
                context: context,
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                headerHeight: 40,
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                },
                headers: ['Description', 'Amount'],
                data: tableData, // 🚀 Uses the dynamic list we built above!
              ),

              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // --- NET PAY TOTAL ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "NET PAY",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "$currencySymbol${net.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              // --- FOOTER ---
              pw.Center(
                child: pw.Text(
                  "Generated securely by KlockerApp",
                  style: const pw.TextStyle(
                    color: PdfColors.grey,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 6. Trigger Native Share
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Payslip_${employeeName.replaceAll(" ", "_")}_$month.pdf',
    );
  }
}
