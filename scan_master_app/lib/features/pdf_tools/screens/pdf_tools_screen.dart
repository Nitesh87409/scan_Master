import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:printing/printing.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:archive/archive_io.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:image/image.dart' as img;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:scan_master_app/features/viewer/screens/viewer_screen.dart';
import 'package:scan_master_app/widgets/file_thumbnail.dart';
import 'package:scan_master_app/utils/file_options_helper.dart';
import 'package:scan_master_app/utils/file_filter_util.dart';
import 'package:scan_master_app/features/pdf_tools/screens/visual_split_pdf_screen.dart';
import 'package:scan_master_app/core/animations.dart';
import 'package:scan_master_app/main.dart'; // import for rootScaffoldMessengerKey
import 'package:scan_master_app/services/notification_service.dart';
import 'package:scan_master_app/l10n/app_localizations.dart';
import 'package:scan_master_app/features/pdf_tools/widgets/pdf_file_cards.dart';
import 'package:scan_master_app/features/pdf_tools/widgets/pdf_action_card.dart';
import 'package:scan_master_app/features/pdf_tools/widgets/pdf_processing_overlay.dart';
import 'package:scan_master_app/services/ad_service.dart';
import 'package:scan_master_app/core/app_config.dart';


enum CompressMode { low, medium, high, targetSize, targetPercent }

class CompressionConfig {
  final CompressMode mode;
  final double? targetMB;
  final int? targetPercent;
  CompressionConfig({required this.mode, this.targetMB, this.targetPercent});
}

class PdfToolsScreen extends StatefulWidget {
  final FileSystemEntity? initialFile;
  final String? initialMode;
  const PdfToolsScreen({super.key, this.initialFile, this.initialMode});

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  String _progressMessage = '';
  
  double _progressValue = 0.0;
  Timer? _progressTimer;

  // Merge mode states
  bool _isMergeMode = false;
  File? _mergeFile2;
  
  bool _isCancelled = false;

