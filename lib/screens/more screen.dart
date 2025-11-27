import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../resources/prefs.dart';

class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({Key? key}) : super(key: key);

  @override
  _RemoveAdsScreenState createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  ProductDetails? _oneTimePurchaseProduct;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('DEBUG: initState called');
    _initialize();
  }

  Future<void> _initialize() async {
    print('DEBUG: _initialize started');

    try {
      print('DEBUG: Checking IAP availability...');
      final bool available = await _inAppPurchase.isAvailable();
      print('DEBUG: IAP available: $available');

      if (!available) {
        print('DEBUG: IAP not available, showing UI anyway');
        if (mounted) {
          setState(() => _isLoading = false);
          _showDialog('Info', 'In-app purchases are not available on this device.');
        }
        return;
      }

      print('DEBUG: Defining product IDs...');
      const Set<String> ids = {
        'kingvpn_999_1m',
        'kingvpn_999_1year',
        'one_time_purchase',
      };
      print('DEBUG: Product IDs: $ids');

      print('DEBUG: Querying products...');

      // Add timeout to prevent hanging forever
      final response = await _inAppPurchase.queryProductDetails(ids);
      // final response = await _inAppPurchase.queryProductDetails(ids).timeout(
      //   const Duration(seconds: 10),
      //   onTimeout: () {
      //     print('DEBUG: Query timed out after 10 seconds');
      //     return ProductDetailsResponse(
      //       productDetails: [],
      //       notFoundIDs: ids.toList(),
      //       error: IAPError(
      //         source: 'timeout',
      //         code: 'query_timeout',
      //         message: 'Product query timed out. Products may not be configured in Google Play Console.',
      //       ),
      //     );
      //   },
      // );

      print('DEBUG: Query response received');
      print('DEBUG: Error: ${response.error}');
      print('DEBUG: Product count: ${response.productDetails.length}');
      print('DEBUG: Not found IDs: ${response.notFoundIDs}');

      print('DEBUG: Processing products...');
      final products = response.productDetails;
      ProductDetails? oneTime;

      for (var product in products) {
        print('DEBUG: Found product: ${product.id} - ${product.title}');
        if (product.id == 'one_time_purchase') {
          oneTime = product;
        }
      }

      print('DEBUG: Setting state with ${products.length} products');
      if (mounted) {
        setState(() {
          _products = products;
          _oneTimePurchaseProduct = oneTime;
          _isLoading = false;
        });
      }

      // Show helpful message if no products found
      if (products.isEmpty && mounted) {
        _showDialog('Info',
            'No products available.\n\n'
                'Possible reasons:\n'
                '• Products not synced yet (can take up to 24 hours)\n'
                '• App not installed from Play Store\n'
                '• Not using release build\n'
                '• Testing account not added as tester in Play Console\n'
                '• Product IDs don\'t match exactly');
      }

      print('DEBUG: Initialization complete!');
    } catch (e, stackTrace) {
      print('DEBUG: ERROR in _initialize: $e');
      print('DEBUG: Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);
        _showDialog('Error', 'Initialization failed: $e\n\nPlease ensure:\n• App is installed from Play Store\n• Products are configured in Google Play Console\n• You\'re using a release build');
      }
    }
  }

  void _handlePurchase(PurchaseDetails purchaseDetails) async {
    // Purchase handling is now done in main.dart
    // This method is kept for compatibility
    print('DEBUG: Purchase handled in main.dart');
  }

  void _buySubscription(ProductDetails product) {
    print('DEBUG: Buying subscription: ${product.id}');

    if (Prefs.getBool('isSubscribed') ?? false) {
      _showDialog('Info', 'You already have an active subscription.');
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _buyOneTimePurchaseProduct() {
    print('DEBUG: Buying one-time purchase');

    if (_oneTimePurchaseProduct == null) {
      _showDialog('Error', 'One-time purchase not available.');
      return;
    }

    if (Prefs.getBool('isSubscribed') ?? false) {
      _showDialog('Info', 'You already have an active subscription.');
      return;
    }

    final purchaseParam =
    PurchaseParam(productDetails: _oneTimePurchaseProduct!);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: build called, isLoading: $_isLoading');

    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = height * width;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.black],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Loading products...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'This may take a few seconds',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: height * 0.02),
                child: ListTile(
                  title: const Text(
                    'Get Access Premium Service',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                  ),
                ),
              ),
              if (_products.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.white, size: 48),
                          const SizedBox(height: 20),
                          const Text(
                            'No Products Available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Please ensure:\n'
                                '• Products are configured in Google Play Console\n'
                                '• Products are Active status\n'
                                '• App is installed from Play Store (not sideloaded)\n'
                                '• Using release build (not debug)\n'
                                '• Testing account added as tester\n'
                                '• Product IDs match exactly\n'
                                '• Wait up to 24 hours after activation',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                              });
                              _initialize();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_products.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: height * 0.04),
                        ..._products
                            .where((p) => p.id != 'one_time_purchase')
                            .map((product) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Container(
                              height: height * 0.10,
                              width: width * 0.85,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 13, 13, 14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () => _buySubscription(product),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size >= 370000
                                                ? size * 0.000052
                                                : size * 0.000057,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        product.price,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: size >= 370000
                                              ? size * 0.000052
                                              : size * 0.000057,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        if (_oneTimePurchaseProduct != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: Container(
                              height: height * 0.10,
                              width: width * 0.85,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 13, 171, 24),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: _buyOneTimePurchaseProduct,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _oneTimePurchaseProduct!.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size >= 370000
                                                ? size * 0.000052
                                                : size * 0.000057,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _oneTimePurchaseProduct!.price,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: size >= 370000
                                              ? size * 0.000052
                                              : size * 0.000057,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'YOU CAN CANCEL YOUR SUBSCRIPTION OR FREE TRIAL AT ANY TIME BY CANCELING IT THROUGH YOUR GOOGLE ACCOUNT SETTING. OTHERWISE, IT WILL AUTOMATICALLY RENEW. CANCELLATION MUST BE DONE 24 HOURS BEFORE THE END OF THE CURRENT PERIOD.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}