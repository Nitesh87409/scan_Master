import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:scan_master_app/core/app_config.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoaded = false;
  static bool get adsEnabled => AppConfig.adsEnabled;

  static Future<void> initialize() async {
    if (!adsEnabled) return;
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  static void _loadInterstitialAd() {
    if (!adsEnabled) return;
    InterstitialAd.load(
      adUnitId: Platform.isAndroid 
          ? AppConfig.admobInterstitialAndroid
          : AppConfig.admobInterstitialIos,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
              _loadInterstitialAd(); // Reload for next time
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _isInterstitialAdLoaded = false;
            },
          );
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (!adsEnabled) return;
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    }
  }
}

class BannerAdWidget extends StatefulWidget {
  final bool? isEnabled;
  
  const BannerAdWidget({super.key, this.isEnabled});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final shouldShow = widget.isEnabled ?? AdService.adsEnabled;
    if (!shouldShow || !AdService.adsEnabled) return;
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid 
          ? AppConfig.admobBannerAndroid
          : AppConfig.admobBannerIos,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = widget.isEnabled ?? AdService.adsEnabled;
    if (!shouldShow || !AdService.adsEnabled) return SizedBox.shrink();
    if (_isLoaded && _bannerAd != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      );
    }
    return SizedBox(height: 50); // Ad space placeholder
  }
}
