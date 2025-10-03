import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:khilfatcola/widgets/Splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Ledger',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const LedgerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Data Models
class DealershipLedgerResponse {
  final int status;
  final String message;
  final List<LedgerData> data;

  DealershipLedgerResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory DealershipLedgerResponse.fromJson(Map<String, dynamic> json) {
    return DealershipLedgerResponse(
      status: json['Status'],
      message: json['Message'],
      data: (json['Data'] as List)
          .map((item) => LedgerData.fromJson(item))
          .toList(),
    );
  }
}

class LedgerData {
  final DateTime date;
  final String code;
  final String accountCode;
  final String accountName;
  final double openingBalance;
  final double debitAmount;
  final double creditAmount;
  final double runningBalance;
  final String referenceNumber;
  final String? chequeNo;
  final DateTime chequeDate;
  final String remarks;

  LedgerData({
    required this.date,
    required this.code,
    required this.accountCode,
    required this.accountName,
    required this.openingBalance,
    required this.debitAmount,
    required this.creditAmount,
    required this.runningBalance,
    required this.referenceNumber,
    required this.chequeNo,
    required this.chequeDate,
    required this.remarks,
  });

  factory LedgerData.fromJson(Map<String, dynamic> json) {
    return LedgerData(
      date: DateTime.parse(json['Date']),
      code: json['Code'],
      accountCode: json['AccountCode'],
      accountName: json['AccountName'],
      openingBalance: (json['OpeningBalance'] as num).toDouble(),
      debitAmount: (json['DebitAmount'] as num).toDouble(),
      creditAmount: (json['CreditAmount'] as num).toDouble(),
      runningBalance: (json['RunningBalance'] as num).toDouble(),
      referenceNumber: json['ReferenceNumber'],
      chequeNo: json['ChequeNo'],
      chequeDate: DateTime.parse(json['ChequeDate']),
      remarks: json['Remarks'],
    );
  }
}

// API Service
class LedgerService {
  static const String baseUrl =
      'http://202.166.160.200:9086/api/App/GetDealershipAccountLedger';

  Future<DealershipLedgerResponse> getDealershipLedger({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "fDate": fromDate.toIso8601String(),
        "tDate": toDate.toIso8601String(),
        "dealershipId": dealershipID,
        "appDateTime": DateTime.now().toIso8601String(),
      };

      print('API Request: $requestBody'); // Debug print

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': '6XesrAM2Nu',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('API Response Status: ${responseData['Status']}'); // Debug print
        print('API Response Message: ${responseData['Message']}'); // Debug print
        print('API Data Count: ${(responseData['Data'] as List).length}'); // Debug print
        return DealershipLedgerResponse.fromJson(responseData);
      } else {
        throw Exception(
          'Failed to load ledger data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load ledger data: $e');
    }
  }
}

// Date Filter Widget
class DateFilterWidget extends StatefulWidget {
  final DateTime initialFromDate;
  final DateTime initialToDate;
  final Function(DateTime, DateTime) onDateRangeChanged;

  const DateFilterWidget({
    super.key,
    required this.initialFromDate,
    required this.initialToDate,
    required this.onDateRangeChanged,
  });

  @override
  State<DateFilterWidget> createState() => _DateFilterWidgetState();
}

