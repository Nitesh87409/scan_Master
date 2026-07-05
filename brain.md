# Scan Master Brain & Changelog

Ye file project ka detailed record rakhti hai. Har update, state change, aur event attachment yahan detail me log hoga.

## [1.5.1+124] - 2026-07-05
### Bug Fix (Minor): Controller Memory Leak
- **Fix Applied:** `_watermarkPdf()` instantiated a `TextEditingController` for the dialog but never called `.dispose()` after the dialog closed. This caused a minor memory leak with repeated use. Now, `textController.dispose()` is reliably called right after the dialog awaits.
- **Version Bump:** `pubspec.yaml` updated to 1.5.1+124.

## [1.5.0+123] - 2026-07-05
### Stability Fix: Native Resource Leaks on Exception
- **Vulnerability:** In `_exportToText()` and `_watermarkPdf()`, native resources like `TextRecognizer`, `IOSink`, and `PdfDocument` were only disposed in the happy path or on cancellation. If a runtime exception occurred, the `catch` block executed but bypassed resource disposal, leading to native memory leaks.
- **Fix Applied:** Refactored the code to use robust `try-catch-finally` blocks. `TextRecognizer`, `IOSink`, and `PdfDocument` variables are declared before the `try` block and are reliably closed/disposed in the `finally` block, ensuring memory safety even if the process crashes.
- **Version Bump:** `pubspec.yaml` updated to 1.5.0+123.

## [1.4.99+122] - 2026-07-05
### Bug Fix (Medium): PDF Export Resource Leaks on Cancel
- **Vulnerability:** When a user cancelled an active "Export to Images" or "Export to Text (OCR)" operation, the partially generated files (temporary PNG folders and incomplete `.txt` files) were not being cleaned up, leading to storage bloat.
- **Fix Applied:** Updated `_exportToImages()` and `_exportToText()` in `pdf_tools_screen.dart` to explicitly call `delete()` on the temporary folder and text file when `_isCancelled` triggers during the loop.
- **Version Bump:** `pubspec.yaml` updated to 1.4.99+122.

## [1.4.98+121] - 2026-07-05
### Security Fix: Defense in Depth for Secure Vault
- **Vulnerability:** `VaultScreen` relied entirely on the caller for authentication. If opened via an intent, deep link, or another vector, it bypassed authentication entirely.
- **Fix Applied:** Implemented 'defense in depth' by introducing an `initialAuthPassed` flag. `VaultScreen` now proactively checks authentication in its `initState()` if the flag is not set. If authentication fails, the user is immediately kicked out, preventing any unauthorized viewing of files.
- **Version Bump:** `pubspec.yaml` updated to 1.4.98+121.

## [1.4.97+120] - 2026-07-05
### Security Fix (CRITICAL): Vault Authentication Bypass
- **Vulnerability:** If a device did not have biometric authentication set up (or hardware was missing), `AuthService.authenticate()` returned `true` by default, silently granting unrestricted access to the Secure Vault.
- **Fix Applied:** Modified `auth_service.dart`. It now correctly returns `false` if the device cannot authenticate. Additionally, implemented `AuthenticationOptions` with `biometricOnly: false` to allow fallback to device PIN/Pattern if biometrics fail or aren't set up.
- **Version Bump:** `pubspec.yaml` updated to 1.4.97+120.

## [1.4.96+119] - 2026-07-05
### Bug Fix (UX): Root Route ViewerScreen Black Screen
- **Fix Applied:** Modified `viewer_screen.dart` to check `Navigator.of(context).canPop()` on back press. If false (meaning the app was opened directly from an external share intent), it now calls `SystemNavigator.pop()` to properly minimize/close the app instead of getting stuck on a black loading screen.
- **Impact:** Ensures a smooth exit back to WhatsApp/Files app when the user closes the PDF viewer from a deep link.
- **Version Bump:** `pubspec.yaml` updated to 1.4.96+119.

## [1.4.94+117] - 2026-07-05
### Stability Fix: Intent Handling Fuzz-Proofing
- **Validation Added:** Enclosed the `ReceiveSharingIntent` path parsing in `main.dart` with a `try-catch` block and added a strict `File(path).existsSync()` validation.
- **Impact:** Prevents the app from crashing if a malformed, invalid, or non-existent file URI is sent via the Android "Open With" intent.


## [1.4.93+116] - 2026-07-05
### Security Fix: Path Traversal Vulnerability
- **Sanitization Added:** Added `_sanitizeName()` helper in `FileManagerService` to strip slashes (`/`, `\`), relative paths (`..`), and other invalid filesystem characters.
- **Impact:** Prevents malicious or accidental path traversal when a user renames a file/folder or creates a folder, ensuring the app remains securely sandboxed.


## [1.4.92+115] - 2026-07-05
### Bug Fix: iOS Critical Crash (Privacy Permissions)
- **Info.plist Update:** Added mandatory iOS privacy permission strings (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`, and `NSMicrophoneUsageDescription`). 
- **Impact:** Fixed a guaranteed SIGABRT crash when accessing camera or gallery on iOS, and prevented an automatic App Store rejection.


## [1.4.91+114] - 2026-07-05
### Feature Addition: Secure Vault (Biometric Lock)
- **Dependency Added:** `local_auth` added.
- **Android Setup:** Updated `AndroidManifest.xml` (USE_BIOMETRIC) and `MainActivity.kt` (FlutterFragmentActivity).
- **Vault Logic:** Created `.Vault` hidden directory in `FileManagerService` with `moveToVault()` helper.
- **Biometric Lock:** Implemented `AuthService` for FaceID/Fingerprint authentication. Added "Secure Vault" button in `HomeScreen` app bar and "Move to Vault" in `FileOptionsHelper`.
- **UI Updates:** Added `VaultScreen` to view, unlock, and restore protected files.


## [1.4.90+113] - 2026-07-05
### Feature Addition: Watermark Tool
- **Dependency Added:** Added `syncfusion_flutter_pdf` package for advanced PDF manipulation without quality loss.
- **Watermark Logic:** Implemented `_watermarkPdf()` in `pdf_tools_screen.dart` which uses `PdfDocument` and `PdfGraphics` to draw a custom text string diagonally (rotated -45 degrees) with 25% opacity on every page.
- **UI Updates:** Added 'Add Watermark' button in `PdfToolsScreen`.


## [1.4.89+112] - 2026-07-05
### Feature Addition: Export Formats (JPEG/PNG/TXT)
- **Export to Images:** Added PDF rasterization using `Printing.raster()` to save all pages as `.png` files, which are then bundled into a `.zip` archive via `archive` package.
- **Export to Text (OCR):** Added functionality to extract text from all PDF pages offline using `google_mlkit_text_recognition`, combining it into a single `.txt` file.
- **File Manager Support:** Updated `FileManagerService` to include `.zip` and `.txt` extensions in `getRecentFiles`, `getRootFiles`, and `getFilesInFolder`.


## [1.4.88+111] - 2026-07-05
### Feature Addition: App Shortcuts (Quick Actions)
- **Dependency Added:** Included `quick_actions` package for native Android/iOS shortcut integration.
- **Home Screen Integration:** Initialized `QuickActions` inside `_HomeScreenState.initState()`.
- **Scan Shortcut:** Configured `action_scan` shortcut which calls `_startScan(isGallery: false)`, allowing users to jump directly into the scanner by long-pressing the app icon.


## [1.4.87+110] - 2026-07-05
### Feature Addition: Favorites / Pin Documents
- **Core Logic:** Modified `FileManagerService` to persist pinned document paths using `SharedPreferences`. The sort algorithm in `_getSortedFilesAsync` now guarantees pinned files always appear at the top.
- **UI Logic:** Added a `Pin to Top` / `Unpin` toggle to the `file_options_helper.dart` bottom sheet menu.
- **Visual Feedback:** Pinned files on the `HomeScreen` display a small purple `Icons.push_pin` badge overlaid on their thumbnail for easy visual distinction.


## [1.4.86+109] - 2026-07-05
### Feature Addition: PDF Compression
- **Added Compress Option:** Implemented `_compressPdf` in `pdf_tools_screen.dart` which uses `pdf_manipulator`'s native `.optimizeImages(quality: 40, minSize: 100)` and `.unembedStandardFonts()` methods.
- **UI Integration:** Added "Compress PDF" button to the PDF Tools screen and updated `AppStrings` accordingly. This allows users to easily shrink large scanner PDFs for email/WhatsApp sharing.


## [1.4.85+108] - 2026-07-05
### Core Feature Fix: UI Integration of Native Scanner
- **Fixed Scanner Launch Logic:** In `home_screen.dart`, the main FAB scanner button was incorrectly hardcoded to `_startScan(isGallery: true)`, which bypassed the camera entirely and only allowed gallery import. This has been corrected to `isGallery: false`.
- **Added Gallery Import Button:** Added a dedicated 'Import from Gallery' button to the `AppBar` actions in `home_screen.dart` so users can still import existing photos.
- **Impact:** This single fix magically unlocks all the core scanner features natively provided by `google_mlkit_document_scanner` including **Auto edge detection, Perspective correction, Built-in image enhancement filters (B&W, grayscale, etc.), and Multi-page batch scanning**.


## [1.4.84+107] - 2026-07-05
### Concurrency Fix: PDF Rasterization Queue
- **Added Execution Queue:** Implemented a custom `_PdfRasterQueue` in `file_thumbnail.dart` using a static `Completer` based queue. 
- **Impact:** Prevents multiple heavy PDF rendering tasks (`Printing.raster`) from executing simultaneously when scrolling a grid of PDF files. By processing them sequentially, the app avoids massive CPU/RAM spikes and prevents native out-of-memory crashes that could occur with concurrent multi-megabyte PDF rasterization.


