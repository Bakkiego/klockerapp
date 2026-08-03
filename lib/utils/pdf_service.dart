import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndSharePayslip({
    required Map<String, dynamic> payslip,
    required String employeeName,
    required String currencySymbol,
    String? companyName,
    String? companyAddress, // e.g., "102 Edward Street\nBellville\n7530"
    String? employeeIdNumber,
    String? employeeNumber,
    String? jobTitle,
    String? taxNumber,
    List<Map<String, dynamic>>? itemizedBreakdown,
  }) async {
    final pdf = pw.Document();

    // --- 1. DATA PREPARATION ---
    final String finalCompanyName =
        (companyName == null || companyName.trim().isEmpty)
        ? "KLOCKERAPP"
        : companyName.trim();

    final gross = double.tryParse(payslip['gross_pay'].toString()) ?? 0.0;
    final net = double.tryParse(payslip['net_pay'].toString()) ?? 0.0;
    final defaultDeductions =
        double.tryParse(payslip['deductions'].toString()) ?? 0.0;
    final month = payslip['month_year'] ?? "Unknown Period";

    // Categorize line items into Additions (Income/Allowances) and Deductions
    List<Map<String, dynamic>> additions = [];
    List<Map<String, dynamic>> deductions = [];

    double totalAdditions = gross;
    double totalDeductionsCalc = defaultDeductions;

    if (itemizedBreakdown != null) {
      for (var item in itemizedBreakdown) {
        final String name = item['item_name'] ?? item['name'] ?? 'Adjustment';
        final double amount =
            double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        final bool isDeduction = item['is_deduction'] == true;

        if (isDeduction) {
          deductions.add({'name': name, 'amount': amount});
          totalDeductionsCalc += amount;
        } else {
          additions.add({'name': name, 'amount': amount});
          totalAdditions += amount;
        }
      }
    }

    // Add a default deduction line if no specific items exist but a total was passed
    if (defaultDeductions > 0 && deductions.isEmpty) {
      deductions.add({
        'name': 'Standard Deductions (PAYE/UIF)',
        'amount': defaultDeductions,
      });
    }

    // --- 2. PDF PAGE BUILDER ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Company Info
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        finalCompanyName,
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "PAYSLIP",
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  // Right: Company Address
                  pw.Text(
                    companyAddress ??
                        "Company Address Not Provided\nCity\nZip Code",
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 10),

              // --- EMPLOYEE METADATA GRID ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Column 1
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        _buildMetaRow("Employee Name", employeeName),
                        _buildMetaRow("Period", month),
                        _buildMetaRow("ID Number", employeeIdNumber ?? "-"),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Column 2
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        _buildMetaRow("Employee Number", employeeNumber ?? "-"),
                        _buildMetaRow("Job Title", jobTitle ?? "-"),
                        _buildMetaRow("Income Tax Number", taxNumber ?? "-"),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1.5),
              pw.SizedBox(height: 20),

              // --- FINANCIAL DETAILS GRID ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: INCOME & ALLOWANCES
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Income",
                          totalAdditions,
                          currencySymbol,
                        ),
                        _buildLineItem("Basic Salary", gross, currencySymbol),
                        for (var item in additions)
                          _buildLineItem(
                            item['name'],
                            item['amount'],
                            currencySymbol,
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 40),

                  // RIGHT COLUMN: DEDUCTIONS & CONTRIBUTIONS
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          "Deduction",
                          totalDeductionsCalc,
                          currencySymbol,
                        ),
                        for (var item in deductions)
                          _buildLineItem(
                            item['name'],
                            item['amount'],
                            currencySymbol,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // --- BOTTOM NET PAY SECTION ---
              pw.Divider(thickness: 2),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      "NETT PAY",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(width: 40),
                    pw.Text(
                      "$currencySymbol ${net.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 2),

              pw.SizedBox(height: 30),

              // --- FOOTER WATERMARK ---
              pw.Center(
                child: pw.Text(
                  "Generated by KlockerApp",
                  style: pw.TextStyle(
                    color: PdfColors.grey500,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 3. Trigger Native Share/Save
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Payslip_${employeeName.replaceAll(" ", "_")}_$month.pdf',
    );
  }

  // --- HELPER WIDGETS FOR CLEAN CODE ---

  /// Builds a standard meta-data row (e.g., "Employee Name      John Doe")
  static pw.Widget _buildMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Builds a section header with a bold title and total amount aligned to the right, followed by a divider
  static pw.Widget _buildSectionHeader(
    String title,
    double total,
    String currencySymbol,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              total.toStringAsFixed(2),
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 4),
      ],
    );
  }

  /// Builds a standard financial line item
  static pw.Widget _buildLineItem(
    String description,
    double amount,
    String currencySymbol,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(description, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            amount.toStringAsFixed(2),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