class _DateFilterWidgetState extends State<DateFilterWidget> {
  late DateTime _fromDate;
  late DateTime _toDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
      widget.onDateRangeChanged(_fromDate, _toDate);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
      widget.onDateRangeChanged(_fromDate, _toDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _selectFromDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_dateFormat.format(_fromDate)),
                              const Icon(Icons.calendar_today, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'To Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _selectToDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_dateFormat.format(_toDate)),
                              const Icon(Icons.calendar_today, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selected Range: ${_dateFormat.format(_fromDate)} to ${_dateFormat.format(_toDate)}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

// Main Screen
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final LedgerService _ledgerService = LedgerService();
  late Future<DealershipLedgerResponse> _ledgerFuture;
  List<LedgerData> _ledgerData = [];
  List<LedgerData> _filteredLedgerData = [];

  // Date filter variables
  DateTime _fromDate = DateTime(2025, 1, 1);
  DateTime _toDate = DateTime(2025, 9, 26);

  // Landscape mode state
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Set initial orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _loadData() {
    setState(() {
      _ledgerFuture = _ledgerService.getDealershipLedger(
        fromDate: _fromDate,
        toDate: _toDate,
      );
    });
  }

  void _onDateRangeChanged(DateTime fromDate, DateTime toDate) {
    setState(() {
      _fromDate = fromDate;
      _toDate = toDate;
    });
    _loadData();
  }

  void _filterDataByDateRange() {
    setState(() {
      _filteredLedgerData = _ledgerData.where((transaction) {
        return transaction.date.isAfter(_fromDate.subtract(const Duration(days: 1))) &&
               transaction.date.isBefore(_toDate.add(const Duration(days: 1)));
      }).toList();
    });
  }

  // Toggle landscape mode
  void _toggleLandscapeMode() {
    setState(() {
      _isLandscape = !_isLandscape;
    });

    if (_isLandscape) {
      // Set to landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Set to portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    // Reset orientation when screen is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  // Build arranged data table with specified columns only
  Widget _buildArrangedDataTable() {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final numberFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    // Use filtered data for display
    final displayData = _filteredLedgerData.isNotEmpty ? _filteredLedgerData : _ledgerData;

    // Calculate grand totals
    double grandTotalDebit = displayData.fold(0, (sum, item) => sum + item.debitAmount);
    double grandTotalCredit = displayData.fold(0, (sum, item) => sum + item.creditAmount);
    double finalBalance = displayData.isNotEmpty ? displayData.last.runningBalance : 0;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) => Colors.blue[50],
            ),
            columnSpacing: 20,
            columns: const [
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Code',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Cheque No',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Remarks',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Debit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Credit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Balance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: displayData.map((transaction) {
              return DataRow(
                cells: [
                  // Date
                  DataCell(Text(dateFormat.format(transaction.date))),

                  // Code
                  DataCell(Text(transaction.code)),

                  // Cheque No
                  DataCell(
                    Text(
                      transaction.chequeNo == null || transaction.chequeNo!.isEmpty
                          ? '-'
                          : transaction.chequeNo!,
                    ),
                  ),

                  // Remarks
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: Tooltip(
                        message: transaction.remarks,
                        child: Text(
                          transaction.remarks,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),

                  // Debit Amount
                  DataCell(
                    Text(
                      transaction.debitAmount > 0
                          ? numberFormat.format(transaction.debitAmount)
                          : '-',
                      style: TextStyle(
                        color: transaction.debitAmount > 0 ? Colors.red : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Credit Amount
                  DataCell(
                    Text(
                      transaction.creditAmount > 0
                          ? numberFormat.format(transaction.creditAmount)
                          : '-',
                      style: TextStyle(
                        color: transaction.creditAmount > 0 ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Running Balance
                  DataCell(
                    Text(
                      numberFormat.format(transaction.runningBalance),
                      style: TextStyle(
                        color: transaction.runningBalance < 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        
        // Grand Total Row
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Debit: ${numberFormat.format(grandTotalDebit)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Credit: ${numberFormat.format(grandTotalCredit)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    final displayData = _filteredLedgerData.isNotEmpty ? _filteredLedgerData : _ledgerData;
    
    if (displayData.isEmpty) return const SizedBox();

    final numberFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Info
          Text(
            'Account: ${displayData.first.accountName}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          
          // Account Code
          Text(
            'Account Code: ${displayData.first.accountCode}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading ledger data...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Transactions Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your date range',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealership Account'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              _isLandscape ? Icons.stay_current_portrait : Icons.stay_current_landscape,
              color: Colors.white,
            ),
            onPressed: _toggleLandscapeMode,
            tooltip: _isLandscape ? 'Switch to Portrait' : 'Switch to Landscape',
          ),
        ],
      ),
      body: FutureBuilder<DealershipLedgerResponse>(
        future: _ledgerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (snapshot.hasData) {
            _ledgerData = snapshot.data!.data;
            _filteredLedgerData = _ledgerData; // Initially show all data

            print('Data loaded: ${_ledgerData.length} transactions');

            if (_ledgerData.isEmpty) {
              return _buildEmptyState();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Account Info Card at the top
                  _buildHeaderInfo(),
                  
                  // Date Filter Widget below account info
                  DateFilterWidget(
                    initialFromDate: _fromDate,
                    initialToDate: _toDate,
                    onDateRangeChanged: _onDateRangeChanged,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Data Table with horizontal scrolling
                  _buildArrangedDataTable(),
                ],
              ),
            );
          } else {
            return _buildEmptyState();
          }
        },
      ),
    );
  }
}