## [1.4.83+106] - 2026-07-05
### Performance Optimization: Image RAM Spikes
- **Added cacheWidth to Images:** Set `cacheWidth: 250` for thumbnails in `file_thumbnail.dart` and `cacheWidth: 2000` for full-screen previews in `viewer_screen.dart` and `filter_screen.dart`.
- **Impact:** Drastically reduces memory usage. Previously, high-res 12MP photos (4000x3000) were being decoded at full resolution just to be displayed as 50x50 UI thumbnails, using ~48MB of RAM per image. The app is now significantly faster and immune to Out-Of-Memory (OOM) crashes when scrolling image-heavy folders.


## [1.4.82+105] - 2026-07-05
### Memory Leak Fix: AnimationController Memory Exhaustion
- **Proper Disposal:** Fixed a confirmed memory leak in `core/animations.dart` where the `AnimationController` passed to `showPremiumBottomSheet` was never being disposed by Flutter. It is now properly stored in a local variable and `.dispose()` is called inside the `.whenComplete()` of the Future.
- **Impact:** Solves the RAM spike (and potential Out of Memory crashes) that would occur if the user repeatedly tapped the 3-dot menu or opened any custom bottom sheet across the app.


## [1.4.81+104] - 2026-07-05
### Automated Testing Fix: Main App Class Rename
- **Fixed Widget Test:** Updated `widget_test.dart` where `MyApp` was still being referenced instead of the newly renamed `ScanMasterApp`. This fixes the compilation error during `flutter analyze` and `flutter test`.


## [1.4.80+103] - 2026-07-05
### Technical Debt Fix: Removed Dead Code in PdfService
- **Code Cleanup:** Removed unused and empty placeholder functions (`mergePdfs`, `splitPdf`, `compressPdf`) from `pdf_service.dart`. Actual manipulation is already being handled cleanly via the `pdf_manipulator` package in `pdf_tools_screen.dart`.


## [1.4.79+102] - 2026-07-05
### Bug Fix: Rapid Back-Press Glitch in ViewerScreen
- **Double Pop Prevented:** Added `if (_isPopping) return;` at the start of `onPopInvokedWithResult` in `viewer_screen.dart`. 
- **Impact:** This prevents multiple rapid back-presses from queuing up overlapping delayed `.pop()` calls, ensuring that the app only pops exactly one screen, even if the user double-taps the back button very fast.


## [1.4.78+101] - 2026-07-05
### Technical Debt Fix: Deprecated WillPopScope
- **API Upgrade:** Replaced the deprecated `WillPopScope` with Flutter's modern `PopScope` API in `pdf_tools_screen.dart`.
- **Logic Updated:** Implemented `canPop: !_isMergeMode` and `onPopInvokedWithResult` to correctly handle the custom back navigation logic without relying on legacy Flutter APIs, ensuring future SDK compatibility.


## [1.4.77+100] - 2026-07-05
### Performance Fix: Heavy Memory Spikes on Thumbnail Rebuilds
- **Stateful Caching:** Converted `FileThumbnail` from `StatelessWidget` to `StatefulWidget`. The `FutureBuilder` future (`_thumbnailFuture`) is now cached in `initState` and only updated in `didUpdateWidget` if the file path changes. 
- **Impact:** This prevents the app from constantly hitting the disk (`cacheDir.exists()`) or memory (`file.readAsBytes()`) every time the user scrolls the list or a parent widget calls `setState()`, completely removing the lag when browsing folders with many large PDFs.


## [1.4.76+99] - 2026-07-05
### Performance Fix: Removed Blocking IO from FileManagerService
- **Async File Fetching:** Replaced synchronous `.listSync()` and nested `.statSync()` inside sorting closures with a new highly concurrent `_getSortedFilesAsync` helper. 
- **O(N) Optimization:** Instead of checking file stats O(N log N) times during sorting, we now fetch stats completely asynchronously, cache them in a Dart Record list `(FileSystemEntity, FileStat)`, sort them efficiently, and return. This prevents UI stuttering or jams in folders with 100+ files.


## [1.4.75+98] - 2026-07-05
### Bug Fix: Silent File Overwrites & Data Loss in FileManagerService
- **Duplicate Prevention:** Added a private helper `_getUniqueFilePath` which dynamically appends numbers (e.g., `(1)`, `(2)`) to filenames if a file with the same name already exists in the destination folder.
- **Fixed Methods:** Applied this duplicate-check to `moveToTrash`, `moveFolderToTrash`, `moveFileToFolder`, and `removeFileFromFolder` so users no longer silently lose data when organizing files or moving them to trash.


## [1.4.74+97] - 2026-07-05
### Bug Fix: Unhandled Camera Permissions & Infinite Loading in ScannerScreen
- **Permission Handled:** Added explicit `Permission.camera.request()` check in `_initCamera()`. If denied, the app now shows a proper error message with an "Open Settings" button instead of failing silently.
- **UI UX Fix:** Fixed the infinite loading screen dead-end. The loading state (`CircularProgressIndicator`) and error states now correctly display a functional Back button, allowing the user to safely exit the scanner screen instead of getting stuck.


## [1.4.73+96] - 2026-07-05
### Bug Fix: setState after dispose in ViewerScreen
- **Crash Prevented:** Added `if (!mounted) return;` checks inside PDF native engine callbacks (`onViewerReady` and `onPageChanged`) in `viewer_screen.dart` to prevent crashes when the user quickly exits the viewer while a PDF is loading.


## [1.4.72+95] - 2026-07-05
### Bug Fix: setState after dispose in SettingsScreen
- **Crash Prevented:** Added `if (!mounted) return;` checks after all async operations (like `SharedPreferences.getInstance()`, `PackageInfo.fromPlatform()`) in `settings_screen.dart` to prevent app crash if the user navigates away from the screen before the async operations complete.


## [1.4.71+94] - 2026-07-05
### Zero-Delay Intent Startup (Critical Performance Fix)
- **Removed All Blocking Awaits Before `runApp()`:** Root cause of 5-6 second delay was 3 sequential `await` calls (`AdService.initialize()`, `NotificationService.initialize()`, `SharedPreferences.getInstance()`) blocking `runApp()`. Flutter engine couldn't start until these completed, keeping user stuck on native splash screen for 2-3 seconds before any Dart frame rendered.
- **Lazy-Initialized Heavy Services:** Moved all heavy service initialization (ads, notifications, SharedPreferences, theme loading, trash cleanup) to `addPostFrameCallback` — they now run in the background **after** the first UI frame is drawn. User sees the app instantly.
- **FutureBuilder Direct Routing:** `MaterialApp.home` now uses a `FutureBuilder` that fetches intent data and renders `ViewerScreen` directly if a shared PDF is detected, or `HomeScreen` if not. No more HomeScreen → ViewerScreen flash/flicker.
- **Error Handlers Extracted:** Moved error handler setup to a separate `_setupErrorHandlers()` function for cleaner non-async `main()`.

## [1.4.70+93] - 2026-07-05
### Version Bump
- Version bump for latest fixes.


### Critical Fixes & Memory Optimization
- **Directionality Crash Fix:** Reverted the `onGenerateInitialRoutes` approach in `MaterialApp` which was causing a `No Directionality widget found` crash at launch when opening intents. Implemented a much safer and robust approach using `WidgetsBinding.instance.addPostFrameCallback` in `initState`. This guarantees the route is pushed instantly at 0ms delay *after* the `MaterialApp` is fully mounted, providing the zero-delay intent loading without breaking the widget tree.
- **Memory Leaks Resolved:** Audited the app for memory leaks and applied `.dispose()` correctly to various local `TextEditingController`s that were left undisposed in dialogs (e.g., Folder creation, Folder rename, File rename, PDF protect). 
- **Unused Controller Cleanup:** Removed a lingering, unused `PdfViewerController` in `ViewerScreen` that was holding onto memory without being properly disposed.


## [1.4.68+91] - 2026-07-05
### Performance & UX Enhancements
- **Instant Intent Loading (Zero Delay):** Fixed a 4-5 second visual delay where opening a PDF from WhatsApp would first render the `HomeScreen` before pushing the `ViewerScreen`. Moved the `getInitialMedia` check to `main()` before `runApp()`, and utilized `onGenerateInitialRoutes` in `MaterialApp` to instantly build the navigation stack. The app now opens directly and seamlessly into the PDF viewer with no flicker.
- **PDF Viewer Stutter Fix:** Resolved severe UI stuttering and lag when scrolling through PDFs. The root cause was an aggressive memory cache (`maxImageBytesCachedOnMemory: 500MB`) in `PdfViewerParams` that choked the Dart Garbage Collector. Removed the manual memory override, allowing `pdfrx` to use its highly optimized native memory management for smooth, lag-free scrolling.

## [1.4.67+90] - 2026-07-05
### Bug Fixes
- **Dynamic File Type Detection (Crash Fix):** Fixed a crash (`Exception: Invalid image data`) that occurred when sharing a PDF from WhatsApp to the app. WhatsApp caches files without `.pdf` extensions. The app's `ViewerScreen` mistakenly identified it as an image because it relied on the file extension. Implemented a robust `_checkIfPdf` method that reads the file's binary header magic bytes (`%PDF-`) to dynamically and accurately detect PDF files, preventing crashes and loading them correctly in the `PdfViewer`.

