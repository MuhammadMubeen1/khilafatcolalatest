import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:khilfatcola/Secondary%20Sales/loginrepo.dart';
import 'package:khilfatcola/Secondary%20Sales/new_orders.dart';
import 'package:khilfatcola/Supervisor/distributor_selection_screen.dart';
import 'package:khilfatcola/order_confirmation/blinking.dart';
import 'package:khilfatcola/widgets/Splash.dart';

class SecondaryOrderHistoryScreen extends StatefulWidget {
  const SecondaryOrderHistoryScreen({super.key});

  @override
  _SupervisorOrderHistoryScreenState createState() =>
      _SupervisorOrderHistoryScreenState();
}

class _SupervisorOrderHistoryScreenState
    extends State<SecondaryOrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  // Status IDs for the new API
  final List<String> statusIds = [
    'all', // All orders
    '10', // Create
    '15', // In Process
    '20', // Account Reviewed
    '30', // Order Confirm
    '40', // Order Dispatched
    '50', // Order Received
    '60', // Canceled
  ];

  String selectedStatusId = 'all';
  late TabController _tabController;

  // Date filter variables
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  bool _showDateFilter = false;

  // Pagination variables for each tab
  Map<String, int> _currentPages = {};
  Map<String, bool> _isLoadingMore = {};
  Map<String, bool> _hasMoreData = {};
  Map<String, List<dynamic>> _cachedData = {};
  Map<String, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    print("Dealership IDss: $dealershipID");

    // Initialize pagination variables for each tab
    for (String statusId in statusIds) {
      _currentPages[statusId] = 0;
      _isLoadingMore[statusId] = false;
      _hasMoreData[statusId] = true;
      _cachedData[statusId] = [];
      _scrollControllers[statusId] = ScrollController()
        ..addListener(() {
          _onScrollListener(statusId);
        });
    }

    _tabController = TabController(length: statusIds.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectedStatusId = statusIds[_tabController.index];
          print('Switched to Tab: $selectedStatusId');
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    // Dispose all scroll controllers
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  void _onScrollListener(String statusId) {
    if (_scrollControllers[statusId]!.position.pixels ==
        _scrollControllers[statusId]!.position.maxScrollExtent) {
      if (!_isLoadingMore[statusId]! && _hasMoreData[statusId]!) {
        _loadMoreData(statusId);
      }
    }
  }

  void _loadMoreData(String statusId) {
    if (_isLoadingMore[statusId]! || !_hasMoreData[statusId]!) return;

    setState(() {
      _isLoadingMore[statusId] = true;
    });

    _currentPages[statusId] = _currentPages[statusId]! + 1;

    fetchOrdersData(statusId, _currentPages[statusId]!)
        .then((newData) {
          setState(() {
            _isLoadingMore[statusId] = false;

            if (newData.isNotEmpty) {
              _cachedData[statusId]!.addAll(newData);
            } else {
              _hasMoreData[statusId] = false;
            }
          });
        })
        .catchError((error) {
          setState(() {
            _isLoadingMore[statusId] = false;
            _currentPages[statusId] =
                _currentPages[statusId]! - 1; // Revert page on error
          });
          print('Error loading more data for status $statusId: $error');
        });
  }

 Future<List<dynamic>> fetchOrdersData(String statusId, int page) async {
    final url = Uri.parse(
      'http://202.166.160.200:9086/api/App/GetDealershipOrder',
    );

    try {
      // Corrected request body - removed the extra curly braces
      final body = {
        "OrderId": 0,
        "StatusId": statusId == 'all' ? 0 : int.parse(statusId),
        "FDate": "${_dateFormat.format(_fromDate)}T00:00:00.000Z",
        "TDate": "${_dateFormat.format(_toDate)}T23:59:59.999Z",
        "DealershipId": dealershipID,
        "AppDateTime": getCurrentDateTime(),
        "PagingData": {
          "CurrentPage": page,
          "Take": 10,
          "IsPagingEnabled": true,
        },
      };

      print('Fetching orders for status: $statusId, page: $page');
      print('From Date: ${_dateFormat.format(_fromDate)}');
      print('To Date: ${_dateFormat.format(_toDate)}');
      print('Dealership ID: $dealershipID');
      print('Request body: ${json.encode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': '6XesrAM2Nu',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['Data'] != null && decoded['Data']['Item1'] != null) {
          final data = decoded['Data']['Item1'] as List<dynamic>;
          print(
            'Fetched ${data.length} orders for status $statusId, page $page',
          );
          return data;
        } else {
          print('No data found in response for status $statusId, page $page');
          return [];
        }
      } else {
        print(
          'API call failed with status: ${response.statusCode} for status $statusId, page $page',
        );
        return [];
      }
    } catch (e) {
      print('Error fetching orders for status $statusId, page $page: $e');
      return [];
    }
  }

  Future<void> refreshData() async {
    // Reset all pagination data and reload
    for (String statusId in statusIds) {
      _currentPages[statusId] = 0;
      _isLoadingMore[statusId] = false;
      _hasMoreData[statusId] = true;
      _cachedData[statusId] = [];
    }

    setState(() {});
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
        if (_fromDate.isAfter(_toDate)) {
          _toDate = _fromDate;
        }
      });
      refreshData(); // Refresh data when date changes
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
        if (_toDate.isBefore(_fromDate)) {
          _fromDate = _toDate;
        }
      });
      refreshData(); // Refresh data when date changes
    }
  }

  void _applyDateFilter() {
    setState(() {
      _showDateFilter = false;
    });
    refreshData();
  }

  void _resetDateFilter() {
    setState(() {
      _fromDate = DateTime.now().subtract(const Duration(days: 30));
      _toDate = DateTime.now();
      _showDateFilter = false;
    });
    refreshData();
  }

  String getCurrentDateTime() {
    return DateTime.now().toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.redAccent,
        title: const Text(
          "Primary Sale",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(color: Colors.grey.shade200),
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Created"),
            Tab(text: "In Process"),
            Tab(text: "Account Reviewed"),
            Tab(text: "Confirm"),
            Tab(text: "Dispatched"),
            Tab(text: "Received"),
            Tab(text: "Canceled"),
          ],
        ),
        actions: [
          // Date Filter Icon
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: () {
              setState(() {
                _showDateFilter = !_showDateFilter;
              });
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DealershipScreen3(
                    distributorID: int.parse(dealershipID.toString()),
                  ),
                ),
              ).then((_) {
                // refreshData();
              });
            },
            child: const Text(
              "New Order",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Filter Section
          if (_showDateFilter) _buildDateFilterSection(),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int i = 0; i < statusIds.length; i++)
                  FutureBuilder<List<dynamic>>(
                    future: _cachedData[statusIds[i]]!.isEmpty
                        ? fetchOrdersData(statusIds[i], 0).then((data) {
                            _cachedData[statusIds[i]] = data;
                            return data;
                          })
                        : Future.value(_cachedData[statusIds[i]]),
                    builder: (context, snapshot) {
                      return RefreshIndicator(
                        onRefresh: () => refreshData(),
                        child: _buildOrderList(snapshot, statusIds[i]),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Filter by Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectFromDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(_fromDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectToDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(_toDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetDateFilter,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyDateFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Apply Filter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOrderList(
    AsyncSnapshot<List<dynamic>> snapshot,
    String statusId,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        _cachedData[statusId]!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError && _cachedData[statusId]!.isEmpty) {
      return Center(child: Text('Error: ${snapshot.error}'));
    } else {
      var data = _cachedData[statusId]!;

      return Column(
        children: [
          // Date Range Summary
          if (!_showDateFilter)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(_fromDate)} - ${DateFormat('MMM dd, yyyy').format(_toDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollControllers[statusId],
              itemCount: data.length + (_hasMoreData[statusId]! ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == data.length) {
                  return _buildLoadMoreIndicator(statusId);
                }

                return AllOrderListItem(
                  order: data[index],
                  statusId: statusId,
                  onStatusUpdate: (newStatusId, orderId, comments) {
                    _showStatusUpdateDialog(newStatusId, orderId, comments);
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildLoadMoreIndicator(String statusId) {
    if (!_hasMoreData[statusId]!) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No more orders to load',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _isLoadingMore[statusId]!
            ? const CircularProgressIndicator()
            : GestureDetector(
                onTap: () => _loadMoreData(statusId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Load More',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _showStatusUpdateDialog(
    String newStatusId,
    String orderId,
    String comments,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Status"),
          content: Text("Update order $orderId to status $newStatusId?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}

class AllOrderListItem extends StatefulWidget {
  final Map<String, dynamic> order;
  final String statusId;
  final Function(String, String, String) onStatusUpdate;

  const AllOrderListItem({
    Key? key,
    required this.order,
    required this.statusId,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  _AllOrderListItemState createState() => _AllOrderListItemState();
}

class _AllOrderListItemState extends State<AllOrderListItem> {
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _deliveryChallanController =
      TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    var order = widget.order;
    var orderId = order['Id'] ?? order['OrderID'] ?? 'N/A';
    var orderStatus = order['OrderStatus'] ?? 'Unknown';
    var orderDate = order['CreatedDate'] ?? order['OrderDate'] ?? 'Unknown';
    var dealerShipName =
        name; // order['DealerShipName'] ?? 'Unknown Distributor';

    // Extract order items - adjust field names based on your API response
    var orderItems = order['OrderItems'] as List<dynamic>?;
    var products = order['Products'] as List<dynamic>?;
    var items = orderItems ?? products ?? [];

    // Extract additional data for the enhanced UI
    var orderProcess = order['OrderProcess'] as List<dynamic>?;
    var orderAttachments = order['OrderAttachments'] as List<dynamic>?;
    var address = order['Address'] ?? 'No address available';

    // Calculate totals
    int totalQuantity = 0;
    double totalPrice = 0.0;
    for (var item in items) {
      var product = item['Item'] ?? item;
      int quantity = item['Quantity'] ?? product['Quantity'] ?? 0;
      double price =
          (item['DistributorPrice'] ?? product['DistributorPrice'] ?? 0.0)
              .toDouble();
      totalQuantity += quantity;
      totalPrice += price * quantity;
    }

    // Get status color
    Color statusColor = _getStatusColor(orderStatus);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getStatusIcon(orderStatus),
            color: statusColor,
            size: 22,
          ),
        ),
        title: const Row(
          children: [
            Text(
              'Order',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 5),
            Icon(Icons.arrow_drop_down, color: Colors.black87),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              _formatDate(orderDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                orderStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${items.length} items',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Text(
              'Rs. ${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        children: [
          // Basic order information
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Distributor:', dealerShipName),
                _buildDetailRow('Address:', address),
                _buildDetailRow('Order ID:', orderId.toString()),
              ],
            ),
          ),

          // Order image/attachments
          if (orderAttachments != null && orderAttachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: orderAttachments.length,
                      itemBuilder: (context, index) {
                        var attachment = orderAttachments[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.network(
                                  'http://202.166.160.200:9085${attachment['FileSource'] ?? attachment['Image']}',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

          // Order items
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      var product = item['Item'] ?? item;
                      int quantity =
                          item['Quantity'] ?? product['Quantity'] ?? 0;
                      double price =
                          (item['DistributorPrice'] ??
                                  product['DistributorPrice'] ??
                                  0)
                              .toDouble();
                      double itemTotal = price * quantity;
                      String productName =
                          product['ProductName'] ??
                          product['Name'] ??
                          'Unknown Product';
                      String description =
                          product['Description'] ??
                          product['ProductType'] ??
                          'No description available';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image
                            _buildProductImage(product),
                            const SizedBox(width: 14),
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Rs. $price × $quantity = Rs. ${itemTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: Colors.redAccent, height: 1, thickness: 0.5),
          ),

          // Order process history
          if (orderProcess != null && orderProcess.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...orderProcess.map(
                    (process) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  process['ToStatus'] ?? 'Status Update',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (process['Comments'] != null &&
                                    (process['Comments'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '${process['Comments']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _formatDate(process['CreatedDate'] ?? ''),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons based on status
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: _buildActionButtons(orderId.toString()),
          ),

          // Total summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL ITEMS',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalQuantity Items',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TOTAL AMOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rs. ${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    var imageUrl = product['ImageName'] ?? product['Image'];
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      if (imageUrl.toString().startsWith('data:image')) {
        return Image.memory(
          base64Decode(imageUrl.toString().split(',').last),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderIcon(60),
        );
      } else {
        String fullImageUrl = imageUrl.toString().startsWith('http')
            ? imageUrl.toString()
            : 'http://202.166.160.200:9085${imageUrl}';
        return Image.network(
          fullImageUrl,
          height: 50,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderIcon(60),
        );
      }
    }
    return _buildPlaceholderIcon(60);
  }

  Widget _buildPlaceholderIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: size / 2,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildActionButtons(String orderId) {
    switch (widget.statusId) {
      case '10': // Created - Show Edit and Delete
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _editOrder(orderId),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _deleteOrder(orderId),
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        );
      case '40': // Dispatched - Show Receive button
        return Center(
          child: ElevatedButton.icon(
            onPressed: () => _receiveOrder(orderId),
            icon: const Icon(Icons.check_circle),
            label: const Text('Receive Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
          ),
        );
      case '15': // In Process
      case '20': // Account Reviewed
      case '30': // Order Confirm
      case '50': // Order Received
      default:
        return Container(); // No action buttons for other statuses
    }
  }

  void _editOrder(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Order'),
        content: const Text('Edit functionality to be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteOrder(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _receiveOrder(String orderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Receive Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deliveryChallanController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Challan Code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comments (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Confirm Receive'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('MMM d, y • hh:mm a').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Order Dispatched':
        return Colors.green;
      case 'Order Confirmed':
        return Colors.blue;
      case 'In Process':
        return Colors.orange;
      case 'Account Reviewed':
        return Colors.purple;
      case 'Order Create':
        return Colors.blueGrey;
      default:
        return Colors.redAccent;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Order Dispatched':
        return Icons.local_shipping;
      case 'Order Confirmed':
        return Icons.check_circle;
      case 'In Process':
        return Icons.autorenew;
      case 'Account Reviewed':
        return Icons.verified_user;
      case 'Order Create':
        return Icons.add_shopping_cart;
      default:
        return Icons.info;
    }
  }
}
