import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../providers/ads_provider.dart';
import '../resources/prefs.dart';

class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({Key? key}) : super(key: key);
  @override
  _RemoveAdsScreenState createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  ProductDetails? _oneTimePurchaseProduct;
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _addDebugLog('initState called');

    // Set up purchase stream FIRST
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _addDebugLog('Purchase update received: ${purchaseDetailsList.length} items');
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _addDebugLog('Purchase stream done');
      _subscription.cancel();
    }, onError: (error) {
      _addDebugLog('Purchase stream error: $error');
      debugPrint('Purchase stream error: $error');
    });

    _initialize();
  }

  void _addDebugLog(String log) {
    setState(() {
      _debugLogs.add('${DateTime.now().toString().split(' ')[1].substring(0, 8)}: $log');
    });
    debugPrint('IAP_DEBUG: $log');
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _addDebugLog('Starting initialization...');

      final bool available = await _inAppPurchase.isAvailable();
      _addDebugLog('IAP available: $available');

      if (!available) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'In-app purchases are not available.\n\nMake sure:\n1. You are using a release build\n2. App is uploaded to Play Console\n3. Products are active';
        });
        return;
      }

      // Restore previous purchases
      try {
        _addDebugLog('Restoring purchases...');
        await _inAppPurchase.restorePurchases();
        _addDebugLog('Purchases restored');
      } catch (e) {
        _addDebugLog('Error restoring purchases: $e');
      }

      // Query products with timeout
      _addDebugLog('Querying products...');

      final Set<String> kIds = {
        'kingvpn_999_1m',
        'kingvpn_999_1year',
        'one_time_purchase',
      };

      // Add timeout to prevent hanging
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(kIds)
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _addDebugLog('Product query TIMEOUT after 15 seconds');
          throw TimeoutException('Product query timed out');
        },
      );

      _addDebugLog('Query completed');

      if (response.error != null) {
        _addDebugLog('Product query error: ${response.error!.code} - ${response.error!.message}');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${response.error!.message}\n\nCheck:\n1. Product IDs are correct\n2. Products are active in Play Console\n3. App is published to testing track';
        });
        return;
      }

      _addDebugLog('Products found: ${response.productDetails.length}');
      _addDebugLog('Not found: ${response.notFoundIDs.join(", ")}');

      if (response.productDetails.isEmpty) {
        _addDebugLog('NO PRODUCTS FOUND!');
        setState(() {
          _isLoading = false;
          _errorMessage = 'No products found!\n\nMissing IDs: ${response.notFoundIDs.join(", ")}\n\nSteps:\n1. Check product IDs in Play Console\n2. Ensure products are ACTIVE\n3. App must be in testing track\n4. Wait 2-3 hours after creating products';
        });
        return;
      }

      // Log each product found
      for (var product in response.productDetails) {
        _addDebugLog('✓ ${product.id}: ${product.title} - ${product.price}');
      }

      setState(() {
        _products = response.productDetails;

        // Find one-time purchase
        try {
          _oneTimePurchaseProduct = _products.firstWhere(
                (product) => product.id == 'one_time_purchase',
          );
          _addDebugLog('One-time purchase found');
        } catch (e) {
          _addDebugLog('One-time purchase NOT found in results');
          _oneTimePurchaseProduct = null;
        }
        _isLoading = false;
      });

      _addDebugLog('✓ Initialization SUCCESS!');
    } on TimeoutException catch (e) {
      _addDebugLog('TIMEOUT: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection timeout!\n\nThe Play Store is not responding.\n\nTry:\n1. Check internet connection\n2. Restart device\n3. Clear Play Store cache\n4. Use release build';
      });
    } catch (e) {
      _addDebugLog('ERROR: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Initialization failed: $e\n\nMake sure you are testing with a RELEASE build, not debug.';
      });
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    _addDebugLog('Purchase status: ${purchaseDetails.status}');

    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      _addDebugLog('✓ Purchase successful');
      await Prefs.setBool('isSubscribed', true);
      if (mounted) {
        Provider.of<AdsProvider>(context, listen: false).setSubscriptionStatus();
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        _addDebugLog('Purchase completed');
      }

      if (mounted) {
        _showDialog('Success', 'Purchase completed successfully!');
      }
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      _addDebugLog('✗ Purchase error: ${purchaseDetails.error?.message}');
      await Prefs.setBool('isSubscribed', false);
      if (mounted) {
        _showDialog('Error', 'Purchase failed: ${purchaseDetails.error?.message ?? "Unknown error"}');
      }
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      _addDebugLog('Purchase canceled by user');
      if (mounted) {
        _showDialog('Canceled', 'Purchase was canceled.');
      }
    } else if (purchaseDetails.status == PurchaseStatus.pending) {
      _addDebugLog('Purchase pending...');
    }

    if (purchaseDetails.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  void _buySubscription(ProductDetails product) {
    _addDebugLog('Buy clicked: ${product.id}');
    if (Prefs.getBool('isSubscribed') ?? false) {
      _showDialog('Info', 'You already have an active subscription.');
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    // Check if it's actually a subscription or non-consumable
    if (product.id.contains('1m') || product.id.contains('1year')) {
      // These look like subscriptions - use buyNonConsumable for non-subscription in-app products
      // If they're actual subscriptions in Play Console, this might be the issue
      _addDebugLog('Initiating purchase for: ${product.id}');
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  void _buyOneTimePurchaseProduct() {
    if (_oneTimePurchaseProduct == null) {
      _showDialog('Error', 'One-time purchase product not available.');
      return;
    }
    _addDebugLog('Buy one-time purchase');
    if (Prefs.getBool('isSubscribed') ?? false) {
      _showDialog('Info', 'You already have an active subscription.');
      return;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: _oneTimePurchaseProduct!);
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

  void _showDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _debugLogs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _debugLogs[index],
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copy logs to clipboard would be nice here
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = height * width;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 20),
              const Text('Loading products...', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 40),
              TextButton.icon(
                onPressed: _showDebugLogs,
                icon: const Icon(Icons.bug_report, color: Colors.white70),
                label: const Text('Show Debug Logs', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.white),
              onPressed: _showDebugLogs,
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                      _debugLogs.clear();
                    });
                    _initialize();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _showDebugLogs,
                  icon: const Icon(Icons.bug_report, color: Colors.white70),
                  label: const Text('View Debug Logs', style: TextStyle(color: Colors.white70)),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Get Premium Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bug_report, color: Colors.white54, size: 20),
                      onPressed: _showDebugLogs,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: height * 0.05),
                      // Subscription products
                      ..._products
                          .where((product) => product.id != 'one_time_purchase')
                          .map((product) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          child: Container(
                            height: height * 0.10,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 13, 13, 14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: InkWell(
                              onTap: () => _buySubscription(product),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.title.split('(')[0].trim(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: size >= 370000 ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      product.price,
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: size >= 370000 ? 20 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      // One-time purchase
                      if (_oneTimePurchaseProduct != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Container(
                            height: height * 0.10,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0DA318), Color(0xFF0A8014)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: _buyOneTimePurchaseProduct,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _oneTimePurchaseProduct!.title.split('(')[0].trim(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: size >= 370000 ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _oneTimePurchaseProduct!.price,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: size >= 370000 ? 20 : 18,
                                        fontWeight: FontWeight.bold,
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
                          'YOU CAN CANCEL YOUR SUBSCRIPTION OR FREE TRIAL AT ANY TIME BY CANCELING IT THROUGH YOUR GOOGLE ACCOUNT SETTINGS. OTHERWISE, IT WILL AUTOMATICALLY RENEW. CANCELLATION MUST BE DONE 24 HOURS BEFORE THE END OF THE CURRENT PERIOD.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            height: 1.4,
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