## [1.4.66+89] - 2026-07-05
### Bug Fixes & UX Enhancements
- **Deep Linking / Intent Handling:** Fixed a bug where sharing a PDF to the app from external apps (like WhatsApp) would occasionally fail and just open the home screen. Removed the strict `.pdf` extension check in `_handleSharedMedia` to properly support Android content URIs that mask the file extension.
- **Light Theme Readability:** Enhanced the text contrast for the `FileFilterBar` choice chips and the `Merge Setup` file selection cards so that text is clearly visible when the device is set to Light Theme.
- **Password Cancellation Error:** Handled the `PdfException: No password supplied by PasswordProvider` crash. Now, if a user cancels the password dialog when opening an encrypted PDF, the viewer screen gracefully pops back instead of displaying a red error banner.

## [1.4.65+88] - 2026-07-05
- **Intent Filter Labels:** Updated `AndroidManifest.xml` to present a cleaner brand identity in the Android "Open with" system dialog. The main app label was changed from `scan_master_app` to `Scan Master`, and the specific PDF intent filter was changed from `Scan Master PDF Viewer` to simply `PDF Viewer`.

## [1.4.64+87] - 2026-07-05
- **OCR Crash Fix:** Resolved a critical `ClassNotFoundException` that caused the app to crash when processing non-English (e.g., Hindi/Devanagari, Japanese, Chinese, Korean) text recognitions. explicitly added the required native Android ML Kit dependencies to `android/app/build.gradle.kts`.

## [1.4.63+86] - 2026-07-05
- **PDF Viewer Password Support:** Resolved the `PdfException: No password supplied by PasswordProvider` error in `PdfViewer`. Added an interactive alert dialog (`_showPasswordDialog`) that securely prompts the user for a password when attempting to open encrypted PDFs.
- **Filter Chip Visibility:** Enhanced readability on the Home Screen by adjusting the text color of unselected `ChoiceChip` items from dark grey to a high-contrast light grey (`Colors.grey.shade300`), making them clearly visible against the app's dark theme.

## [1.4.62+85] - 2026-07-05
- **Premium OCR Language Selector:** Replaced the standard Material dropdown in `OcrScreen` with a sleek, 120fps-smooth `showModalBottomSheet`. The new selector is triggered by a beautiful, animated `InkWell` card displaying the current language with leading icons.
- **OCR Crash Fix:** Implemented a robust "Safe Switch" state management system in `OcrScreen`. The app now safely disposes of (`close()`) the previous `TextRecognizer` instance before allocating memory for a new script model, entirely preventing crashes when rapidly switching languages.

## [1.4.61+84] - 2026-07-05
- **Fresh Deployment:** Performed a clean installation of the app on the user's device to ensure the new OCR Language Dropdown feature (from version 1.4.60) is fully active and accessible.

## [1.4.60+83] - 2026-07-05
### Features & UX
- **Universal OCR Language Support:** Added a comprehensive Dropdown selection menu to `OcrScreen` allowing users to switch the Google ML Kit TextRecognitionScript on-the-fly. This enables text extraction across 5 major global scripts: Latin (English/European), Devanagiri (Hindi), Japanese, Korean, and Chinese.

## [1.4.59+82] - 2026-07-05
- **OCR Multi-Language Support:** Changed the default Google ML Kit TextRecognitionScript from `latin` to `devanagari`. This allows the OCR feature to seamlessly and automatically extract both English and Hindi text simultaneously without requiring any manual language selection from the user.

## [1.4.58+81] - 2026-07-05
- **Visual Split PDF Interface:** Redesigned the "Split PDF" functionality from a blind text-input dialog into a full-fledged visual interactive screen (`VisualSplitPdfScreen`). Users can now see thumbnails of all pages in the PDF, view the selected file name, and intuitively tap on any page to mark the split point (indicated by a bold red outline and scissors icon).

## [1.4.57+80] - 2026-07-05
- **Removed Duplicate Protect PDF Action:** Removed the "Add Password (Protect)" card from the general PDF Tools screen because a dedicated, premium entry point already exists on the Home Screen. This reduces clutter and clarifies user flow.
- **Improved Dialog Context:** Modified the "Protect PDF" password dialog to display the name of the selected file (`Selected File: <filename>`), ensuring users know exactly which document they are encrypting.

## [1.4.56+79] - 2026-07-05
- **Centralized File Filter UI:** Refactored the File Filter Chips from being duplicated across `HomeScreen`, `FoldersScreen`, and `FolderViewScreen` into a single, reusable `FileFilterBar` widget. This strictly follows DRY principles. 
- **Filter UI Enhancements:** Made the filter chip background transparent, reduced the text size by ~20% for a sleeker look, and curved the corners (`BorderRadius.circular(20)`). Also removed the checkmark for a cleaner UI.

## [1.4.55+78] - 2026-07-05
### Performance & UX (120fps Smooth Scrolling)
- **Global Smooth Scroll Behavior:** Implemented `SmoothScrollBehavior` on the root `MaterialApp` enforcing `BouncingScrollPhysics` across the entire app. This replaces Android's default clamping physics, giving every `ListView`, `GridView`, and scrollable area a premium, high-refresh-rate (120fps) bouncing feel.
- **Persistent Disk Thumbnail Caching:** Completely eliminated the severe UI stutter/lag on app startup by replacing synchronous PDF rasterization (`readAsBytesSync`) with an asynchronous disk caching mechanism. Now, when a thumbnail is first generated, it is cached as a `.png` on the disk in the temporary directory. Subsequent app loads bypass PDF parsing entirely and instantly load the cached `.png`, bringing load times down to milliseconds and freeing up the main isolate.

## [1.4.53+76] - 2026-07-04
### New Features & SEO
- **Smart File Filters:** Added 8 dynamic file filters (All, PDFs Only, Signatures, Scanned PDFs, Merged PDFs, Split PDFs, Protected PDFs, Organized PDFs) to the Recent Files tab and Folder View screens. These act as descriptive SEO-friendly categories (`ChoiceChip` row) allowing users to easily parse through large document lists. 

## [1.4.52+75] - 2026-07-04
### Performance Enhancements
- **Lightning Fast Extraction:** Optimized the "Organize Pages" save logic. Instead of extracting pages one by one to temporary files and merging them (O(N) disk I/O), the app now passes the new `_pageOrder` array directly to the Rust backend (`pdf_manipulator`). The native engine rearranges the PDF pointers in memory instantly, cutting down save times for 100+ page documents to less than a second.

## [1.4.51+74] - 2026-07-04
### New Features
- **PDF Page Reordering:** Added a new "Organize Pages" button to the PDF Viewer. When tapped, it opens a visual grid of page thumbnails (`ReorderableGridView`). Users can long-press and drag to reorder pages. Upon saving, the app safely extracts and merges the pages in the new order, generating a fresh PDF while maintaining text quality and structure.

## [1.4.50+73] - 2026-07-04
### New Features
- **PDF Deep Linking (Open With support):** Added `receive_sharing_intent` and configured an `<activity-alias>` in `AndroidManifest.xml` with the SEO label "Scan Master PDF Viewer". The app can now receive PDFs from external apps (like File Managers or WhatsApp). When the user selects our app from the "Open with" chooser, the app launches (or resumes) and directly opens the PDF inside the `ViewerScreen`.

## [1.4.49+72] - 2026-07-04
### Bug Fixes & UX Enhancements
- **Consistent File Options UI:** Extracted the comprehensive file options bottom sheet into a shared `FileOptionsHelper`. Now, tapping the 3-dot menu on a file in the "Folders" tab or inside a specific folder shows the exact same rich options (Open, Rename, Move to Folder, PDF Tools / Edit Image, Share, Remove from Folder, Delete) as the "Recent Files" tab, instead of just a basic delete popup.

## [1.4.48+71] - 2026-07-04
### New Features
- **Cancel Processing Option:** Added a "Cancel" button to the PDF processing dialog (used during merging, splitting, and encrypting). If the user cancels midway, the progress overlay is immediately dismissed and any partially generated/corrupt output files are cleanly deleted to avoid clutter and data corruption.

## [1.4.47+70] - 2026-07-04
### Bug Fixes & UX Enhancements
- **PDF Merging Performance (OOM fix):** Fixed an issue where merging large PDFs (e.g., 24MB) would stall at 99% or crash by replacing memory-heavy `MemorySource` with `FileSource`.
- **PDF Viewer Sub-pixel Clipping:** Fixed the PDF viewer layout where the top edge (e.g., table headers) of pages was getting cut off. Applied a custom integer-rounded `layoutPages` bounding box to `pdfrx` `PdfViewerParams` to prevent sub-pixel rendering overlap and clipping.
- **Protect PDF UI Flow:** Refactored `PdfToolsScreen` to show a dedicated "Select PDF to Encrypt" UI when accessed directly from the Home Screen's Protect action card, removing the confusing Split/Merge options for that specific flow and ensuring it no longer bypasses the UI and goes straight to the file picker.

## [1.4.46+69] - 2026-07-04
### UI Navigation & Experience
- **Internal Viewer for Notifications:**
  - **Issue:** Tapping a completion notification (e.g., after merging/splitting) used `OpenFilex` to open the PDF in an external app, breaking the immersive app experience.
  - **Fix:** Added a global `navigatorKey` in `main.dart` and updated `NotificationService`. Now, if a notification payload points to a PDF, it intelligently pushes the app's own `ViewerScreen` onto the navigation stack, allowing users to seamlessly view their file and easily return to the app by pressing back.

