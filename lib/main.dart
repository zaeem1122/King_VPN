import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/providers/ads_provider.dart';
import 'package:vpnprowithjava/providers/animation_provider.dart';
import 'package:vpnprowithjava/providers/appsProvider.dart';
import 'package:vpnprowithjava/providers/deviceDetailProvider.dart';
import 'package:vpnprowithjava/providers/servers_provider.dart';
import 'package:vpnprowithjava/providers/vpnProvider.dart';
import 'package:vpnprowithjava/providers/vpn_connection_provider.dart';
import 'package:vpnprowithjava/resources/prefs.dart';
import 'package:vpnprowithjava/screens/splashScreen.dart';

import 'https/vpnServerHttp.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.grey[900],
  ));
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await Prefs.init();
  await _requestNotificationPermission();

//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown
//   ]).then((_) {
//     runApp(
//       DevicePreview(
//         enabled: true, // Set to false in production
//         builder: (context) => MultiProvider(
//           providers: [
//             ChangeNotifierProvider(create: (_) => ServersProvider()),
//             ChangeNotifierProvider(create: (_) => DeviceDetailProvider()),
//             ChangeNotifierProvider(create: (_) => AppsProvider()),
//             ChangeNotifierProvider(create: (_) => VpnProvider()),
//             ChangeNotifierProvider(create: (_) => VpnConnectionProvider()),
//             ChangeNotifierProvider(create: (_) => CountProvider()),
//             ChangeNotifierProvider(create: (_) => AdsProvider()),
//           ],
//           child: const MyApp(),
//         ),
//       ),
//     );
//   });
// }
//
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => ServersProvider()),
      ChangeNotifierProvider(create: (_) => DeviceDetailProvider()),
      ChangeNotifierProvider(create: (_) => AppsProvider()),
      ChangeNotifierProvider(create: (_) => VpnProvider()),
      ChangeNotifierProvider(create: (_) => VpnConnectionProvider()),
      ChangeNotifierProvider(create: (_) => CountProvider()),
      ChangeNotifierProvider(create: (_) => AdsProvider()),
    ], child: const MyApp()));
  });
}

Future<bool> _requestNotificationPermission() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    status = await Permission.notification.request();
    if (status.isGranted) {
      return true;
    } else {
      Fluttertoast.showToast(
        msg: "Notification permission denied! VPN notifications may not appear.",
        backgroundColor: Colors.red,
      );
      return false;
    }
  }
  return true;
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      print("🏁 App opened → Calling VPN API now");
      //hhhh

      final vpnHttp = VpnServerHttp(context);
      await vpnHttp.getBestServer(context);
    });

    _initPurchaseListener();
  }

  void _initPurchaseListener() async {
    final InAppPurchase _inAppPurchase = InAppPurchase.instance;
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      log('InAppPurchase not available');
      return;
    }

    // Initialize the purchase stream listener
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
          (purchaseDetailsList) {
        _processPurchases(purchaseDetailsList);
      },
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) => log('Purchase stream error: $error'),
    );

    // Restore existing purchases
    await _inAppPurchase.restorePurchases();
  }

  void _processPurchases(List<PurchaseDetails> purchaseDetailsList) {
    bool hasActiveSubscription = false;

    for (final purchaseDetails in purchaseDetailsList) {
      // Handle purchase status
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        hasActiveSubscription = true;
        log('Valid purchase: ${purchaseDetails.productID}');
      }

      // Complete pending purchases
      if (purchaseDetails.pendingCompletePurchase) {
        InAppPurchase.instance.completePurchase(purchaseDetails);
      }
    }

    // Update subscription status based on all purchases
    final newStatus = hasActiveSubscription || _checkOtherSubscriptionConditions();
    Prefs.setBool('isSubscribed', newStatus);
    if (mounted) {
      Provider.of<AdsProvider>(context, listen: false).setSubscriptionStatus();
    }
  }

  bool _checkOtherSubscriptionConditions() {
    // Add custom logic here if needed
    return false;
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp( navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false, home: SplashScreen(),theme: ThemeData(
      dialogBackgroundColor: Colors.white
    ),);
  }
}