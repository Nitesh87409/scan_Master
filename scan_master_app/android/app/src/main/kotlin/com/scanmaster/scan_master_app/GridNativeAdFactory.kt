package com.scanmaster.scan_master_app

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class GridNativeAdFactory(private val context: Context) : NativeAdFactory {

    override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.grid_native_ad, null) as NativeAdView

        with(nativeAdView) {
            val attributionViewSmall = findViewById<TextView>(R.id.ad_attribution)
            val iconView = findViewById<ImageView>(R.id.ad_app_icon)
            val headlineView = findViewById<TextView>(R.id.ad_headline)
            val buttonView = findViewById<Button>(R.id.ad_call_to_action)

            this.iconView = iconView
            this.headlineView = headlineView
            this.callToActionView = buttonView

            // Populate the views with ad data
            nativeAd.icon?.let {
                iconView.setImageDrawable(it.drawable)
                iconView.visibility = View.VISIBLE
            } ?: run {
                iconView.visibility = View.INVISIBLE
            }

            headlineView.text = nativeAd.headline

            nativeAd.callToAction?.let {
                buttonView.text = it
                buttonView.visibility = View.VISIBLE
            } ?: run {
                buttonView.visibility = View.INVISIBLE
            }

            attributionViewSmall.visibility = View.VISIBLE

            setNativeAd(nativeAd)
        }

        return nativeAdView
    }
}