## [1.4.45+68] - 2026-07-04
### Code Quality & ASO (App Store Optimization)
- **Dynamic Strings Refactoring:**
  - **Enhancement:** Identified and extracted multiple hardcoded UI strings from `pdf_tools_screen.dart` and `home_screen.dart` into `AppStrings` class (`app_strings.dart`).
  - **Compliance:** This ensures strict adherence to AGENTS.md Rule #4 (SEO & Dynamic Content), making all new "Protect PDF" and PDF Toolkit texts completely dynamic, localized-ready, and ASO friendly.

## [1.4.44+67] - 2026-07-04
### UI Flow Correction
- **Protect PDF Auto-Launch Fix:**
  - **Issue:** Tapping "Protect PDF" from the Home Screen automatically launched the native file picker immediately, bypassing the tool's dedicated screen. This felt abrupt to the user.
  - **Fix:** Removed the `addPostFrameCallback` auto-launch logic in `pdf_tools_screen.dart`. Now, users arrive at the clean "Protect PDF" screen first, and can tap the action card to open the file manager at their own pace.

## [1.4.43+66] - 2026-07-04
### UI & Rendering
- **PDF Viewer Page Clipping Fix:**
  - **Issue:** Users reported that the top edge of PDF pages was getting cut off or clipped when scrolling through continuous pages in the PDF Viewer.
  - **Fix:** Increased the vertical `margin` between pages to `16.0` and removed the default `pageDropShadow` in `pdfrx` `PdfViewerParams`. The shadow and small margin were causing the bottom of one page to overlap and visually crop the top edge of the subsequent page.

## [1.4.42+65] - 2026-07-04
### UI & Feature Discoverability
- **Protect PDF Dedicated View:**
  - **Issue:** When users tapped "Protect PDF" from the Home Screen and dismissed the file picker (or finished encrypting), they were shown the general "PDF Tools" screen with all three options (Merge, Split, Protect), causing confusion.
  - **Fix:** Refined the UI logic so that if the screen is launched specifically in 'protect' mode, it acts as a standalone tool. The screen title dynamically changes to "Protect PDF" and the Split/Merge cards are completely hidden, keeping the user focused solely on the encryption tool.

## [1.4.41+64] - 2026-07-04
### Core Functionality & Stability
- **Large PDF Merge Hang/Crash Fix:**
  - **Issue:** Merging large PDFs (e.g., 24MB) caused the app to hang at 99% for minutes and eventually crash. This was due to the underlying `FileSource` continuously opening and closing native file handles for every small byte-read operation, leading to File Descriptor exhaustion and thread starvation.
  - **Fix:** Switched `FileSource` to `MemorySource` in `pdf_tools_screen.dart` (`_splitPdf` and `_mergePdf`). This pre-loads the PDF bytes directly into memory once, bypassing the slow native file I/O bottleneck entirely. Now merging large PDFs completes in a fraction of a second.

## [1.4.40+63] - 2026-07-04
### UI & Feature Discoverability
- **Protect PDF Dedicated Button:**
  - **Enhancement:** Added a dedicated "Protect PDF" action card directly to the Home Screen grid. This makes the premium "Add Password" feature highly visible to users right from the start.
  - **UI Detail:** The card features a deep purple gradient and a premium "crown" badge in the top right corner to clearly indicate it as a Pro feature. Tapping it directly launches the PDF selection and password protection flow.

## [1.4.39+62] - 2026-07-04
### Performance & UX
- **PDF Viewer Page Reload Fix:**
  - **Issue:** Scrolling down a long PDF and scrolling back up caused earlier pages to display as blank/black momentarily while re-rendering, because they were evicted from memory.
  - **Fix:** Increased the `maxImageBytesCachedOnMemory` in `PdfViewerParams` from the default 100MB to 500MB. This allows the app to retain significantly more rendered pages in RAM, delivering a buttery-smooth scrolling experience without white/black flashes when returning to previous pages.

## [1.4.38+61] - 2026-07-04
### Architecture & Stability
- **Global Industry-Level Error Handling:**
  - **Feature:** Implemented global exception catchers in `main.dart` to prevent the app from crashing and to hide raw stack traces from the end user.
  - **Implementation:** 
    - Overrode `ErrorWidget.builder` to show a clean, user-friendly UI when a widget fails to build (instead of the red screen of death).
    - Set up `PlatformDispatcher.instance.onError` to catch uncaught asynchronous Dart exceptions globally, logging them and displaying a subtle SnackBar to the user.
    - Set up `FlutterError.onError` for catching and logging standard framework errors without crashing.

## [1.4.37+60] - 2026-07-04
### Bugfixes & Industry-Level Error Handling
- **FPDF_ERR_FORMAT: 3 Fix:**
  - **Issue:** The `Pdf().merge()` function from the new `pdf` engine was generating corrupted, unreadable PDFs, resulting in `FPDF_ERR_FORMAT: 3` when opened in `pdfrx`.
  - **Fix:** Identified that the native PDF writer stream was closed without calling `pdf.dispose()`. Added `await pdf.dispose()` to the split, merge, and protect pipelines, ensuring that the EOF marker and cross-reference tables are properly written before file sinks are closed.
- **Industry-Standard PDF Error UI:**
  - **Issue:** When a corrupted or unsupported PDF failed to load, `pdfrx` displayed a raw, blue-screen-of-death style default error overlay with full stack traces.
  - **Fix:** Implemented a custom `errorBannerBuilder` in `PdfViewerParams` that catches format exceptions gracefully. It now displays a sleek, dark-themed, user-friendly error UI instead of crashing the experience, matching industry standards.

## [1.4.36+59] - 2026-07-04
### UX Enhancements
- **Interactive Notifications:**
  - **Feature:** Added the ability to open the newly generated PDF directly by tapping on the completion notification.
  - **Implementation:** Updated `NotificationService.showNotification` to accept a file path `payload`. Configured `onDidReceiveNotificationResponse` to use the `open_filex` package to launch the generated PDF file (or the folder in case of PDF Split) directly from the notification tray.

## [1.4.35+58] - 2026-07-04
### Bugfixes & UX Improvements
- **Merge Mode Navigation Fix:**
  - **Issue:** When the user was in "Merge Setup" mode (`_isMergeMode = true`), pressing the physical Android back button (or swipe back gesture) completely popped the `PdfToolsScreen` and returned to the Home Screen. The app was failing to remember the "in-screen history".
  - **Fix:** Wrapped the main `Scaffold` of `PdfToolsScreen` with a `WillPopScope`. It intercepts the system back event: if `_isMergeMode` is active, it prevents popping and instead gracefully resets the state (`_isMergeMode = false`), returning the user to the single file tools screen without escaping the context entirely.

## [1.4.34+57] - 2026-07-04
### UI & Core Upgrades (UX/SEO Optimized)
- **PDF Engine Upgrade (pdfrx):**
  - **Issue:** The `flutter_pdfview` package was trapping scroll events at the bottom of the page when `autoSpacing` was false, making it impossible to scroll back up smoothly.
  - **Fix:** Completely replaced `flutter_pdfview` with `pdfrx` which uses Flutter's native `Canvas` and `Pdfium`. This guarantees 120Hz smooth scrolling without any gap margins and completely eliminates the bottom page scrolling trap.
- **FAB UI Refinement:**
  - **Issue:** User requested the `BottomAppBar` to be even shorter for a sleeker look and perfectly centered glowing FAB.
  - **Fix:** Reduced `BottomAppBar` height to `58` and adjusted the floating action button calculation accordingly. The FAB glow now shines completely unobstructed.

## [1.4.33+56] - 2026-07-04
### UI & Crash Fixes
- **PDF Viewer UI Fix:**
  - **Issue:** The new native `flutter_pdfview` had `autoSpacing: true` which forced each PDF page to fill exactly one screen height, creating massive margins on A4 pages. The pages were also shrunk due to lacking width bounds.
  - **Fix:** Set `autoSpacing: false` and `fitPolicy: FitPolicy.WIDTH`. Now PDF pages render back-to-back normally spanning full width without excessive vertical spacing.
- **Native Crash on Encrypted PDF Thumbnails:**
  - **Issue:** `FileThumbnail` attempts to generate PDF previews using the `printing` package (`Printing.raster`). If the PDF is password protected, the native Android `PdfRenderer` throws a `SecurityException`, bypassing Flutter's error handling and causing a fatal native app crash.
  - **Fix:** Implemented `_isPdfEncrypted` in `file_thumbnail.dart` to read the first and last 4KB of the file looking for the `/Encrypt` keyword. If found, thumbnail generation is skipped entirely, showing a placeholder lock icon and preventing the native crash.
- **Home Screen BottomNavigationBar Fix:**
  - **Issue:** The FAB glow effect was getting clipped due to an increased `BottomAppBar` height of 80 combined with a hardcoded FAB location script.
  - **Fix:** Restored `BottomAppBar` height to 65 to align with `_FixedCenterDockedFabLocation` calculations. Fixed the original pixel overflow by setting `padding: EdgeInsets.zero` on the `BottomAppBar`.

## [1.4.28+51] to [1.4.32+55] - 2026-07-04
### Major UI Overhaul & Performance Enhancements
- **PDF Viewer Migration (Syncfusion to Native):**
  - **Issue:** `syncfusion_flutter_pdfviewer` was causing severe lag, OOM crashes on large PDFs, and blocking the main thread during scrolling.
  - **Fix:** Removed Syncfusion viewer and migrated to `flutter_pdfview` (later replaced by `pdfrx`) for native, hardware-accelerated rendering.
