import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../providers/ads_provider.dart';
import '../resources/prefs.dart';
import 'package:onepref/onepref.dart';

class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({Key? key}) : super(key: key);
  @override
  _RemoveAdsScreenState createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = <ProductDetails>[];
  ProductDetails? _oneTimePurchaseProduct;
  bool _isLoading = true;
  String? _errorMessage;

  final Set<String> _kIds = {
    'kingvpn_999_1m',
    'kingvpn_999_1year',
    'one_time_purchase',
  };

  @override
  void initState() {
    super.initState();

    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Handle error silently
    });

    _initialize();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final bool available = await _inAppPurchase.isAvailable();

      if (!available) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'In-app purchases are not available.\n\nMake sure:\n1. You are using a release/appbundle build\n2. App is uploaded to Play Console\n3. Products are active/published';
        });
        return;
      }

      try {
        await _inAppPurchase.restorePurchases();
      } catch (e) {
        // Handle error silently
      }

      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(_kIds)
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Product query timed out');
        },
      );

      if (response.error != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${response.error!.message}\n\nCheck:\n1. Product IDs are correct\n2. Products are active in Play Console\n3. App is published to testing track';
        });
        return;
      }

      if (response.productDetails.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No products found!\n\nMissing IDs: ${response.notFoundIDs.join(", ")}';
        });
        return;
      }

      setState(() {
        _products = response.productDetails;
        try {
          _oneTimePurchaseProduct = _products.firstWhere(
                (product) => product.id == 'one_time_purchase',
          );
        } catch (e) {
          _oneTimePurchaseProduct = null;
        }
        _isLoading = false;
      });
    } on TimeoutException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection timeout!\n\nThe Play Store is not responding.';
      });
    } catch (e) {
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
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      await Prefs.setBool('isSubscribed', true);
      if (mounted) {
        Provider.of<AdsProvider>(context, listen: false).setSubscriptionStatus();
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }

      if (mounted) {
        _showDialog('Success', 'Purchase completed successfully!');
      }
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      await Prefs.setBool('isSubscribed', false);
      if (mounted) {
        _showDialog('Error', 'Purchase failed: ${purchaseDetails.error?.message ?? "Unknown error"}');
      }
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      if (mounted) {
        _showDialog('Canceled', 'Purchase was canceled.');
      }
    }
  }

  void _buySubscription(ProductDetails product) {
    if (Prefs.getBool('isSubscribed') ?? false) {
      _showDialog('Info', 'You already have an active subscription.');
      return;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _buyOneTimePurchaseProduct() {
    if (_oneTimePurchaseProduct == null) {
      _showDialog('Error', 'One-time purchase product not available.');
      return;
    }
    if (Prefs.getBool('isSubscribed') ?? false) {
      _showDialog('Info', 'You already have an active subscription.');
      return;
    }
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: _oneTimePurchaseProduct!);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _showDialog(String title, String message) {
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    // Responsive values
    final isSmallScreen = height < 600;
    final isMediumScreen = height >= 600 && height < 800;

    final topSpacing = isSmallScreen ? height * 0.02 : height * 0.05;
    final itemHeight = isSmallScreen ? 70.0 : (isMediumScreen ? 80.0 : height * 0.10);
    final bottomSpacing = isSmallScreen ? height * 0.02 : height * 0.05;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 20),
              Text('Loading products...', style: TextStyle(color: Colors.white)),
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
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: isSmallScreen ? 50 : 60,
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 12 : 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initialize();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.08,
                      vertical: 15,
                    ),
                  ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.025,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Get Premium Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: topSpacing),
                      // Subscription products
                      ..._products
                          .where((product) => product.id != 'one_time_purchase')
                          .map((product) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.05,
                            vertical: 5,
                          ),
                          child: Container(
                            height: itemHeight,
                            constraints: BoxConstraints(
                              minHeight: 70,
                              maxHeight: isSmallScreen ? 80 : 100,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 13, 13, 14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: InkWell(
                              onTap: () => _buySubscription(product),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.05,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.title.split('(')[0].trim(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Text(
                                      product.price,
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      SizedBox(height: height * 0.01),

                      // ONE-TIME PURCHASE SECTION
                      if (_oneTimePurchaseProduct != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.05,
                          ),
                          child: Container(
                            height: itemHeight,
                            constraints: BoxConstraints(
                              minHeight: 70,
                              maxHeight: isSmallScreen ? 80 : 100,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 13, 13, 14),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.withOpacity(0.5)),
                            ),
                            child: InkWell(
                              onTap: _buyOneTimePurchaseProduct,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.05,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Remove Ads Permanently',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 13 : 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    Text(
                                      _oneTimePurchaseProduct!.price,
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: width * 0.02),
                                    const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: bottomSpacing),
                      TextButton(
                        onPressed: () => _inAppPurchase.restorePurchases(),
                        child: const Text(
                          'Restore Purchases',
                          style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 15 : 20),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                        child: Text(
                          'YOU CAN CANCEL YOUR SUBSCRIPTION OR FREE TRIAL AT ANY TIME BY CANCELING IT THROUGH YOUR GOOGLE ACCOUNT SETTING. OTHERWISE, IT WILL AUTOMATICALLY RENEW. CANCELLATION MUST BE DONE 24 HOURS BEFORE THE END OF THE CURRENT PERIOD.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isSmallScreen ? 9 : 10,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 20),
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