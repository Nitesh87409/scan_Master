# Firebase Remote Config Parameters Cheat Sheet

Firebase Console me **Engage -> Remote Config** me jaakar aapko ye saare parameters bananane hain. Niche di gayi list me exact "Parameter Key (Name)", uska "Data Type" (String/Boolean), aur "Default Value" di gayi hai.

> [!TIP]
> **Data Types yaad rakhein:** 
> - Jiske aage **[Boolean]** likha hai, wahan Firebase me `true` ya `false` select karna hai.
> - Jiske aage **[String]** likha hai, wahan koi text ya link dalna hai.

---

### 1. Feature Flags (On/Off Switches)
Aap kisi bhi feature ko yahan se turant disable kar sakte hain (agar usme koi bug aaye) bina naya APK banaye.

| Parameter Key | Data Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `ads_enabled` | **[Boolean]** | `false` | True karne par app me ads aane lagenge |
| `analytics_enabled` | **[Boolean]** | `true` | Usage tracking ON/OFF karne ke liye |
| `ocr_feature_enabled` | **[Boolean]** | `true` | Text extract feature ke liye |
| `qr_feature_enabled` | **[Boolean]** | `true` | QR Scanner feature ke liye |
| `signature_feature_enabled` | **[Boolean]** | `true` | Document sign feature ke liye |
| `vault_feature_enabled` | **[Boolean]** | `true` | Secure Vault feature ke liye |
| `compress_feature_enabled` | **[Boolean]** | `true` | PDF compress tool ke liye |
| `watermark_feature_enabled` | **[Boolean]** | `true` | Watermark tool ke liye |
| `export_images_enabled` | **[Boolean]** | `true` | PDF to Image tool ke liye |
| `export_text_enabled` | **[Boolean]** | `true` | PDF to Text tool ke liye |
| `protect_pdf_enabled` | **[Boolean]** | `true` | Protect PDF tool ke liye |

---

### 2. AdMob Ad IDs (Earning)
Live hone par, yahan apne real Google AdMob IDs daalein. (Isko set karne se aapki app ads show karegi).

| Parameter Key | Data Type | Default Value (Test IDs) |
| :--- | :--- | :--- |
| `admob_banner_android` | **[String]** | `ca-app-pub-3940256099942544/6300978111` |
| `admob_banner_ios` | **[String]** | `ca-app-pub-3940256099942544/2934735716` |
| `admob_interstitial_android` | **[String]** | `ca-app-pub-3940256099942544/1033173712` |
| `admob_interstitial_ios` | **[String]** | `ca-app-pub-3940256099942544/4411468910` |

---

### 3. Store Links (Ecosystem)
Ye links "Rate Us" aur "More Apps" me use hote hain. Ye dynamically auto-detect karke Play Store ya Amazon par redirect karenge.

| Parameter Key | Data Type | Default Value |
| :--- | :--- | :--- |
| `developer_name` | **[String]** | `Nitesh` |
| `play_store_url` | **[String]** | `https://play.google.com/store/apps/details?id=com.scanmaster.scan_master_app` |
| `amazon_store_url` | **[String]** | `https://www.amazon.com/gp/mas/dl/android?p=com.scanmaster.scan_master_app` |
| `play_store_developer_page` | **[String]** | `https://play.google.com/store/apps/developer?id=Nitesh` |
| `amazon_developer_page` | **[String]** | `https://www.amazon.com/s?rh=p_4:Nitesh` |

---

### 4. Update System (In-App Update)
Ye system Play Store ke bahar se download kiye gaye users (jaise Amazon ya APK users) ko force update dikhane me madad karta hai.

| Parameter Key | Data Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `latest_app_version` | **[String]** | `1.0.0` | Yahan latest version daalein (e.g. `1.5.32`) |
| `update_url` | **[String]** | `https://play.google.com/store/apps/details?id=com.scanmaster...` | Jahan se naya version download karna hai |
| `force_update_required` | **[Boolean]** | `false` | True karne par purana app khulna band ho jayega |

---

### 5. Announcements / Promo Banner
Agar aapko apne users ko koi naya app (e.g., Dimmer Pro) promote karna ho, ya koi notice dena ho toh ye feature use karein. (Abhi backend ready hai, UI me implement karna baaki hai agar aap chahein toh).

| Parameter Key | Data Type | Default Value | Description |
| :--- | :--- | :--- | :--- |
| `show_announcement` | **[Boolean]** | `false` | True karne par notice dikhega |
| `announcement_title` | **[String]** | `""` (Khali chhod dein) | Notice ka title (e.g., *Try Dimmer Pro!*) |
| `announcement_message` | **[String]** | `""` (Khali chhod dein) | Notice ki detail |
| `announcement_action_url` | **[String]** | `""` (Khali chhod dein) | Button par click karne par kahan bhejna hai |

---

### 6. Maintenance Mode
Agar kabhi app ka koi server ya feature crash ho jaye, toh ise On karein. User ko app ke andar maintenance screen dikhegi.

| Parameter Key | Data Type | Default Value |
| :--- | :--- | :--- |
| `maintenance_mode` | **[Boolean]** | `false` |
| `maintenance_message` | **[String]** | `App is under maintenance. Please try again later.` |

---

### 7. Privacy & Legal
| Parameter Key | Data Type | Default Value |
| :--- | :--- | :--- |
| `privacy_policy_url` | **[String]** | `https://docs.google.com/document/d/1GhSOcrpymsv1XZvCXgzW1YQWlrrCpNiBy2dc2eBW8hU/edit?usp=sharing` |
| `terms_of_service_url` | **[String]** | `""` (Khali chhod dein) |

> **Pro Tip:** Inme se jo parameters abhi khali string `""` hain, unko aap chhod bhi sakte hain, par baki saare Remote Config me bana lene chahiye taaki app perfectly "smart" rahe!
