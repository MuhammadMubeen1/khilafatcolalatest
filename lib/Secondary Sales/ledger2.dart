import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StocksssBalanceScreen extends StatefulWidget {
  @override
  _StockBalanceScreenState createState() => _StockBalanceScreenState();
}

class _StockBalanceScreenState extends State<StocksssBalanceScreen> {
  List<StockItem> stockItems = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchStockBalance();
  }

  Future<void> fetchStockBalance() async {
    try {
      final response = await http.post(
        Uri.parse('http://202.166.160.200:9086/api/App/GetDealershipStockBalance'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "6XesrAM2Nu",
        },
        body: json.encode({
          "dealershipId": 7,
          "appDateTime": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['Status'] == 200) {
          setState(() {
            stockItems = (data['Data'] as List)
                .map((item) => StockItem.fromJson(item))
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['Message'] ?? 'Failed to load data';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'HTTP Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    double totalQuantityIn = stockItems.fold(0, (sum, item) => sum + item.quantityIn);
    double totalQuantityOut = stockItems.fold(0, (sum, item) => sum + item.quantityOut);
    double totalBalance = stockItems.fold(0, (sum, item) => sum + item.balance);

    return Scaffold(
      appBar: AppBar(
        title: Text('Disturbutor Stock '),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchStockBalance,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchStockBalance,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced overall padding
                  child: Column(
                    children: [
                      SizedBox(height: 8), // Reduced spacing
                      
                      // Data Table with compact layout
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                width: constraints.maxWidth > 500 ? constraints.maxWidth : 500, // Reduced minimum width
                                child: Column(
                                  children: [
                                    // Table Header
                                    Container(
                                      color: Colors.blue[50],
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3, // Increased flex for Product Name
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8), // Reduced padding
                                              child: Text(
                                                'Product Name',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14, // Slightly smaller font
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2, // Adjusted flex for Quantity In
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Reduced padding
                                              child: Text(
                                                'Qty In',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14, // Slightly smaller font
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2, // Adjusted flex for Quantity Out
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Reduced padding
                                              child: Text(
                                                'Qty Out',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14, // Slightly smaller font
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2, // Adjusted flex for Balance
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Reduced padding
                                              child: Text(
                                                'Balance',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14, // Slightly smaller font
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Table Body
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: stockItems.map((item) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3, // Increased flex for Product Name
                                                    child: Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10), // Reduced padding
                                                      child: Text(
                                                        item.name,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 13, // Slightly smaller font
                                                        ),
                                                        maxLines: 2, // Allow text to wrap
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2, // Adjusted flex for Quantity In
                                                    child: Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10), // Reduced padding
                                                      child: Text(
                                                        item.quantityIn.toStringAsFixed(2),
                                                        style: TextStyle(fontSize: 13), // Slightly smaller font
                                                        textAlign: TextAlign.right,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2, // Adjusted flex for Quantity Out
                                                    child: Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10), // Reduced padding
                                                      child: Text(
                                                        item.quantityOut.toStringAsFixed(2),
                                                        style: TextStyle(fontSize: 13), // Slightly smaller font
                                                        textAlign: TextAlign.right,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2, // Adjusted flex for Balance
                                                    child: Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10), // Reduced padding
                                                      child: Text(
                                                        item.balance.toStringAsFixed(2),
                                                        style: TextStyle(
                                                          fontSize: 13, // Slightly smaller font
                                                          color: item.balance < 0 ? Colors.red : Colors.green,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        textAlign: TextAlign.right,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    
                                    // Totals Row
                                    Container(
                                      color: Colors.grey[100],
                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Reduced padding
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3, // Increased flex for Product Name
                                            child: Text(
                                              'TOTAL',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14, // Slightly smaller font
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2, // Adjusted flex for Quantity In
                                            child: Text(
                                              totalQuantityIn.toStringAsFixed(2),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14, // Slightly smaller font
                                                color: Colors.blue[800],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2, // Adjusted flex for Quantity Out
                                            child: Text(
                                              totalQuantityOut.toStringAsFixed(2),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14, // Slightly smaller font
                                                color: Colors.blue[800],
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2, // Adjusted flex for Balance
                                            child: Text(
                                              totalBalance.toStringAsFixed(2),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14, // Slightly smaller font
                                                color: totalBalance < 0 ? Colors.red : Colors.green,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }
}

class StockItem {
  final String name;
  final double quantityIn;
  final double quantityOut;
  final double balance;

  StockItem({
    required this.name,
    required this.quantityIn,
    required this.quantityOut,
    required this.balance,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      name: json['Name'] ?? '',
      quantityIn: (json['QuantityIn'] ?? 0).toDouble(),
      quantityOut: (json['QuantityOut'] ?? 0).toDouble(),
      balance: (json['Balance'] ?? 0).toDouble(),
    );
  }
}