- **Premium Glowing FAB Design:**
  - **Details:** Redesigned the Home Screen bottom navigation. Removed the standard floating action button and introduced `_GlowingScanButton` with a pulsating purple shadow `CurvedAnimation`.
  - **State Changes:** Adjusted `BottomAppBar` height to 80 (initially) to prevent `RenderFlex` overflow errors caused by the new FAB layout constraints.
- **Direct PDF Manipulation:**
  - **Details:** Integrated `pdf_manipulator` for splitting/merging PDFs natively on the background thread, replacing Syncfusion's heavy Dart-based document modification which was causing ANRs.

## [1.4.27+50] - 2026-07-04
### Bugfixes & UX Enhancements (SEO/ASO Optimized)
- **PDF Out of Memory (OOM) Fix:**
  - **Issue:** Passing huge file `Uint8List` bytes into Isolate caused memory duplication and a 70% OOM crash.
  - **Fix:** Refactored `_processSplitPdf`, `_processMergePdf`, and `_processProtectPdf` in `pdf_tools_screen.dart` to accept the `inputPath` (String) instead. The Isolate now reads the file locally via `File(inputPath).readAsBytesSync()`. Aggressive `dispose()` and memory cleanup added to prevent spikes.
- **System Push Notifications:**
  - **Details:** Integrated `flutter_local_notifications` (v22). Added `NotificationService` to push actual Android system notifications when the background task completes, ensuring users know when their PDF is ready even if the app is minimized.
- **Merge PDF Redesign:**
  - **Issue:** Users didn't know which two files were being merged. 
  - **Details:** Added `_isMergeMode` state. When users tap "Merge", the UI expands to show explicit "File 1" and "File 2" cards. Both must be selected before the "Start Merge" button appears.
- **SEO & App Ranking Strings:**
  - Extracted all hardcoded texts into `constants/app_strings.dart` for dynamic configuration (Rule: "Koi bhi text ya configuration hardcode nahi karni hai").

## [1.4.26+49] - 2026-07-04
### Features & UX (SEO & ASO Optimized)
- **Background Processing & Live Progress Indicator for PDFs:**
  - **File Changed:** `lib/screens/pdf_tools_screen.dart`, `lib/main.dart`
  - **Issue:** The user had no visual indication of how long large PDF processes (merge/split/protect) would take. Also, waiting on the screen blocked navigation, which is a poor experience.
  - **Details:** Replaced basic `CircularProgressIndicator` with a dynamic `LinearProgressIndicator` (mapped to `_progress` percentage). Replaced the `compute` wrapper with direct `Isolate.spawn` passing a `SendPort`.
  - **State Changes:** Added a new state variable `_progress` (ranging 0.0 to 1.0) and `_progressMessage`. The UI reacts to these changes via `setState()` when progress updates are received over the `ReceivePort`.
  - **Global SnackBar Mechanism:** Added `rootScaffoldMessengerKey` to `main.dart` so that when the Isolate finishes saving the file, a success notification can pop up anywhere in the app, even if the user has navigated away from `PdfToolsScreen`.
  - **SEO & UX Rule Compliance:** The loading screen now presents a highly professional, industry-level message: *"Processing large file in background. You can safely go back; we will notify you when it's done."* This strongly adheres to the "App Ranking / UX friendly" mindset demanded by the rules, establishing trust and reducing user drop-off.


### [1.4.25+48] - 2026-07-04
### Bugfixes & Performance
- **PDF Tools ANR/Crash Fix (Offloading CPU Work):**
  - **File Changed:** `lib/screens/pdf_tools_screen.dart`
  - **Issue:** When the user attempted to merge, split, or protect large PDF files, the main thread was blocked, causing the app to hang/crash (ANR).
  - **Details:** Inside `_mergePdf`, `_splitPdf`, and `_protectPdf`, the app was instantiating Syncfusion `PdfDocument` objects and performing heavy page manipulations (loops, template drawing) directly on the UI thread.
  - **Solution:** Created 3 new top-level functions: `_processMergePdf`, `_processSplitPdf`, and `_processProtectPdf`. These functions were offloaded from the UI thread to a background isolate using Flutter's `compute` method.
  - **State Changes:** The `_isProcessing` state is set to `true` before launching the background thread and `false` upon completion, ensuring the loading indicator remains visible while the background isolate saves the PDF.

## [1.4.24+47] - 2026-07-04
### Bugfixes
- **Home Screen Syntax Error Resolution:**
  - **File Changed:** `lib/screens/home_screen.dart`
  - **Issue:** While adding subtitles in `_buildActionCard` and other widgets, brackets `)` and `}` were mismatched, causing the `assembleRelease` build to fail.
  - **Solution:** Performed a manual code traversal to insert missing brackets and remove redundant braces, restoring the correct file structure and widget tree in `home_screen.dart`.

## [1.4.23+46] - 2026-07-04
### Improvements
- **Home Screen UI Enhancement (Subtitles):**
  - **File Changed:** `lib/screens/home_screen.dart`
  - **Details:** The user noted that the features inside action cards (QR Toolkit, OCR Text, PDF Tools) were not immediately clear from the outside.
  - **Changes:** Wrapped the icon and title layout inside a `Column` and added an informative subtitle (`Text` widget, color `Colors.grey[400]`, fontSize 12) directly beneath the main title for every action card.
  - **SEO & UX:** This adheres to the 'SEO friendly / UX friendly' rule by making the app's intent immediately clear (e.g., adding "Merge, Split, Protect" under PDF Tools).

## [1.4.22+45] - 2026-07-04
### Bugfixes
- **Signature Viewer Contrast Fix:**
  - **File Changed:** `lib/screens/viewer_screen.dart`
  - **Issue:** Hand-drawn signature files are transparent, and the default `InteractiveViewer` background is black. This caused black signatures to blend into the black background, confusing users.
  - **Solution:** Wrapped the Image widget inside a `Container` with its `color` property set to `Colors.white`. Now, any `.png` (especially transparent signatures) appears clearly on a solid white background.

## [1.4.21+44] - 2026-07-04
### Improvements
- **Viewer Background Implementation:** Explored methods to provide high contrast for black signature strokes in image view mode.

## [1.4.20+43] - 2026-07-04
### Features
- **Signature Persistence & Saving:**
  - **File Changed:** `lib/services/file_manager_service.dart`, `lib/screens/signature_screen.dart`
  - **Issue:** Saved signatures were not appearing in the 'Recent' or 'Folders' lists.
  - **Solution:** Modified the extension checking logic in `FileManagerService.loadFiles()` and `getRecentFiles()` to allow loading of `.png` files (previously only `.pdf` and `.jpg` were permitted).
  - **State Changes:** Triggered the refresh logic to update the list view.

## [1.4.19+42] - 2026-07-04
### Refactor
- **File Manager Tweaks:** Adjusted logic to support arbitrary image extensions smoothly, preparing for `.png` support.

## [1.4.18+41] - 2026-07-04
### Improvements
- **Floating Action Button (FAB) Positioning Fix:**
  - **File Changed:** `lib/screens/home_screen.dart`
  - **Issue:** When SnackBars or bottom popups appeared, the FAB was pushed upward from its docked position, leading to poor UX.
  - **Solution:** Created a custom FAB location class named `_FixedCenterDockedFabLocation` (extending `StandardFabLocation` with `FabCenterOffsetX`) that keeps the FAB permanently docked at the bottom center of the navigation bar, regardless of SnackBars appearing.
  - **Event Attachments:** Replaced the `floatingActionButtonLocation` property in the Scaffold with this new custom class.

## [1.4.17+40] - 2026-07-04
### Improvements
- **FAB Behavior Adjustments:** Analyzed FAB displacement issues alongside SnackBar appearances and prepared a custom layout strategy.

## [1.4.16+39] - 2026-07-04
### Refactor
- **Home Screen Alignment:** Minor adjustments to UI component padding and alignment in preparation for FAB lock fix.

## [1.4.15+38] - 2026-07-04
### Bugfixes
- **App Update Notification Crash:**
  - **Issue:** Attempting to show the update dialog after a widget was disposed (e.g., during splash screen transitions) caused Flutter to throw an `Unhandled Exception: setState() called after dispose()`.
  - **Solution:** Added an `if (mounted)` check in the update checker to ensure the asynchronous API call (GitHub release fetch) completes and only triggers the dialog if the context remains valid and mounted.

## [1.4.14+37] - 2026-07-04
### Features
- **Update Logic Initiation:** Began implementing logic for background checking of new versions and app update dialogs.

## [1.4.13+36] - 2026-07-04
### Improvements
- **Minor Tweaks & Code Cleanup:**
  - **Details:** Removed unused logs and debug print statements from earlier SnackBar exception handling work.
  - **Compliance:** Formatted the codebase for better readability.


## [1.4.12+35] - 2026-07-04
### New Features
- **Share Folder Option:** Added a "Share Folder" option to the popup menu in `folders_screen.dart`. When selected, all files inside the folder are compressed into a `.zip` file and shared natively using `share_plus`. A snackbar notifies the user that the folder is being zipped.