  void _cancelProcess() {
    setState(() {
      _isCancelled = true;
      _isProcessing = false;
    });
    _stopSimulatedProgress();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFile != null) {
      _selectedFile = File(widget.initialFile!.path);
    }
    // Removed auto-launch for protect mode based on user feedback
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startSimulatedProgress() {
    _progressValue = 0.0;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progressValue < 0.5) {
          _progressValue += 0.02;
        } else if (_progressValue < 0.8) {
          _progressValue += 0.01;
        } else if (_progressValue < 0.95) {
          _progressValue += 0.005;
        } else if (_progressValue < 0.99) {
          _progressValue += 0.001; // Slow crawl past 95%
        }
      });
    });
  }

  void _stopSimulatedProgress() {
    _progressTimer?.cancel();
    if (mounted) {
      setState(() {
        _progressValue = 1.0;
      });
    }
  }

  Future<void> _pickFile({bool isFile2 = false}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: !isFile2,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (isFile2) {
          _mergeFile2 = File(result.files.first.path!);
        } else {
          _selectedFile = File(result.files.first.path!);
          if (result.files.length > 1) {
            _mergeFile2 = File(result.files[1].path!);
            _isMergeMode = true;
          }
        }
      });
    }
  }
  
  void _finishTask(String successMessage, {String? error, String? filePath}) {
    _stopSimulatedProgress();
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isMergeMode = false;
        _mergeFile2 = null;
      });
      Navigator.pop(context, true); 
    }
    final notificationId = Random().nextInt(100000);
    if (error != null) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Error: $error')));
      NotificationService.showNotification(id: notificationId, title: 'Task Failed', body: 'Error: $error');
    } else {
      rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(successMessage)));
      NotificationService.showNotification(
        id: notificationId, 
        title: AppLocalizations.of(context)!.notificationTitle, 
        body: successMessage,
        payload: filePath,
      );
    }
  }

  Future<void> _splitPdf() async {
    if (_selectedFile == null) return;
    
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => VisualSplitPdfScreen(file: File(_selectedFile!.path)),
      ),
    );

    if (success == true) {
      _finishTask(AppLocalizations.of(context)!.splitSuccess, filePath: null); // The split screen handles output paths, so we just show general success.
    }
  }

  Future<void> _startMergeProcess() async {
    if (_selectedFile == null || _mergeFile2 == null) return;
    
    setState(() {
      _isCancelled = false;
      _isProcessing = true;
      _progressMessage = AppLocalizations.of(context)!.mergingPdfs;
    });
    _startSimulatedProgress();
    
    final outputDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mergedFilePath = '${outputDir.path}/scan_merged_$timestamp.pdf';
    
    try {
      final pdf = Pdf();
      final outSink = await FileSink.create(File(mergedFilePath));
      
      await pdf.merge([
        FileSource(_selectedFile!),
        FileSource(_mergeFile2!),
      ], outSink);
      await pdf.dispose();
      await outSink.close();
      
      if (_isCancelled) {
        try {
          if (await File(mergedFilePath).exists()) await File(mergedFilePath).delete();
        } catch (_) {}
        return;
      }
      
      _finishTask(AppLocalizations.of(context)!.mergeSuccess, filePath: mergedFilePath);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false, reason: 'Merge PDF failed');
      _finishTask(AppLocalizations.of(context)!.mergeSuccess, error: e.toString());
    }
  }

  Future<CompressionConfig?> _showCompressOptionsDialog(double currentSizeMB) async {
    CompressMode selectedMode = CompressMode.medium;
    final targetMBController = TextEditingController();
    double targetPercent = 50;

    return showModalBottomSheet<CompressionConfig>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.compressOptionsTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 4),
                  Text('${AppLocalizations.of(context)!.compressCurrentSize} ${currentSizeMB.toStringAsFixed(2)} MB',
                      style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.compressQuickPresets,
                      style: Theme.of(context).textTheme.labelLarge),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)!.compressLowLabel),
                        selected: selectedMode == CompressMode.low,
                        onSelected: (_) =>
                            setModalState(() => selectedMode = CompressMode.low),
                      ),
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)!.compressMediumLabel),
                        selected: selectedMode == CompressMode.medium,
                        onSelected: (_) =>
                            setModalState(() => selectedMode = CompressMode.medium),
                      ),
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)!.compressHighLabel),
                        selected: selectedMode == CompressMode.high,
                        onSelected: (_) =>
                            setModalState(() => selectedMode = CompressMode.high),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Radio<CompressMode>(
                        value: CompressMode.targetSize,
                        groupValue: selectedMode,
                        onChanged: (v) =>
                            setModalState(() => selectedMode = v!),
                      ),
                      Text(AppLocalizations.of(context)!.compressTargetSizeLabel),
                    ],
                  ),
                  if (selectedMode == CompressMode.targetSize)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, bottom: 12),
                      child: TextField(
                        controller: targetMBController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.compressTargetSizeHint,
                          suffixText: 'MB',
                          isDense: true,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Radio<CompressMode>(
                        value: CompressMode.targetPercent,
                        groupValue: selectedMode,
                        onChanged: (v) =>
                            setModalState(() => selectedMode = v!),
                      ),
                      Text(AppLocalizations.of(context)!.compressReduceByLabel),
                    ],
                  ),
                  if (selectedMode == CompressMode.targetPercent)
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: targetPercent,
                              min: 10,
                              max: 90,
                              divisions: 16,
                              label: '${targetPercent.round()}%',
                              onChanged: (v) =>
                                  setModalState(() => targetPercent = v),
                            ),
                          ),
                          Text('${targetPercent.round()}%'),
                        ],
                      ),
                    ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final config = CompressionConfig(
                          mode: selectedMode,
                          targetMB: selectedMode == CompressMode.targetSize
                              ? double.tryParse(
                                  targetMBController.text.trim())
                              : null,
                          targetPercent:
                              selectedMode == CompressMode.targetPercent
                                  ? targetPercent.round()
                                  : null,
                        );
                        Navigator.pop(context, config);
                      },
                      child: Text(AppLocalizations.of(context)!.compressButtonLabel),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => targetMBController.dispose());
  }

  Future<void> _compressPdf() async {
    if (_selectedFile == null) return;

    final originalSize = await _selectedFile!.length();
    final originalMB = originalSize / (1024 * 1024);

    // Show options dialog BEFORE entering processing state
    final config = await _showCompressOptionsDialog(originalMB);
    if (config == null) return; // user cancelled

    // Validation for target size mode
    if (config.mode == CompressMode.targetSize) {
      if (config.targetMB == null || config.targetMB! <= 0) {
        _finishTask(AppLocalizations.of(context)!.compressInvalidTarget,
            error: AppLocalizations.of(context)!.compressInvalidTargetMsg);
        return;
      }
      if (config.targetMB! >= originalMB) {
        _finishTask(AppLocalizations.of(context)!.compressNotNeeded,
            error:
                'File is already smaller than your target (${originalMB.toStringAsFixed(2)} MB)');
        return;
      }
    }

    setState(() {
      _isCancelled = false;
      _isProcessing = true;
      _progressMessage = AppLocalizations.of(context)!.compressingPdf;
    });
    _startSimulatedProgress();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputDir = await getApplicationDocumentsDirectory();

    // Two-pronged compression ladder: [quality, dpi]
    // Lower quality = more JPEG compression, Lower DPI = smaller image dimensions
    // No artificial floor — ladder goes as aggressive as needed
    List<List<int>> compressionLadder;
    switch (config.mode) {
      case CompressMode.low:
        compressionLadder = [[35, 120]]; // Aggressive quality, low DPI
        break;
      case CompressMode.medium:
        compressionLadder = [[55, 150]]; // Moderate
        break;
      case CompressMode.high:
        compressionLadder = [[75, 200]]; // Light compression
        break;
      case CompressMode.targetSize:
      case CompressMode.targetPercent:
        // Progressive ladder — quality AND resolution both decrease
        // No hardcoded floor — keeps going until target is met
        compressionLadder = [
          [70, 200],  // Step 1: Light
          [55, 170],  // Step 2: Moderate  
          [40, 140],  // Step 3: Medium
          [25, 110],  // Step 4: Aggressive
          [15, 85],   // Step 5: Very aggressive
          [10, 65],   // Step 6: Ultra (for very demanding targets)
          [8, 50],    // Step 7: Maximum compression
        ];
        break;
    }

    String? bestPath;
    int bestSize = originalSize;
    double? targetBytes;
    if (config.mode == CompressMode.targetSize) {
      targetBytes = config.targetMB! * 1024 * 1024;
    } else if (config.mode == CompressMode.targetPercent) {
      targetBytes = originalSize * (1 - config.targetPercent! / 100);
    }

    try {
      for (final step in compressionLadder) {
        if (_isCancelled) break;
        final quality = step[0];
        final dpi = step[1].toDouble();

        final attemptPath =
            '${outputDir.path}/scan_compressed_${timestamp}_q${quality}_d${step[1]}.pdf';

        try {
          // Render each PDF page to an image at the given DPI,
          // then re-encode as JPEG at the given quality,
          // and rebuild the PDF from those compressed images.
          await _compressViaImageRender(
            inputFile: _selectedFile!,
            outputPath: attemptPath,
            dpi: dpi,
            jpegQuality: quality,
          );
        } catch (e) {
          debugPrint('Compress step q=$quality d=$dpi failed: $e');
          // If image-render approach fails, try fallback quality-only for first step
          if (step == compressionLadder.first) {
            try {
              final pdf = Pdf();
              final outSink = await FileSink.create(File(attemptPath));
              try {
                await pdf.compress(
                  FileSource(_selectedFile!),
                  outSink,
                  imageQuality: quality,
                );
              } finally {
                await outSink.close();
                await pdf.dispose();
              }
            } catch (_) {
              continue;
            }
          } else {
            continue;
          }
        }

        if (!await File(attemptPath).exists()) continue;
        final attemptSize = await File(attemptPath).length();

        if (attemptSize < bestSize) {
          // Delete previous best to avoid leftover files
          if (bestPath != null) {
            try { await File(bestPath).delete(); } catch (_) {}
          }
          bestPath = attemptPath;
          bestSize = attemptSize;
        } else {
          // This attempt was worse — delete it
          try { await File(attemptPath).delete(); } catch (_) {}
        }

        // Stop early if target met
        if (targetBytes != null && bestSize <= targetBytes) break;

        // For fixed presets, one pass is enough
        if (config.mode == CompressMode.low ||
            config.mode == CompressMode.medium ||
            config.mode == CompressMode.high) break;
      }

      // Handle cancellation cleanup
      if (_isCancelled) {
        if (bestPath != null) {
          try { await File(bestPath).delete(); } catch (_) {}
        }
        setState(() => _isProcessing = false);
        _stopSimulatedProgress();
        return;
      }

      // No meaningful reduction
      final percentSaved =
          ((originalSize - bestSize) / originalSize * 100).round();
          
      if (bestPath == null || bestSize >= originalSize || percentSaved < 1) {
        if (bestPath != null) {
          try { await File(bestPath).delete(); } catch (_) {}
        }
        _finishTask(AppLocalizations.of(context)!.compressFailed,
            error: AppLocalizations.of(context)!.compressAlreadyOptimized);
        return;
      }

      final compressedMB = bestSize / (1024 * 1024);

      String resultMessage;
      if (targetBytes != null && bestSize > targetBytes) {
        resultMessage =
            'Target not fully reached.\nOriginal: ${originalMB.toStringAsFixed(2)} MB → '
            'Best possible: ${compressedMB.toStringAsFixed(2)} MB ($percentSaved% smaller)';
      } else {
        resultMessage =
            'Original: ${originalMB.toStringAsFixed(2)} MB → '
            'Compressed: ${compressedMB.toStringAsFixed(2)} MB ($percentSaved% smaller)';
      }

      _finishTask(resultMessage, filePath: bestPath);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false, reason: 'Compress PDF failed');
      if (bestPath != null) {
        try { await File(bestPath).delete(); } catch (_) {}
      }
      _finishTask(AppLocalizations.of(context)!.compressFailed, error: e.toString());
    }
  }

  /// Renders each page of [inputFile] to an image at [dpi], compresses it 
  /// as JPEG at [jpegQuality], and rebuilds a new PDF from those images.
  Future<void> _compressViaImageRender({
    required File inputFile,
    required String outputPath,
    required double dpi,
    required int jpegQuality,
  }) async {
    final pdfDoc = sf.PdfDocument();
    
    // Render each page to a raster image using the printing package
    final inputBytes = await inputFile.readAsBytes();
    final pages = Printing.raster(inputBytes, dpi: dpi);
    
    await for (final page in pages) {
      if (_isCancelled) break;
      
      // Convert rendered page to PNG, then re-encode as JPEG with actual quality
      final pngBytes = await page.toPng();
      
      // Decode PNG and re-encode as JPEG — THIS is where quality compression happens
      final decoded = img.decodePng(pngBytes);
      final jpegBytes = decoded != null
          ? Uint8List.fromList(img.encodeJpg(decoded, quality: jpegQuality))
          : pngBytes; // fallback if decode fails
      
      // Use Syncfusion to create a new page with the compressed JPEG image
      final sf.PdfPage pdfPage = pdfDoc.pages.add();
      final pageSize = pdfPage.getClientSize();
      
      final sf.PdfBitmap image = sf.PdfBitmap(jpegBytes);
      
      // Draw image to fill the entire page
      pdfPage.graphics.drawImage(
        image,
        Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
      );
    }
    
    if (_isCancelled) {
      pdfDoc.dispose();
      return;
    }

    // Save the new compressed PDF
    final bytes = await pdfDoc.save();
    pdfDoc.dispose();
    await File(outputPath).writeAsBytes(bytes);
  }

  Future<void> _exportToImages() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isCancelled = false;
      _isProcessing = true;
      _progressMessage = 'Exporting PDF to Images...';
    });
    _startSimulatedProgress();
    
    try {
      final bytes = await File(_selectedFile!.path).readAsBytes();
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final folderPath = '${outputDir.path}/temp_images_$timestamp';
      final dir = await Directory(folderPath).create(recursive: true);
      
      int pageIndex = 1;
      await for (final page in Printing.raster(bytes, dpi: 150)) {
        if (_isCancelled) {
          try {
            if (await dir.exists()) await dir.delete(recursive: true);
          } catch (_) {}
          return;
        }
        final imageFile = File('$folderPath/page_$pageIndex.png');
        await imageFile.writeAsBytes(await page.toPng());
        pageIndex++;
      }
      
      // Zip the folder
      final zipFilePath = '${outputDir.path}/scan_exported_images_$timestamp.zip';
      var encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      encoder.addDirectory(dir);
      encoder.close();
      
      // Cleanup folder
      await dir.delete(recursive: true);
      
      _finishTask('Exported $pageIndex images to ZIP', filePath: zipFilePath);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false, reason: 'Export to Images failed');
      _finishTask('Export Failed', error: e.toString());
    }
  }

  Future<void> _exportToText() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isCancelled = false;
      _isProcessing = true;
      _progressMessage = 'Extracting Text (OCR)...';
    });
    _startSimulatedProgress();
    
    TextRecognizer? textRecognizer;
    IOSink? sink;

    try {
      final bytes = await File(_selectedFile!.path).readAsBytes();
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final textFilePath = '${outputDir.path}/scan_extracted_$timestamp.txt';
      final textFile = File(textFilePath);
      sink = textFile.openWrite();
      
      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      int pageIndex = 1;
      await for (final page in Printing.raster(bytes, dpi: 150)) {
        if (_isCancelled) {
          textRecognizer.close();
          await sink.close();
          try {
            if (await textFile.exists()) await textFile.delete();
          } catch (_) {}
          return;
        }
        
        final tempImageFile = File('${outputDir.path}/temp_ocr_page_$pageIndex.png');
        await tempImageFile.writeAsBytes(await page.toPng());
        
        final inputImage = InputImage.fromFile(tempImageFile);
        final recognizedText = await textRecognizer.processImage(inputImage);
        
        sink.writeln('--- Page $pageIndex ---');
        sink.writeln(recognizedText.text);
        sink.writeln('');
        
        await tempImageFile.delete(); // cleanup
        pageIndex++;
      }
      
      textRecognizer.close();
      await sink.close();
      
      _finishTask('Text Extracted Successfully', filePath: textFilePath);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false, reason: 'Export to Text failed');
      _finishTask('Export Failed', error: e.toString());
    } finally {
      textRecognizer?.close();
      await sink?.close();
    }
  }

  Future<void> _watermarkPdf() async {
    if (_selectedFile == null) return;
    
    final textController = TextEditingController();
    final watermarkText = await AppAnimations.showPremiumDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.watermarkPdfTitle),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter watermark text',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, textController.text), 
            child: Text('Add Watermark')
          ),
        ],
      ),
    );
    textController.dispose();

    if (watermarkText == null || watermarkText.trim().isEmpty) return;

    setState(() {
      _isCancelled = false;
      _isProcessing = true;
      _progressMessage = 'Adding Watermark...';
    });
    _startSimulatedProgress();

    sf.PdfDocument? document;

    try {
      final bytes = await File(_selectedFile!.path).readAsBytes();
      document = sf.PdfDocument(inputBytes: bytes);
      
      final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 60);
      final brush = sf.PdfSolidBrush(sf.PdfColor(150, 150, 150));
      
      for (int i = 0; i < document.pages.count; i++) {
        if (_isCancelled) {
          return;
        }
        final page = document.pages[i];
        final graphics = page.graphics;
        final pageSize = page.size;
        
        graphics.save();
        graphics.setTransparency(0.25); // 25% opacity
        graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
        graphics.rotateTransform(-45);
        
        final format = sf.PdfStringFormat(
          alignment: sf.PdfTextAlignment.center,
          lineAlignment: sf.PdfVerticalAlignment.middle,
          wordWrap: sf.PdfWordWrapType.word
        );
        final maxWidth = pageSize.width * 1.2;
        
        graphics.drawString(
          watermarkText, 
          font, 
          brush: brush,
          bounds: Rect.fromLTWH(-maxWidth / 2, -pageSize.height / 2, maxWidth, pageSize.height),
          format: format
        );
        
        graphics.restore();
      }
      
      final outputBytes = await document.save();
      
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${outputDir.path}/scan_watermarked_$timestamp.pdf';
      await File(outPath).writeAsBytes(outputBytes);
      
      _finishTask('Watermark added successfully', filePath: outPath);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false, reason: 'Watermark PDF failed');
      _finishTask('Failed to add watermark', error: e.toString());
    } finally {
      document?.dispose();
    }
  }

  Future<void> _protectPdf() async {
    if (_selectedFile == null) return;
    
    final fileName = _selectedFile!.path.split(Platform.pathSeparator).last;
    
    final passwordController = TextEditingController();
    final password = await AppAnimations.showPremiumDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.protectPdf),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected File: $fileName', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Enter Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, passwordController.text), child: Text('Encrypt')),
        ],
      ),
    );
    passwordController.dispose();

    if (password == null || password.isEmpty) return;

    setState(() {
      _isCancelled = false;
      _isProcessing = true;
      _progressMessage = 'Applying AES Encryption...';
    });
    _startSimulatedProgress();

    final outputDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final protectedFilePath = '${outputDir.path}/scan_protected_$timestamp.pdf';
    
    try {
      final pdf = Pdf();
      final outSink = await FileSink.create(File(protectedFilePath));
      
      await pdf.encrypt(
         FileSource(_selectedFile!), 
         outSink, 
         encryption: PdfEncryptionConfig(ownerPassword: password, userPassword: password),
      );
      await pdf.dispose();
      await outSink.close();
      
      if (_isCancelled) {
        try {
          if (await File(protectedFilePath).exists()) await File(protectedFilePath).delete();
        } catch (_) {}
        return;
      }
      
      _finishTask(AppLocalizations.of(context)!.protectSuccess, filePath: protectedFilePath);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false, reason: 'Protect PDF failed');
      _finishTask(AppLocalizations.of(context)!.protectSuccess, error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMergeMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isMergeMode) {
          setState(() {
            _isMergeMode = false;
            if (widget.initialFile == null) _selectedFile = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initialMode == 'protect' ? AppLocalizations.of(context)!.protectPdfTitle : AppLocalizations.of(context)!.pdfToolsTitle),
        ),
        body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      if (widget.initialFile != null && !_isMergeMode) ...[
                        PdfFileCard(file: _selectedFile!, onChange: () {}, label: AppLocalizations.of(context)!.selectedPdf),
                        SizedBox(height: 32),
                        Text(AppLocalizations.of(context)!.selectAnAction, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        SizedBox(height: 16),
                        if (widget.initialMode != 'protect') ...[
                          ElevatedButton.icon(
                            onPressed: _splitPdf,
                            icon: Icon(Icons.call_split),
                            label: Text(AppLocalizations.of(context)!.splitPdf),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isMergeMode = true;
                              });
                            },
                            icon: Icon(Icons.merge_type),
                            label: Text(AppLocalizations.of(context)!.mergePdf),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                          ),
                          SizedBox(height: 12),
                        ],
                        ElevatedButton.icon(
                          onPressed: _compressPdf,
                          icon: Icon(Icons.compress),
                          label: Text(AppLocalizations.of(context)!.compressPdf),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _exportToImages,
                          icon: Icon(Icons.image),
                          label: Text(AppLocalizations.of(context)!.exportImagesTitle),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _exportToText,
                          icon: Icon(Icons.text_snippet),
                          label: Text(AppLocalizations.of(context)!.exportTextTitle),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _watermarkPdf,
                          icon: Icon(Icons.branding_watermark),
                          label: Text(AppLocalizations.of(context)!.watermarkPdfTitle),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _protectPdf,
                          icon: Icon(Icons.lock),
                          label: Text(AppLocalizations.of(context)!.protectPdf),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                        ),
                      ] else if (!_isMergeMode) ...[
                        SizedBox(height: 16),
                        if (widget.initialMode == 'protect') ...[
                          Icon(Icons.lock_outline, size: 64, color: Colors.deepPurple),
                          SizedBox(height: 16),
                          Text(AppLocalizations.of(context)!.protectPdf, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          SizedBox(height: 8),
                          Text(AppLocalizations.of(context)!.descProtectPdf, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
                          SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _pickFile(isFile2: false);
                              if (_selectedFile != null) {
                                await _protectPdf();
                                if (mounted) setState(() => _selectedFile = null);
                              }
                            },
                            icon: Icon(Icons.file_upload),
                            label: Text('Select PDF to Encrypt'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                          ),
                        ] else ...[
                          Text(AppLocalizations.of(context)!.whatWouldYouLikeToDo, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          SizedBox(height: 24),
                          PdfActionCard(
                            icon: Icons.call_split,
                            title: AppLocalizations.of(context)!.splitPdf,
                            description: AppLocalizations.of(context)!.descSplitPdf,
                            onTap: () async {
                              await _pickFile(isFile2: false);
                              if (_selectedFile != null) {
                                await _splitPdf();
                                if (mounted) setState(() => _selectedFile = null);
                              }
                            },
                          ),
                          SizedBox(height: 16),
                          PdfActionCard(
                            icon: Icons.merge_type,
                            title: AppLocalizations.of(context)!.mergePdf,
                            description: AppLocalizations.of(context)!.descMergePdf,
                            onTap: () {
                              setState(() {
                                _selectedFile = null;
                                _mergeFile2 = null;
                                _isMergeMode = true;
                              });
                            },
                          ),
                          SizedBox(height: 16),
                          PdfActionCard(
                            icon: Icons.compress,
                            title: AppLocalizations.of(context)!.compressPdfTitle,
                            description: AppLocalizations.of(context)!.descCompressPdf,
                            onTap: () async {
                              await _pickFile(isFile2: false);
                              if (_selectedFile != null) {
                                await _compressPdf();
                                if (mounted) setState(() => _selectedFile = null);
                              }
                            },
                          ),
                          SizedBox(height: 16),
                          PdfActionCard(
                            icon: Icons.image,
                            title: AppLocalizations.of(context)!.exportImagesTitle,
                            description: AppLocalizations.of(context)!.descExportImages,
                            onTap: () async {
                              await _pickFile(isFile2: false);
                              if (_selectedFile != null) {
                                await _exportToImages();
                                if (mounted) setState(() => _selectedFile = null);
                              }
                            },
                          ),
                          SizedBox(height: 16),
                          PdfActionCard(
                            icon: Icons.text_snippet,
                            title: AppLocalizations.of(context)!.exportTextTitle,
                            description: AppLocalizations.of(context)!.descExportText,
                            onTap: () async {
                              await _pickFile(isFile2: false);
                              if (_selectedFile != null) {
                                await _exportToText();
                                if (mounted) setState(() => _selectedFile = null);
                              }
                            },
                          ),
                          SizedBox(height: 16),
                          PdfActionCard(
                            icon: Icons.branding_watermark,
                            title: AppLocalizations.of(context)!.watermarkPdfTitle,
                            description: AppLocalizations.of(context)!.descWatermarkPdf,
                            onTap: () async {
                              await _pickFile(isFile2: false);
                              if (_selectedFile != null) {
                                await _watermarkPdf();
                                if (mounted) setState(() => _selectedFile = null);
                              }
                            },
                          ),
                        ],
                      ] else ...[
                        // MERGE MODE UI
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: () => setState(() {
                                _isMergeMode = false;
                                if (widget.initialFile == null) _selectedFile = null;
                              }),
                            ),
                            Text('Merge Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (_selectedFile != null)
                          PdfFileCard(file: _selectedFile!, onChange: () => _pickFile(isFile2: false), label: 'File 1')
                        else
                          PdfEmptyFileCard(label: 'Select File 1', onTap: () => _pickFile(isFile2: false)),
                        
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(child: Icon(Icons.add, size: 32, color: Colors.grey)),
                        ),
                        
                        if (_mergeFile2 != null)
                          PdfFileCard(file: _mergeFile2!, onChange: () => _pickFile(isFile2: true), label: 'File 2')
                        else
                          PdfEmptyFileCard(label: 'Select File 2', onTap: () => _pickFile(isFile2: true)),
                          
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: (_selectedFile == null || _mergeFile2 == null) ? null : _startMergeProcess,
                          icon: Icon(Icons.play_arrow),
                          label: Text('Start Merge'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(20),
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              BannerAdWidget(isEnabled: AppConfig.adsPdfToolsScreenEnabled),
            ],
          ),
          if (_isProcessing)
            PdfProcessingOverlay(
              progressValue: _progressValue,
              progressMessage: _progressMessage,
              onCancel: _cancelProcess,
            ),
        ],
      ),
    ));
  }
}
