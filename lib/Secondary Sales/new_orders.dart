import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:khilfatcola/Secondary%20Sales/secondaryoders.dart';
import 'package:khilfatcola/order_confirmation/demo.dart';
import 'package:khilfatcola/order_confirmation/sup_Order_Comfirm.dart';
import 'package:khilfatcola/utils/widgets.dart';
import 'package:khilfatcola/widgets/Splash.dart';
import 'package:khilfatcola/widgets/const.dart';


class DealershipScreen3   extends StatefulWidget {
  final int distributorID;
      
  
  const DealershipScreen3({
    super.key,
    required this.distributorID,
   
  });

  @override
  _DealershipScreenState createState() => _DealershipScreenState();
}

class _DealershipScreenState extends State<DealershipScreen3> {
  Dealership? dealership;
  List<SelectedProduct> selectedProducts = [];
  bool isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (_isDisposed) return;

    setState(() {
      isLoading = true;
    });

    try {
      dealership = await fetchDealership(widget.distributorID.toString());
      if (dealership == null) {
        throw Exception('Failed to fetch dealership data');
      }
      print('Products loaded from network');
    } catch (e) {
      print('Error loading products: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<Dealership> fetchDealership(String dealershipID) async {
    final url = Uri.parse(
      '${Constants.BASE_URL}/api/App/GetProductForDOByDistId?dealershipId=$dealershipID&appDateTime=${getCurrentDateTime()}',
    );

    print('Making request to: $url');

    final response = await http.get(
      headers: {'Authorization': '6XesrAM2Nu'},
      url,
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Parsed response data: $responseData');

      if (responseData['Data'] != null) {
        return Dealership.fromJson(
          Map<String, dynamic>.from(responseData['Data']),
        );
      } else {
        throw Exception('No data found in response');
      }
    } else if (response.statusCode == 410) {
      final responseData = jsonDecode(response.body);
      print('Parsed response data (410): $responseData');

      if (responseData['Data'] != null &&
          responseData['Data']['Message'] != null) {
        return Dealership.fromJson(
          Map<String, dynamic>.from(responseData['Data']['Message']),
        );
      }
      throw Exception('Failed to load dealership data');
    } else {
      throw Exception('Failed to load dealership data');
    }
  }

  void _showManualQuantityDialog(Products product) {
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Quantity'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter quantity"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                setState(() {
                  int? newQuantity = int.tryParse(quantityController.text);
                  if (newQuantity != null && newQuantity >= 0) {
                    product.orderQuantity = newQuantity;

                    if (!selectedProducts.any(
                      (p) => p.productId == product.productId,
                    )) {
                      selectedProducts.add(
                        SelectedProduct(
                          productId: product.productId,
                          distributorPrice: product.distributorPrice,
                          orderQuantity: product.orderQuantity,
                          productImage: product.imageName,
                          productVolumne: product.volumeInMl,
                          productName: product.name,
                        ),
                      );
                    } else {
                      selectedProducts
                          .firstWhere((p) => p.productId == product.productId)
                          .orderQuantity = product
                          .orderQuantity;
                    }
                  }
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _increaseQuantity(Products product) {
    setState(() {
      product.orderQuantity++;
      if (!selectedProducts.any((p) => p.productId == product.productId)) {
        selectedProducts.add(
          SelectedProduct(
            productId: product.productId,
            distributorPrice: product.distributorPrice,
            orderQuantity: product.orderQuantity,
            productImage: product.imageName,
            productVolumne: product.volumeInMl,
            productName: product.name,
          ),
        );
      } else {
        selectedProducts
                .firstWhere((p) => p.productId == product.productId)
                .orderQuantity =
            product.orderQuantity;
      }
    });
  }

  void _decreaseQuantity(Products product) {
    setState(() {
      if (product.orderQuantity > 0) {
        product.orderQuantity--;
        if (product.orderQuantity == 0) {
          selectedProducts.removeWhere((p) => p.productId == product.productId);
        } else {
          selectedProducts
                  .firstWhere((p) => p.productId == product.productId)
                  .orderQuantity =
              product.orderQuantity;
        }
      }
    });
  }

  void _navigateToSelectedProducts() {
    print('Selected Products : $selectedProducts');

    if (selectedProducts.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Empty Cart'),
            content: const Text('Your cart is empty. Please add some items.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectedProductsScreen(
            selectedProducts: selectedProducts,
            dealershipID: widget.distributorID,
            distributorName:
               
                dealership?.dealershipName ??
                'Unknown',
            distributorAddress:
                dealership?.address??"unknown",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.redAccent,
        title: const Text(
          'Primary Sale Products',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _navigateToSelectedProducts,
            child: const Text(
              'Checkout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  )
                : dealership == null
                ? const Center(
                    child: Text(
                      'No active Distributor Price Groups found for the Selected Distributor',
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(
                              constraints.maxWidth * 0.04,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    constraints.maxWidth * 0.04,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Distributor: ${dealership!.dealershipName}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Phone: ${dealership!.phoneNo}",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Address: ${dealership!.address}",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: dealership!.products.length,
                              itemBuilder: (context, index) {
                                final product = dealership!.products[index];
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  margin: EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: constraints.maxWidth * 0.04,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      constraints.maxWidth * 0.04,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 50,
                                          width: 30,
                                          child: product.imageName.isNotEmpty
                                              ? (product.imageName.startsWith(
                                                      'data:image',
                                                    )
                                                    ? Image.memory(
                                                        base64Decode(
                                                          product.imageName
                                                              .split(',')
                                                              .last,
                                                        ),
                                                      )
                                                    : Image.network(
                                                        'http://202.166.160.200:9085${product.imageName}',
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return Image.asset(
                                                                'assets/default_image.png',
                                                                fit: BoxFit
                                                                    .cover,
                                                              );
                                                            },
                                                      ))
                                              : Image.asset(
                                                  'assets/default_image.png',
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${product.name} (${product.volumeInMl} ml ${product.type} )",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Distributor Price: ${product.distributorPrice}\nQuantity in Pack: ${product.quantityInPack}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove,
                                                  ),
                                                  onPressed: () =>
                                                      _decreaseQuantity(
                                                        product,
                                                      ),
                                                ),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _showManualQuantityDialog(
                                                        product,
                                                      ),
                                                  child: Text(
                                                    '${product.orderQuantity}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add),
                                                  onPressed: () =>
                                                      _increaseQuantity(
                                                        product,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SelectedProductsScreen extends StatefulWidget {
  final List<SelectedProduct> selectedProducts;
  final int dealershipID;
  final String distributorName;
  final String distributorAddress;

  const SelectedProductsScreen({
    super.key,
    required this.selectedProducts,
    required this.dealershipID,
    required this.distributorName,
    required this.distributorAddress,
  });

  @override
  State<SelectedProductsScreen> createState() => _SelectedProductsScreenState();
}

class _SelectedProductsScreenState extends State<SelectedProductsScreen> {
  bool isLoading = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  String? _base64Image;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
        });
        await _convertImageToBase64(pickedFile.path);
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
        });
        await _convertImageToBase64(pickedFile.path);
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
      }
    }
  }

  Future<void> _showPicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _convertImageToBase64(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      if (!_isDisposed) {
        setState(() {
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      print('Error converting image to base64: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
      }
    }
  }



  Future<void> saveDealershipOrder() async {
    if (_isDisposed) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> orderItemCommandList = widget.selectedProducts
          .map((product) {
            return {
              "productId": product.productId,
              "DistributorPrice": product.distributorPrice,
              "orderQuantity": product.orderQuantity,
            };
          })
          .toList();

      final Map<String, dynamic> bodyData = {
        "dealershipId": dealershipID,
        "address": widget.distributorAddress,
        "userId": userid,
        "appDateTime": getCurrentDateTime(),
        "ImageFileSource": _base64Image,
        "OrderItemCommandList": orderItemCommandList,
      };

      // Convert to JSON and print in formatted way for Postman
      final JsonEncoder encoder = JsonEncoder.withIndent('  ');
      String jsonBody = encoder.convert(bodyData);

      print('=== POSTMAN TESTING PAYLOAD ===');
      print(jsonBody.toString());
      print('=== END PAYLOAD ===');

      final response = await http.post(
        Uri.parse("${Constants.BASE_URL}/api/App/SaveDealershipOrder"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '6XesrAM2Nu',
        },
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Order Created')));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SecondaryOrderHistoryScreen(),
            ),
          );
        }
      } else {
        throw Exception('Failed to save order: ${response.body}');
      }
    } catch (e) {
      print('Error saving order: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  // Add this helper function to your class
  String _buildCurlCommand(
    String url,
    Map<String, String> headers,
    String body,
  ) {
    String curl = 'curl -X POST \\\n';
    curl += '  \"$url\" \\\n';

    // Add headers
    headers.forEach((key, value) {
      curl += '  -H \"$key: $value\" \\\n';
    });

    // Add body (with proper escaping for single quotes)
    String escapedBody = body.replaceAll("'", "'\\''");
    curl += '  -d \'$escapedBody\'';

    return curl;
  }

  // Ensure your getCurrentDateTime function returns proper format
  String getCurrentDateTime() {
    // Use ISO 8601 format (most APIs accept this)
    return DateTime.now().toUtc().toIso8601String();

    // Or if you need specific format:
    // final now = DateTime.now();
    // return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    int totalQuantity = widget.selectedProducts.fold(
      0,
      (sum, product) => sum + product.orderQuantity,
    );
    double totalAmount = widget.selectedProducts.fold(
      0.0,
      (sum, product) =>
          sum + (product.orderQuantity * product.distributorPrice),
    );

    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.redAccent,
        title: const Text(
          'Selected Products',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.selectedProducts.length,
                  itemBuilder: (context, index) {
                    final product = widget.selectedProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: product.productImage.isNotEmpty
                                  ? (product.productImage.startsWith(
                                          'data:image',
                                        )
                                        ? Image.memory(
                                            base64Decode(
                                              product.productImage
                                                  .split(',')
                                                  .last,
                                            ),
                                            width: 70,
                                            height: 70,
                                          )
                                        : Image.network(
                                            'http://202.166.160.200:9085${product.productImage}',
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/default_image.png',
                                                    width: 70,
                                                    height: 70,
                                                  );
                                                },
                                          ))
                                  : Image.asset(
                                      'assets/default_image.png',
                                      width: 70,
                                      height: 70,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                   mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      const SizedBox(height: 5),
                                      Text(
                                        'Name: ${product.productName}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Volume in ML: ${product.productVolumne} ml',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Distributor Price: ${(product.distributorPrice).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text(
                                        'QTY:',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${product.orderQuantity}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey.shade300, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Total Quantity: $totalQuantity',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Amount: Rs.$totalAmount',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showPicker(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Attach Payment Invoice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _image != null
                  ? Image.file(File(_image!.path), width: 100, height: 100)
                  : const Text('No image selected'),
              const SizedBox(height: 20),
              Padding(    
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () async {   
                    if (_image == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please Attach Payment Invoice'),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Center(child: Text("Confirm Order")),
                            content: const Text(
                              'Are you sure you want to save this order?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Close"),
                              ),
                              TextButton(
                                onPressed: (  ) async {
                                  Navigator.pop(context);
                                  await saveDealershipOrder();
                                },
                                child: const Text("Yes"),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Save Order',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