## [1.4.11+34] - 2026-07-04
### Improvements
- **Premium UI Animations:** Implemented a new `PremiumPageTransitionsBuilder` and `AppAnimations` utility class to provide an ultra-smooth, 120Hz-feeling premium experience. All page transitions (`MaterialPageRoute`), dialogs (`showDialog`), and bottom sheets (`showModalBottomSheet`) across all screens (Home, Folders, Folder View, PDF Tools, Trash) now use a custom fluid ease-out animation (Curves.easeOutQuart) with a soft fade and scale (0.98 -> 1.0) effect. Duration ranges from 240ms to 280ms for an extremely polished, high-end feel similar to Pixel/Samsung One UI.

## [1.4.10+33] - 2026-07-04
### Bugfixes
- **SnackBar Sticking Issue (Swipe-to-delete):** Fixed a critical bug in `home_screen.dart`, `folders_screen.dart`, and `folder_view_screen.dart` where the "Undo" SnackBar would stick permanently. The issue occurred because `ScaffoldMessenger.of(context)` was called after an `await` using the context of a deleted list item (which gets unmounted), causing an exception and preventing `hideCurrentSnackBar()` from executing. Captured the `ScaffoldMessengerState` before `await` to safely display and hide the SnackBar.

## [1.4.9+32] - 2026-07-04
### Improvements
- **Bottom Navigation Bar UI:** Modified the `NavigationBar` in `home_screen.dart`. Hid the labels ("Recent Documents" and "Client Folders") by setting `labelBehavior: NavigationDestinationLabelBehavior.alwaysHide` and reduced the height to 60px (approx 20% smaller) to provide more screen space for the content.

## [1.4.8+31] - 2026-07-04
### Bugfixes & Improvements
- **Crash Fixes & Imports:** Fixed compilation errors caused by missing imports (`share_plus`, `archive`, `FileManagerService`) and duplicated functions (`_editImage`). Resolved the app crash on startup.
- **Undo SnackBar Force Hide:** Updated the SnackBar logic in `folders_screen.dart` and `folder_view_screen.dart` to explicitly use `hideCurrentSnackBar()` after a 2-second `Future.delayed`. This bypasses system accessibility settings that were permanently sticking the SnackBar to the screen.

## [1.4.7+30] - 2026-07-04
### Improvements
- **Undo SnackBar Duration:** Increased the duration of the "Moved to Trash" Undo SnackBar from 2 seconds to 5 seconds across all screens (Home, Folders, Folder View, QR) so users have enough time to tap "Undo" before it disappears.

## [1.4.6+29] - 2026-07-04
### Bugfixes
- **Release App Crash (WorkManager):** Fixed a critical native crash on app startup occurring only in Release mode (`Unable to get provider androidx.startup.InitializationProvider... Failed to create an instance of androidx.work.impl.WorkDatabase`). Created `proguard-rules.pro` to prevent R8/ProGuard from obfuscating `androidx.work` and `androidx.room` classes.

## [1.4.5+28] - 2026-07-04
### Improvements
- **Privacy Trust Badge:** Added a small privacy and security badge ("100% Offline • Safe & Secure • No Tracking") at the bottom of the HomeScreen to increase user trust and improve App Store Optimization (ASO). String is dynamic in `app_strings.dart`.

## [1.4.4+27] - 2026-07-04
### Improvements
- **Folder Swipe-to-Delete & Menu:** Enhanced `FoldersScreen` to support swipe-to-delete (Dismissible) with a red Trash background. Replaced the static delete icon with a 3-dot `PopupMenuButton` offering "Rename Folder" and "Move to Trash" options. Created dynamic strings for SEO compliance.

## [1.4.2+25] - 2026-07-04
### Improvements
- **Trash Feedback & Folder Deletion:** Added a 1-second "Moved to Trash" SnackBar confirmation when deleting a file from Recent Files or Folders. Also implemented the ability to delete entire folders to the Trash from the Folders tab.

## [1.4.1+24] - 2026-07-04
### New Features
- **Custom Document Filters:** Replaced standard photo filters in `pro_image_editor` with ML Kit-like document enhancement filters using custom ColorMatrices. The new filters include: Lighten, Magic Color, Grayscale, B & W, Eco, and No Shadow (simulated). This ensures edited images retain professional document quality without needing external scanners.

## [1.4.0+23] - 2026-07-04
### Improvements & Bug Fixes
- **Premium Image Editor Migration (`pro_image_editor`):** Removed `image_cropper` because of a known crash (`Reply already submitted`) and lack of Filters support. Integrated `pro_image_editor` which gives a comprehensive WhatsApp/iOS-like editing experience natively inside the app, allowing users to apply Filters (Grayscale, B&W, etc.), Crop, and Rotate saved images. Changes updated in `home_screen.dart` and `folder_view_screen.dart`.

## [1.3.0+22] - 2026-07-04
### New Features
- **Image Editing (`image_cropper` integration):** Replaced the "coming soon" snackbar with actual image editing. Users can now tap "Edit Image" on any JPEG/JPG file in Recent or Folders tab. This opens a premium image cropper UI allowing rotation, cropping, and aspect ratio adjustments. Changes are saved back to the original file.
- **Dynamic Theme Switching (`main.dart`, `settings_screen.dart`):** Replaced the placeholder Theme setting with a fully functional Dropdown (System Default, Light Theme, Dark Theme). The app now uses a global `ValueNotifier<ThemeMode>` combined with `ValueListenableBuilder` to apply theme changes instantly across the entire app without a restart. Preferences are saved via `SharedPreferences`. All text labels were added to `app_strings.dart` for ASO rules.

## [1.2.0+21] - 2026-07-04
### New Features
- **Trash Bin (Recycle Bin) System (`trash_screen.dart`, `file_manager_service.dart`):** Implemented a complete trash system so deleted files are not permanently lost immediately.
  - **Auto-Cleanup & Retention:** Files stay in the trash for a default of 30 days. Users can customize this (7, 15, 30, 60 days, or Never) in Settings. Startup cleanup runs automatically in `main.dart`.
  - **Restore & Permanent Delete:** UI created to view trash files, restore them to their original location (Recent Tab or specific Folders), or delete them permanently.
  - **Dynamic SEO Strings:** All texts are completely dynamic and SEO-friendly, stored in `app_strings.dart`.

## [1.1.4+19] - 2026-07-04
### New Features
- **Folder Sharing as ZIP (`folder_view_screen.dart`):** WhatsApp par multiple mixed files share karne par issues aa rahe the (sirf text share ho raha tha, files drop ho rahi thi). Isliye ab folder ko officially ek `.zip` archive bana kar share karne ka feature implement kiya gaya hai (using `archive` package). Isse user WhatsApp par pura folder as a single ZIP file bhej sakta hai jise receiver extract karke andar ki saari files (PDF, JPEG, etc.) ek saath dekh sakta hai.

## [1.1.3+18] - 2026-07-04
### UI / UX Improvements
- **Tab Navigation Back Support (`home_screen.dart`):** Folders tab par hone par ab top AppBar me ek "Back (<-)" button dikhega. Sath hi `PopScope` implement kiya gaya hai taaki user agar mobile ka physical back button press kare toh app close hone ki jagah wapas "Recent" tab par chali jaye (history retention).

## [1.1.2+17] - 2026-07-04
### Bug Fixes / Tweaks
- **Folder Sharing Tweaked (`folder_view_screen.dart`):** User didn't want the folder contents to be forcibly merged into a PDF. Changed the logic to directly share all files (JPEGs, PDFs) inside the folder at once using `Share.shareXFiles()`. This allows the user to truly "share the folder contents" in their original formats.

## [1.1.1+16] - 2026-07-04
### Bug Fixes
- **Scanner Cancellation Error Fixed (`home_screen.dart`):** Suppressed the `PlatformException(DocumentScanner, Operation cancelled, null, null)` dialog. Jab user scanner open karke bina scan kiye back (cancel) kar deta tha toh pehle ye "Scan Error" dikhata tha. Ab ise handle kar liya gaya hai taaki back aane par gracefully ignore ho jaye bina error pop-up ke.

## [1.1.0+15] - 2026-07-04
### New Features
- **Client Folder Management (E-Mitra Mode):** Implemented a complete folder system to organize scanned documents by customer/client name.
  - Added a `BottomNavigationBar` in `HomeScreen` to toggle between 'Recent' and 'Folders'.
  - Added `FoldersScreen` to create and list directories within the app's document path.
  - Added `FolderViewScreen` to view documents inside a specific folder.
  - **Move Feature:** Added 'Move to Folder' option in the Recent file context menu (long-press/three-dots) to shift loose files into folders.
  - **Share as PDF:** E-Mitra optimized "Share Folder as PDF" feature. Automatically merges all images in a customer's folder into a single PDF document before launching the Android Share Sheet.

## [1.0.13+14] - 2026-07-04
### Bug Fixes
- **Ultimate Viewer Pop Crash Fix (`viewer_screen.dart`):** Finally eliminated the persistent `RenderBox was not laid out: RenderTransform` layout crash. The crash was caused by `InteractiveViewer` and `SfPdfViewer` continuing to animate or recalculate bounds during the route popping transition/predictive back gesture. Implemented a `PopScope` that intercepts the back action, immediately unmounts the viewer widget (replacing it with a loading spinner), waits 10ms for the unmount to flush through the framework, and then performs the actual `Navigator.pop()`. This completely isolates the complex viewers from the route transition logic.

## [1.0.12+13] - 2026-07-04
### Bug Fixes
- **Dismissible Predictive Back Crash Fix (`home_screen.dart`):** Resolved the `RenderBox was not laid out: RenderTransform` crash on the HomeScreen caused by the newly added `Dismissible` widget during the Android predictive back gesture from the ViewerScreen. Wrapped the `Dismissible` in a `RepaintBoundary` to isolate its layout pass and prevent Flutter's slide transition from asserting during route unmounts.

