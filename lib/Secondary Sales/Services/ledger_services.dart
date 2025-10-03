// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://202.166.160.200:9086/api/App';

  static Future<LedgerResponse> getDealershipAccountLedger({
    required DateTime fromDate,
    required DateTime toDate,
    required int dealershipId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/GetDealershipAccountLedger'),
        headers: {
          'Authorization': '6XesrAM2Nu',
          'Content-Type': 'application/json'},
        body: jsonEncode({
          // 'fDate': fromDate.toIso8601String(),
          // 'tDate': toDate.toIso8601String(),
          // 'dealershipId': dealershipId,
          // 'appDateTime': DateTime.now().toIso8601String(),

            "fDate": "2025-01-01T12:14:42.614Z",
          "tDate": "2025-09-26T12:14:42.614Z",
          "dealershipId": 280,
          "appDateTime": "2025-09-30T12:14:42.614Z"
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LedgerResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Failed to load ledger data. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('API Error: $e');
      throw Exception('Failed to load ledger data: $e');
    }
  }
}

class LedgerResponse {
  final int status;
  final String message;
  final List<LedgerData> data;

  LedgerResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory LedgerResponse.fromJson(Map<String, dynamic> json) {
    // Debug print to see actual response structure
    print('Response JSON: $json');

    // Handle case where Data might be null or not a list
    List<LedgerData> dataList = [];

    if (json['Data'] != null) {
      if (json['Data'] is List) {
        dataList = (json['Data'] as List)
            .map((item) => LedgerData.fromJson(item))
            .toList();
      } else {
        print('Data is not a list: ${json['Data']}');
      }
    } else {
      print('Data field is null');
    }

    return LedgerResponse(
      status: json['Status'] ?? 0,
      message: json['Message'] ?? 'No message',
      data: dataList,
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
    // Handle potential null values and type conversions
    return LedgerData(
      date: _parseDateTime(json['Date']),
      code: json['Code']?.toString() ?? 'N/A',
      accountCode: json['AccountCode']?.toString() ?? 'N/A',
      accountName: json['AccountName']?.toString() ?? 'N/A',
      openingBalance: _parseDouble(json['OpeningBalance']),
      debitAmount: _parseDouble(json['DebitAmount']),
      creditAmount: _parseDouble(json['CreditAmount']),
      runningBalance: _parseDouble(json['RunningBalance']),
      referenceNumber: json['ReferenceNumber']?.toString() ?? '',
      chequeNo: json['ChequeNo']?.toString(),
      chequeDate: _parseDateTime(json['ChequeDate']),
      remarks: json['Remarks']?.toString() ?? '',
    );
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    try {
      if (dateValue == null || dateValue == '0001-01-01T00:00:00') {
        return DateTime.now();
      }
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
      return DateTime.now();
    }
  }

  static double _parseDouble(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    } catch (e) {
      print('Error parsing double: $value, error: $e');
      return 0.0;
    }
  }
}
