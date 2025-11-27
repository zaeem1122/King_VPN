// import 'package:flutter/cupertino.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// import '../resources/prefs.dart';
//
// class AdsProvider with ChangeNotifier {
//   BannerAd? _bannerAd;
//   InterstitialAd? _interstitialAd;
//   bool _isAdLoaded = false;
//   bool _isSubscribed = Prefs.getBool('isSubscribed') ?? false;
//
//   AdsProvider() {
//     loadAds();
//     loadInterstitialAd();
//   }
//   Future<void> loadAds() async {
//     _bannerAd = BannerAd(
//       adUnitId: 'ca-app-pub-4826348586303925/7714245939',
//       size: AdSize.banner,
//       request: AdRequest(),
//       listener: BannerAdListener(
//         onAdLoaded: (_) {
//           _isAdLoaded = true;
//           notifyListeners();
//         },
//         onAdFailedToLoad: (ad, error) {
//           ad.dispose();
//           print('Ad load failed (code=${error.code} message=${error.message})');
//         },
//       ),
//     );
//     await _bannerAd?.load();
//   }
//
//   BannerAd? getBannerAd() {
//     if (_bannerAd != null && _isAdLoaded && !_isSubscribed) {
//       return _bannerAd;
//     }
//     return null;
//   }
//
//   Future<void> loadInterstitialAd() async {
//     final adUnitId = 'ca-app-pub-4826348586303925/4530313850';
//     final adRequest = AdRequest();
//     InterstitialAd.load(
//       adUnitId: adUnitId,
//       request: adRequest,
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) {
//           _interstitialAd = ad;
//           notifyListeners();
//         },
//         onAdFailedToLoad: (error) {
//           print('InterstitialAd failed to load: $error');
//         },
//       ),
//     );
//   }
//
//   void showInterstitialAd() {
//     if (_interstitialAd != null && !_isSubscribed) {
//       _interstitialAd!.show();
//     }
//   }
//
//   void setSubscriptionStatus() {
//     var isSubscribed = Prefs.getBool('isSubscribed') ?? false;
//     _isSubscribed = isSubscribed;
//     notifyListeners();
//   }
// }


import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../resources/prefs.dart';

class AdsProvider with ChangeNotifier {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoading = false;
  bool _isSubscribed = Prefs.getBool('isSubscribed') ?? false;
  int _bannerRetryCount = 0;

  bool get isSubscribed => _isSubscribed;

  Future<void> loadAds() async {
    if (_isSubscribed || _isBannerLoading || _bannerAd != null) return;
    _isBannerLoading = true;

    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-4826348586303925/8956470606'
        : 'ca-app-pub-4826348586303925/8956470606';

// final adUnitId = Platform.isAndroid
//         ? 'ca-app-pub-3940256099942544/9214589741'
//         : 'ca-app-pub-4826348586303925/7714245939';
    try {
      _bannerAd?.dispose();
      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            _bannerRetryCount = 0;
            _isBannerLoading = false;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _bannerAd = null;
            _isBannerLoading = false;
            notifyListeners();

            // Exponential backoff retry
            if (_bannerRetryCount < 3) {
              _bannerRetryCount++;
              Future.delayed(Duration(seconds: 1 << _bannerRetryCount), loadAds);
            }
          },
        ),
      );
      await _bannerAd?.load();
    } catch (e) {
      _isBannerLoading = false;
      print('Banner load error: $e');
    }
  }

  BannerAd? getBannerAd() {
    return (!_isSubscribed && _bannerAd != null) ? _bannerAd : null;
  }

  Future<void> loadInterstitialAd() async {
    if (_isSubscribed) return;

    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-4826348586303925/5659953920'
        : 'ca-app-pub-4826348586303925/5659953920';

    try {
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (error) {
            print('Interstitial failed: $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      print('Interstitial load error: $e');
    }
  }

  void showInterstitialAd() {
    if (_isSubscribed || _interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
  }

  void disposeAds() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }

  void setSubscriptionStatus() {
    var isSubscribed = Prefs.getBool('isSubscribed') ?? false;
    _isSubscribed = isSubscribed;
    notifyListeners();
  }
}