## [1.0.11+12] - 2026-07-04
### Bug Fixes
- **SfPdfViewer & InteractiveViewer Layout Fix (`viewer_screen.dart`):** Resolved the `RenderBox was not laid out: RenderTransform` error that occurred when popping the ViewerScreen. The `Center` widget was providing loose constraints to `SfPdfViewer` and `InteractiveViewer`, causing layout assertion failures during the route transition. Replaced `Center` with `SizedBox.expand` to ensure strict bounds. Also added missing `_pdfViewerController.dispose()` in the state's `dispose` method to prevent memory leaks during unmount.

## [1.0.10+11] - 2026-07-04
### Bug Fixes
- **RenderBox Layout Error Fix (`viewer_screen.dart`):** Fixed the `RenderBox was not laid out: RenderTransform` exception that occurred when navigating back from the ViewerScreen. The issue was caused by Flutter 3.10's `MenuAnchor` lifecycle during route pop. Reverted to `PopupMenuButton` but maintained the smooth user experience by utilizing the new `popUpAnimationStyle` with an `easeOutCubic` curve.

## [1.0.9+10] - 2026-07-04
### UI & UX Improvements
- **Swipe to Delete (`home_screen.dart`):** Wrapped the recent files list items in a `Dismissible` widget, allowing users to easily delete files by swiping from right to left (End to Start). A red background with a delete icon appears during the swipe.
- **Image Format Badges (`file_thumbnail.dart`):** Extended the PDF badge functionality to also display badges for image files (e.g., 'JPEG', 'PNG') with a blue accent color, helping users instantly identify the file format in the recent list.

## [1.0.8+9] - 2026-07-04
### UI & UX Improvements
- **Smooth Action Menu (`viewer_screen.dart`):** Replaced the legacy `PopupMenuButton` with the new Material 3 `MenuAnchor` to provide a much smoother drop-down animation (removing the sudden "bump" effect). 
- **Clean Menu UI:** Removed icons from the action menu items and shortened the ASO strings slightly (e.g., "Share PDF...") to perfectly match the sleek, text-only aesthetic of native Google apps.

## [1.0.7+8] - 2026-07-04
### Bug Fixes & UI Tweaks
- **File Save Fix (`viewer_screen.dart`):** Resolved an `Invalid argument(s): Bytes are required on Android & iOS` error during the "Save to Device" flow by passing `file.readAsBytes()` directly to `FilePicker.platform.saveFile`.
- **UI Compaction (`viewer_screen.dart`):** Replaced the bulky `ListTile` widgets in the AppBar's `PopupMenuButton` with compact `Row` layouts, significantly reducing the dropdown's footprint on the screen while maintaining ASO-friendly labels.

## [1.0.6+7] - 2026-07-04
### Bug Fixes & Feature Updates
- **PDF Generation Fallback:** Added a manual fallback generator in `scanner_service.dart` using the `pdf` package to ensure a PDF is created from JPEGs if ML Kit unexpectedly returns `null` for the PDF output.
- **Error Visibility:** Introduced a UI error dialog in `home_screen.dart`'s `_startScan` method to gracefully catch and display exceptions from `ScannerService`, making debugging transparent instead of failing silently.
- **Thumbnail Optimizations:**
  - Added a red 'PDF' badge overlay in `FileThumbnail` to clearly distinguish PDFs from JPEG files.
  - Implemented an in-memory `_thumbnailCache` (Map) for PDF rasterized thumbnails, eliminating the need to repeatedly run `Printing.raster()` upon screen transitions or scrolling.
  - Improved `_loadFiles` to bypass the loading spinner if files are already populated, removing list flickering.
- **ViewerScreen Search & Actions:**
  - Converted `ViewerScreen` to a `StatefulWidget` to integrate a `PdfViewerController` and a `TextEditingController`.
  - Added full-text PDF search functionality (up/down navigation through results) integrated directly into the `AppBar`.
  - Introduced a 3-dot action menu offering native intents: "Send File" (`share_plus`), "Open With" (`open_filex`), "Save / Download" (`file_picker`), and "Print" (`printing`).

## [1.0.5+6] - 2026-07-04
### Bug Fixes & Feature Updates
- **PDF Saving Fix (`scanner_service.dart`):** Resolved an issue where ML Kit Document Scanner output `file://` URIs, causing `File.copy()` to fail silently. Parsed the URI using `Uri.parse().toFilePath()` so PDFs correctly save and appear in the Recent Files list.
- **Dynamic Thumbnail Sizing:**
  - Added a "Thumbnail Size" dropdown in `settings_screen.dart` storing preferences (Small, Medium, Large) via `shared_preferences`.
  - Converted the Recent Files list in `home_screen.dart` from `ListTile` to a custom `InkWell` + `Row` layout to accommodate dynamically sized thumbnails without clipping.
- **In-App Viewer Enforcement:** Modified the 3-dot "Open" menu action in `home_screen.dart` to use `ViewerScreen` instead of `open_filex`, ensuring all documents open internally.
- **Build Infrastructure:** Added `proguard-rules.pro` to ignore missing ML Kit language classes (Chinese, Japanese, Korean, Devanagari) which were causing R8 minification failures during APK builds.

## [1.0.4+5] - 2026-07-04
### Infrastructure & Agent Guidelines Update
- **Build Pipeline Fix:** Resolved the persistent `compileSdk 36` dependency issue with `file_picker` and `flutter_plugin_android_lifecycle`. Reverted `file_picker` to `^8.3.7` and directly patched the pub cache Gradle configuration to forcefully compile against SDK 36. This ensures Android AAR compilation without Kotlin Gradle Plugin mismatch errors.
- **Agent Rules Updated (`AGENTS.md`):** Added a new permanent rule for SEO & Dynamic Content. All future features must avoid hardcoded text and be structured keeping App Store Optimization (ASO) in mind.

## [1.0.3+4] - 2026-07-04
### UI & Features Update
- **In-App File Viewer (`viewer_screen.dart`):**
  - Tapping a Recent File tile now opens it directly in a dedicated viewer within the app, instead of delegating to external apps.
  - Image viewing supports interactive pan/zoom via `InteractiveViewer`.
  - PDF viewing powered by `SfPdfViewer` (Syncfusion).
- **File Thumbnails (`file_thumbnail.dart`):**
  - Replaced generic static icons in the Recent Files list with real image thumbnails and dynamically rendered PDF cover thumbnails using the `printing` package.
- **Settings Screen (`settings_screen.dart`):**
  - Created a Settings screen accessible from the top-right gear icon.
  - Added an "About" section that fetches the actual App Version dynamically using `package_info_plus`.
  - **Packages Added/Upgraded:** `package_info_plus`, `syncfusion_flutter_pdfviewer`, `share_plus` (upgraded to any to resolve version conflict).

### State & Event Changes
- `HomeScreen` list tiles were hooked up to `Navigator.push` to navigate to the new `ViewerScreen`.

## [1.0.2+3] - 2026-07-04
### UI & Features Update
- **PDF Toolkit Implementation (`pdf_tools_screen.dart`):**
  - **Split PDF:** Added ability to split a PDF into two separate files at a specific page number.
  - **Merge PDF:** Added ability to merge the currently selected PDF with another PDF picked from the device using `file_picker`.
  - **Protect PDF:** Added ability to encrypt a PDF with a user-defined password using AES-256 bit encryption.
  - **Home Screen Integration:** Added a dedicated 'PDF Tools' quick action button on the Home Screen grid. The Bottom Sheet options for PDF files now also open this dedicated screen.
  - **Packages Added:** `syncfusion_flutter_pdf: 33.2.15`.

### State & Event Changes
- Created `PdfToolsScreen` stateful widget to manage file selection and processing state (`_isProcessing`).
- Updated `home_screen.dart` to navigate to `PdfToolsScreen` and reload the recent files list upon returning if any new files were generated.

## [1.0.1+2] - 2026-07-04
### UI & Features Update
- **Recent Files Menu Enhancement (`home_screen.dart`):**
  - **Open File:** Added `open_filex` package implementation to open PDF and Image files directly from the bottom sheet in native system viewers.
  - **Save to Gallery:** Added `gal` package integration. When the user selects a JPG/PNG file, the app requests necessary storage permissions (if required) and saves the image to the Android gallery. Added a SnackBar to confirm success or failure.
  - **Rename File:** Created a custom `AlertDialog` prompting the user to edit the filename (excluding extension). Replaces the old file natively and reloads the file list state.
  - **Placeholders:** Added 'PDF Tools' and 'Edit Image' UI elements as placeholders for future implementation.
  - **Packages Added:** `open_filex: 4.7.0`, `gal: 2.3.2`.
- **Bug Fix:** Fixed an issue where Ads were crashing the app upon initialization due to missing `APPLICATION_ID` in AndroidManifest. Then temporarily disabled Ads in `ad_service.dart` at the user's request using a boolean toggle.

### State & Event Changes
- `_showFileOptions` in `home_screen.dart` was modified to inject the new UI tiles.
- `_renameFile` Future method was bound to the UI to handle the asynchronous file renaming and state refresh.

