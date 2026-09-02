import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:scan_master_app/core/app_config.dart';

class AdService {
  static InterstitialAd? _protectInterstitialAd;
  static bool _isProtectInterstitialAdLoaded = false;

  static bool get adsEnabled => AppConfig.adsEnabled;

  static Future<void> initialize() async {
    if (!adsEnabled) return;
    await MobileAds.instance.initialize();
    _loadProtectInterstitialAd();
  }

  // Old interstitial ad logic removed

  static void _loadProtectInterstitialAd() {
    if (!adsEnabled || !AppConfig.adsProtectInterstitialEnabled) return;
    InterstitialAd.load(
      adUnitId: Platform.isAndroid 
          ? AppConfig.admobProtectInterstitialAndroid
          : AppConfig.admobProtectInterstitialIos,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _protectInterstitialAd = ad;
          _isProtectInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load protect interstitial ad: ${err.message}');
          _isProtectInterstitialAdLoaded = false;
        },
      ),
    );
  }

  // showInterstitialAd removed

  static void showProtectInterstitialAd({VoidCallback? onAdClosed}) {
    if (!adsEnabled || !AppConfig.adsProtectInterstitialEnabled || !_isProtectInterstitialAdLoaded || _protectInterstitialAd == null) {
      onAdClosed?.call();
      return;
    }
    _protectInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isProtectInterstitialAdLoaded = false;
        onAdClosed?.call();
        _loadProtectInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _isProtectInterstitialAdLoaded = false;
        onAdClosed?.call();
        _loadProtectInterstitialAd();
      },
    );
    _protectInterstitialAd!.show();
  }
}
