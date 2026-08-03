import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:klockerapp/providers/user_provider.dart';
import 'package:klockerapp/supabase/repo/supabase_service.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;

class ReportsScreen extends StatefulWidget {
  static const String id = 'reports_screen';
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _reportData = [];

  String _selectedReportType = 'Payroll';
  final List<String> _reportTypes = ['Payroll', 'Attendance', 'Leave Balances'];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final tenantId = context.read<UserProvider>().tenantId;
      if (tenantId == null) return;

      final data = await SupabaseService().getManagerReport(
        tenantId: tenantId,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _reportData = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading report: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (BuildContext context, Widget? child) {
        final theme = Theme.of(context);

        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF00A36C), // Your Klocker Green
              onPrimary: Colors.white, // Text color on top of the green
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReport();
    }
  }

  void _exportToCsv() {
    if (_reportData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export!')));
      return;
    }

    // 1. Get exactly the columns currently visible on the screen
    List<String> headers = _getColumns()
        .map((col) => (col.label as Text).data!)
        .toList();
    List<List<dynamic>> csvData = [headers];

    // 2. Get the exact row data
    for (var row in _reportData) {
      List<dynamic> rowData = [row['employee_name'] ?? 'Unknown'];
      final hours = ((row['total_standard_minutes'] as num) / 60)
          .toStringAsFixed(1);
      final netPay = (row['total_net_pay'] as num).toStringAsFixed(2);

      if (_selectedReportType == 'Payroll') {
        rowData.addAll([row['shifts_worked'], hours, netPay]);
      } else if (_selectedReportType == 'Attendance') {
        rowData.addAll([
          hours,
          row['total_late'],
          row['total_early'],
          row['total_absent'],
        ]);
      } else if (_selectedReportType == 'Leave Balances') {
        final entitled = (row['leave_entitled'] as num).toDouble();
        final used = (row['leave_used'] as num).toDouble();
        rowData.addAll([entitled, used, entitled - used]);
      }
      csvData.add(rowData);
    }

    // 3. Convert to CSV string
    String csv = const ListToCsvConverter().convert(csvData);

    // 4. 🚀 THE WEB DOWNLOAD MAGIC
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "Klocker_${_selectedReportType}_Report.csv")
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedReportType CSV Downloaded!'),
        backgroundColor: const Color(0xFF00A36C),
      ),
    );
  }

  // --- SUMMARY CARDS ---
  Widget _buildSummaryCards(String currencySymbol) {
    if (_reportData.isEmpty) return const SizedBox.shrink();

    double totalPay = 0;
    double totalHours = 0;
    int totalLate = 0;
    int totalAbsent = 0;
    double totalLeaveUsed = 0;

    for (var row in _reportData) {
      totalPay += (row['total_net_pay'] as num).toDouble();
      totalHours += (row['total_standard_minutes'] as num) / 60;
      totalLate += (row['total_late'] as num).toInt();
      totalAbsent += (row['total_absent'] as num).toInt();
      totalLeaveUsed += (row['leave_used'] as num).toDouble();
    }

    if (_selectedReportType == 'Payroll') {
      return _buildCardRow([
        _summaryCard(
          "Total Payroll",
          "$currencySymbol${totalPay.toStringAsFixed(2)}",
          Icons.payments_outlined,
          Colors.green,
        ),
        _summaryCard(
          "Total Hours",
          totalHours.toStringAsFixed(0),
          Icons.timer,
          Colors.blue,
        ),
        _summaryCard(
          "Active Staff",
          _reportData.length.toString(),
          Icons.people,
          Colors.orange,
        ),
      ]);
    } else if (_selectedReportType == 'Attendance') {
      return _buildCardRow([
        _summaryCard(
          "Total Hours",
          totalHours.toStringAsFixed(0),
          Icons.timer,
          Colors.blue,
        ),
        _summaryCard(
          "Total Lates",
          totalLate.toString(),
          Icons.warning_amber_rounded,
          Colors.redAccent,
        ),
        _summaryCard(
          "Absences",
          totalAbsent.toString(),
          Icons.person_off,
          Colors.red,
        ),
      ]);
    } else {
      return _buildCardRow([
        _summaryCard(
          "Staff Count",
          _reportData.length.toString(),
          Icons.people,
          Colors.orange,
        ),
        _summaryCard(
          "Leave Days Used",
          totalLeaveUsed.toStringAsFixed(1),
          Icons.beach_access,
          Colors.teal,
        ),
      ]);
    }
  }

  Widget _buildCardRow(List<Widget> cards) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return isMobile
              ? Column(
                  children: cards
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: c,
                        ),
                      )
                      .toList(),
                )
              : Row(
                  children: cards
                      .map(
                        (c) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: c,
                          ),
                        ),
                      )
                      .toList(),
                );
        },
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DYNAMIC DATA TABLE ---
  List<DataColumn> _getColumns() {
    const boldStyle = TextStyle(fontWeight: FontWeight.bold);

    List<DataColumn> baseColumns = [
      const DataColumn(label: Text('Employee', style: boldStyle)),
    ];

    if (_selectedReportType == 'Payroll') {
      baseColumns.addAll([
        const DataColumn(label: Text('Shifts', style: boldStyle)),
        const DataColumn(label: Text('Hours', style: boldStyle)),
        const DataColumn(label: Text('Net Pay', style: boldStyle)),
      ]);
    } else if (_selectedReportType == 'Attendance') {
      baseColumns.addAll([
        const DataColumn(label: Text('Hours', style: boldStyle)),
        const DataColumn(label: Text('Late', style: boldStyle)),
        const DataColumn(label: Text('Early Leave', style: boldStyle)),
        const DataColumn(label: Text('Absent', style: boldStyle)),
      ]);
    } else if (_selectedReportType == 'Leave Balances') {
      baseColumns.addAll([
        const DataColumn(label: Text('Leave Entitled', style: boldStyle)),
        const DataColumn(label: Text('Leave Used', style: boldStyle)),
        const DataColumn(label: Text('Remaining', style: boldStyle)),
      ]);
    }
    return baseColumns;
  }

  List<DataRow> _getRows(String currencySymbol) {
    return _reportData.map((row) {
      final hours = ((row['total_standard_minutes'] as num) / 60)
          .toStringAsFixed(1);
      final netPay = (row['total_net_pay'] as num).toStringAsFixed(2);

      List<DataCell> cells = [
        DataCell(
          Text(
            row['employee_name'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ];

      if (_selectedReportType == 'Payroll') {
        cells.addAll([
          DataCell(Text(row['shifts_worked'].toString())),
          DataCell(Text(hours)),
          DataCell(
            Text(
              '$currencySymbol$netPay',
              style: const TextStyle(
                color: Color(0xFF00A36C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ]);
      } else if (_selectedReportType == 'Attendance') {
        final lateCount = row['total_late'] as num;
        final absentCount = row['total_absent'] as num;
        cells.addAll([
          DataCell(Text(hours)),
          DataCell(
            Text(
              lateCount.toString(),
              style: TextStyle(color: lateCount > 0 ? Colors.red : null),
            ),
          ),
          DataCell(Text(row['total_early'].toString())),
          DataCell(
            Text(
              absentCount.toString(),
              style: TextStyle(color: absentCount > 0 ? Colors.red : null),
            ),
          ),
        ]);
      } else if (_selectedReportType == 'Leave Balances') {
        final entitled = (row['leave_entitled'] as num).toDouble();
        final used = (row['leave_used'] as num).toDouble();
        final remaining = entitled - used;
        cells.addAll([
          DataCell(Text(entitled.toString())),
          DataCell(Text(used.toString())),
          DataCell(
            Text(
              remaining.toString(),
              style: TextStyle(color: remaining < 0 ? Colors.red : null),
            ),
          ),
        ]);
      }

      return DataRow(cells: cells);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd');

    // 🚀 WATCHING THE PROVIDER FOR CURRENCY UPDATES
    final currencySymbol = context.watch<UserProvider>().currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports & Analytics"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportToCsv,
        backgroundColor: const Color(0xFF00A36C),
        icon: const Icon(Icons.download_rounded, color: Colors.white),
        label: const Text(
          "Export CSV",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      // 🚀 RESPONSIVENESS FIX: Center & Constrain the UI on Web
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              // --- TOP CONTROL BAR ---
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedReportType,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF00A36C),
                          ),
                          items: _reportTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() => _selectedReportType = newValue);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDateRange(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _fetchReport,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text("Update"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A36C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- SUMMARY CARDS ---
              if (!_isLoading) _buildSummaryCards(currencySymbol),

              // --- DYNAMIC DATA TABLE ---
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF00A36C)),
                  ),
                )
              else if (_reportData.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: Text("No records found for this date range."),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  // 🚀 LAYOUT BUILDER & MIN WIDTH: Forces the table to expand safely
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey.withOpacity(0.05),
                            ),
                            columns: _getColumns(),
                            rows: _getRows(currencySymbol),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