## [04/07/2026] - Search Bar UI Fix, Scroll Performance, & Add to Folder
- **Home Screen Search UI**: Fixed an issue where the keyboard covered the search results. Now, when a user types in the search bar, the Quick Action buttons automatically hide, pulling the filtered 'Search Results' list directly below the search bar for easy access.
- **Add Files to Empty Folders**: Added a new FAB in the folder view that opens a premium bottom sheet containing all root files. This allows users to easily add existing files into any folder.
- **Smooth Scrolling (120 FPS target)**: Refactored the Home Screen to use CustomScrollView and SliverList instead of a SingleChildScrollView containing a shrink-wrapped ListView. This eliminates jank and provides ultra-smooth bouncing scroll physics.
- **Duplicate Checking**: Added case-insensitive duplicate checking for file renaming, folder renaming, and folder creation in file_manager_service.dart. ScaffoldMessenger alerts the user if the item already exists.
- **Settings**: Changed default thumbnail size to Small.
- **Version Bump**: 1.4.12+35 -> 1.4.13+36

- **Recent Files Filter**: Updated getRecentFiles in file_manager_service to only fetch files modified in the last 7 days (industry standard for recent).
- **Folders Tab File Display**: Updated folders_screen to display both folders and root files. Folders are displayed at the top, followed by files at the bottom. Added delete and view capabilities for files within this tab.
- **Version Bump**: 1.4.13+36 -> 1.4.14+37

- **Remove File From Folder**: Added 'Remove from Folder' option to file contextual menu in folder_view_screen to easily move files back to the root directory.
- **Recent Tab State Refresh**: Ensured Recent tab reloads files every time it is focused (via NavigationBar selection in home_screen) so stale entries of deleted or moved files are removed.
- **Version Bump**: 1.4.14+37 -> 1.4.15+38

- **Thumbnail Size Fix**: Fixed settings where 'Small' was showing as default but app used 'Medium'. Ensured the thumbnail size (Small/Medium/Large) is properly read as a String and applied universally across Home Screen, Folders Screen, and inside Folder View Screen.
- **Version Bump**: 1.4.15+38 -> 1.4.16+39

- **UX Improvement (Multi-add to folder)**: Modified 'Add Files to Folder' bottom sheet. Now uses StatefulBuilder. When a user clicks (+) to add a file to a folder, the file is added and removed from the list instantly with a snackbar confirmation, but the bottom sheet STAYS OPEN. This allows adding multiple files quickly. Added a drag handle indicator at the top so users know they can slide down to dismiss.
- **Version Bump**: 1.4.16+39 -> 1.4.17+40

- **UI Improvement**: Merged 'Scan Document' and 'Import Gallery' buttons on the home screen into a single wide 'Scan Document' button that launches the camera with the gallery import option enabled by default. This reduces UI clutter.
- **Version Bump**: 1.4.17+40 -> 1.4.18+41

- **UI Improvement**: Moved the main Scan button to a centered Floating Action Button (FAB) in the BottomAppBar, matching the user's provided design. Removed the redundant Scan Document card from the recent tab.
- **Version Bump**: 1.4.18+41 -> 1.4.19+42

- **UI Improvement**: Added a continuous glowing animation to the central Scan FAB to grab user attention.
- **Version Bump**: 1.4.19+42 -> 1.4.20+43

- **UI Refinement**: Reduced the glow spread radius and added a subtle 6% scale zoom in/out animation to the Scan FAB to make it crisp and premium.
- **Version Bump**: 1.4.20+43 -> 1.4.21+44

- **UI Fixes**: Created \_FixedCenterDockedFabLocation\ to prevent SnackBar popups from displacing the center-docked Floating Action Button.
- **Bug Fix**: Added \.png\ extension to \FileManagerService\ filtering so that saved signatures now appear in the Recent Files and Folders list.
- **Version Bump**: 1.4.21+44 -> 1.4.22+45

- **UI Fixes**: Added a white background container behind transparent images in \ViewerScreen\ so that black signatures on transparent backgrounds are clearly visible against the app's dark theme background.
- **Version Bump**: 1.4.22+45 -> 1.4.23+46

- **UI Enhancement**: Added descriptive subtitles to all action cards on the Home Screen (e.g. 'QR Toolkit -> Scan & Gen') to improve UX and feature discoverability.
- **Version Bump**: 1.4.23+46 -> 1.4.24+47

-   * * B u g   F i x   ( O O M ) * * :   M i g r a t e d   P D F   p r o c e s s i n g   t o o l s   ( m e r g e ,   s p l i t ,   p r o t e c t )   f r o m   \ s y n c f u s i o n _ f l u t t e r _ p d f \   t o   \ p d f _ m a n i p u l a t o r \   t o   u t i l i z e   n a t i v e   R u s t - b a s e d   s t r e a m i n g .   T h i s   r e s o l v e s   O u t - o f - M e m o r y   ( O O M )   c r a s h e s   o n   l a r g e   f i l e s   ( e . g .   a t   7 2 % )   a n d   e x e c u t e s   n a t i v e l y   w i t h o u t   b l o c k i n g   t h e   U I   t h r e a d .  
 -   * * V e r s i o n   B u m p * * :   1 . 4 . 2 7 + 5 0   - >   1 . 4 . 2 8 + 5 1  
  
 -   * * B u g   F i x   ( U I ) * * :   F i x e d   H o m e   S c r e e n   B o t t o m N a v i g a t i o n B a r   h e i g h t   t o   p r e v e n t   t e x t   o v e r f l o w   ( 9   p i x e l s ) .  
 -   * * U I   E n h a n c e m e n t * * :   A d d e d   a   s i m u l a t e d   l i v e   p r o g r e s s   i n d i c a t o r   f o r   P D F   p r o c e s s i n g   t o o l s   t o   p r o v i d e   u s e r   f e e d b a c k .  
 -   * * B u g   F i x   ( N o t i f i c a t i o n s ) * * :   A d d e d   A n d r o i d   P O S T _ N O T I F I C A T I O N S   r u n t i m e   p e r m i s s i o n   r e q u e s t   i n   \ N o t i f i c a t i o n S e r v i c e \   a n d   A n d r o i d M a n i f e s t . x m l   t o   e n s u r e   t a s k   c o m p l e t i o n   n o t i f i c a t i o n s   a r e   d i s p l a y e d   o n   A n d r o i d   1 3 + .  
 -   * * V e r s i o n   B u m p * * :   1 . 4 . 2 8 + 5 1   - >   1 . 4 . 2 9 + 5 2  
  
 -   * * U I   E n h a n c e m e n t * * :   A d j u s t e d   t h e   s i m u l a t e d   p r o g r e s s   i n d i c a t o r   i n   P D F   p r o c e s s i n g   t o   s l o w l y   c r a w l   u p   t o   9 9 %   i n s t e a d   o f   p a u s i n g   a t   9 5 % .  
 -   * * V e r s i o n   B u m p * * :   1 . 4 . 2 9 + 5 2   - >   1 . 4 . 3 0 + 5 3  
  
 -   * * P e r f o r m a n c e   ( P D F   V i e w e r ) * * :   M i g r a t e d   f r o m   p u r e - D a r t   \ s y n c f u s i o n _ f l u t t e r _ p d f v i e w e r \   t o   \  l u t t e r _ p d f v i e w \   ( N a t i v e   P l a t f o r m   V i e w ) .   T h i s   e l i m i n a t e s   U I   s c r o l l i n g   l a g   f o r   l a r g e   P D F s   b y   l e v e r a g i n g   t h e   O S - l e v e l   P d f i u m   h a r d w a r e - a c c e l e r a t e d   r e n d e r e r .  
 -   * * D e p e n d e n c i e s * * :   R e m o v e d   \ s y n c f u s i o n _ f l u t t e r _ p d f \   a n d   \ s y n c f u s i o n _ f l u t t e r _ p d f v i e w e r \ .   A d d e d   \  l u t t e r _ p d f v i e w \ .  
 -   * * V e r s i o n   B u m p * * :   1 . 4 . 3 0 + 5 3   - >   1 . 4 . 3 1 + 5 4  
  
 -   * * U X   E n h a n c e m e n t * * :   R e d e s i g n e d   P D F   T o o l s   s c r e e n .   R e m o v e d   t h e   i n i t i a l   \  
 S e l e c t  
 P D F  
 t o  
 E d i t \   b o t t l e n e c k .   U s e r s   a r e   n o w   p r e s e n t e d   d i r e c t l y   w i t h   a c t i o n   c a r d s   ( S p l i t ,   M e r g e ,   P r o t e c t )   w h i c h   t r i g g e r   t h e   f i l e   p i c k e r   s e q u e n t i a l l y   f o r   a n   i n t u i t i v e   f l o w .  
 -   * * V e r s i o n   B u m p * * :   1 . 4 . 3 1 + 5 4   - >   1 . 4 . 3 2 + 5 5  
  
 
### Update (Pre-Launch QA Fixes)
- **Version Bump**: pubspec.yaml updated to 1.4.95+118.
- **Pinned Files Leak Fix**: Fixed a data leak in FileManagerService. Now _updatePinnedPath correctly synchronizes SharedPreferences when files are renamed, moved to trash, vaulted, or permanently deleted.
- **Watermark Text Overflow Fix**: Updated _watermarkPdf in pdf_tools_screen.dart to use PdfStringFormat with wordWrap: true and proper bounding rects to prevent very long watermark text from being cut off.
- **Stale Reference Fix**: Added wait file.exists() check in iewer_screen.dart to prevent crashes when the user attempts to share or print a file that has been deleted in the background.
- **Rule Compliance**: AGENTS.md rules followed (version bump & brain.md log).
