import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:scan_master_app/core/app_config.dart';

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

  void _loadAd() {
    if (!AppConfig.adsEnabled || !AppConfig.adsHomeNativeEnabled) return;

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
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: widget.baseColor.withOpacity(0.9),
        cornerRadius: 20.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: widget.baseColor.withOpacity(0.8),
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
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

    // Wrap the NativeAd in a container styled like the other cards
    return Container(
      width: double.infinity,
      // Fixed min height to match the approximate height of _buildActionCard
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.baseColor.withOpacity(0.8), widget.baseColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.baseColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _isLoaded && _nativeAd != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AdWidget(ad: _nativeAd!),
            )
          : Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white.withAlpha(128),
                  strokeWidth: 2,
                ),
              ),
            ),
    );
  }
}
