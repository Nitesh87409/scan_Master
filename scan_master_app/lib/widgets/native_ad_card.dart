import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:scan_master_app/core/app_config.dart';
import 'package:scan_master_app/services/ad_service.dart';

class NativeAdCardWidget extends StatefulWidget {
  final Color baseColor;
  final VoidCallback? onFailed;

  const NativeAdCardWidget({super.key, this.baseColor = Colors.deepPurple, this.onFailed});

  @override
  State<NativeAdCardWidget> createState() => _NativeAdCardWidgetState();
}

class _NativeAdCardWidgetState extends State<NativeAdCardWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    if (!AppConfig.adsEnabled || !AppConfig.adsHomeNativeEnabled) return;

    await AdService.waitForInit;
    if (!mounted) return;

    _nativeAd = NativeAd(
      adUnitId: Platform.isAndroid ? AppConfig.admobNativeAndroid : AppConfig.admobNativeIos,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native Ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isFailed = true;
            });
            widget.onFailed?.call();
          }
        },
      ),
      factoryId: 'GridAdFactory',
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.adsEnabled || !AppConfig.adsHomeNativeEnabled || _isFailed) {
      return const SizedBox();
    }

    // Wrap the NativeAd in a container to add shadow matching other cards
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _isLoaded && _nativeAd != null
          ? AdWidget(ad: _nativeAd!)
          : Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.grey,
                  strokeWidth: 2,
                ),
              ),
            ),
    );
  }
}
