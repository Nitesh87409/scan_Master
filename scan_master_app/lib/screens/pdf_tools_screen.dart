import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:printing/printing.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:archive/archive_io.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'viewer_screen.dart';
import '../widgets/file_thumbnail.dart';
import '../utils/file_options_helper.dart';
import '../utils/file_filter_util.dart';
import 'visual_split_pdf_screen.dart';
import '../core/animations.dart';
import '../constants/app_strings.dart';
import '../main.dart'; // import for rootScaffoldMessengerKey
import '../services/notification_service.dart';

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
  String _progressMessage = AppStrings.loading;
  
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
        title: AppStrings.notificationTitle, 
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
      _finishTask(AppStrings.splitSuccess, filePath: null); // The split screen handles output paths, so we just show general success.
    }
  }

  Future<void> _startMergeProcess() async {
    if (_selectedFile == null || _mergeFile2 == null) return;
    
    setState(() {
      _isCancelled = false;
      _isProcessing = true;
      _progressMessage = AppStrings.mergingPdfs;
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
      
      _finishTask(AppStrings.mergeSuccess, filePath: mergedFilePath);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false, reason: 'Merge PDF failed');
      _finishTask(AppStrings.mergeSuccess, error: e.toString());
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
                  Text(AppStrings.compressOptionsTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('${AppStrings.compressCurrentSize} ${currentSizeMB.toStringAsFixed(2)} MB',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  Text(AppStrings.compressQuickPresets,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(AppStrings.compressLowLabel),
                        selected: selectedMode == CompressMode.low,
                        onSelected: (_) =>
                            setModalState(() => selectedMode = CompressMode.low),
                      ),
                      ChoiceChip(
                        label: Text(AppStrings.compressMediumLabel),
                        selected: selectedMode == CompressMode.medium,
                        onSelected: (_) =>
                            setModalState(() => selectedMode = CompressMode.medium),
                      ),
                      ChoiceChip(
                        label: Text(AppStrings.compressHighLabel),
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
                      Text(AppStrings.compressTargetSizeLabel),
                    ],
                  ),
                  if (selectedMode == CompressMode.targetSize)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, bottom: 12),
                      child: TextField(
                        controller: targetMBController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: AppStrings.compressTargetSizeHint,
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
                      Text(AppStrings.compressReduceByLabel),
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
                  const SizedBox(height: 16),
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
                      child: Text(AppStrings.compressButtonLabel),
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
        _finishTask(AppStrings.compressInvalidTarget,
            error: AppStrings.compressInvalidTargetMsg);
        return;
      }
      if (config.targetMB! >= originalMB) {
        _finishTask(AppStrings.compressNotNeeded,
            error:
                'File is already smaller than your target (${originalMB.toStringAsFixed(2)} MB)');
        return;
      }
    }

    setState(() {
      _isCancelled = false;
      _isProcessing = true;
      _progressMessage = AppStrings.compressingPdf;
    });
    _startSimulatedProgress();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputDir = await getApplicationDocumentsDirectory();

    // Quality ladder per mode
    List<int> qualityLadder;
    switch (config.mode) {
      case CompressMode.low:
        qualityLadder = [20];
        break;
      case CompressMode.medium:
        qualityLadder = [45];
        break;
      case CompressMode.high:
        qualityLadder = [70];
        break;
      case CompressMode.targetSize:
      case CompressMode.targetPercent:
        qualityLadder = [70, 55, 40, 25, 15];
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
      for (final q in qualityLadder) {
        if (_isCancelled) break;

        final attemptPath =
            '${outputDir.path}/scan_compressed_${timestamp}_q$q.pdf';

        final pdf = Pdf();
        final outSink = await FileSink.create(File(attemptPath));
        try {
          await pdf.compress(
            FileSource(_selectedFile!),
            outSink,
            imageQuality: q,
          );
        } finally {
          await outSink.close();
          await pdf.dispose();
        }

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
        _finishTask(AppStrings.compressFailed,
            error: AppStrings.compressAlreadyOptimized);
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
      _finishTask(AppStrings.compressFailed, error: e.toString());
    }
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
        title: const Text(AppStrings.watermarkPdfTitle),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter watermark text',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, textController.text), 
            child: const Text('Add Watermark')
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
        title: const Text(AppStrings.protectPdf),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selected File: $fileName', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Enter Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, passwordController.text), child: const Text('Encrypt')),
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
      
      _finishTask(AppStrings.protectSuccess, filePath: protectedFilePath);
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, fatal: false, reason: 'Protect PDF failed');
      _finishTask(AppStrings.protectSuccess, error: e.toString());
    }
  }
  
  Widget _buildFileCard(File file, VoidCallback onChange, String label) {
    return Card(
      color: Colors.redAccent.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
            const SizedBox(height: 8),
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(
              file.path.split(Platform.pathSeparator).last,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: onChange,
              child: const Text('Change File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFileCard(String label, VoidCallback onTap) {
    return Card(
      color: Colors.grey.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.upload_file, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                label, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
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
          title: Text(widget.initialMode == 'protect' ? AppStrings.protectPdfTitle : AppStrings.pdfToolsTitle),
        ),
        body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (widget.initialFile != null && !_isMergeMode) ...[
                  _buildFileCard(_selectedFile!, () {}, AppStrings.selectedPdf),
                  const SizedBox(height: 32),
                  const Text(AppStrings.selectAnAction, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  if (widget.initialMode != 'protect') ...[
                    ElevatedButton.icon(
                      onPressed: _splitPdf,
                      icon: const Icon(Icons.call_split),
                      label: const Text(AppStrings.splitPdf),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isMergeMode = true;
                        });
                      },
                      icon: const Icon(Icons.merge_type),
                      label: const Text(AppStrings.mergePdf),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: _compressPdf,
                    icon: const Icon(Icons.compress),
                    label: const Text(AppStrings.compressPdf),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _exportToImages,
                    icon: const Icon(Icons.image),
                    label: const Text(AppStrings.exportImagesTitle),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _exportToText,
                    icon: const Icon(Icons.text_snippet),
                    label: const Text(AppStrings.exportTextTitle),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _watermarkPdf,
                    icon: const Icon(Icons.branding_watermark),
                    label: const Text(AppStrings.watermarkPdfTitle),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _protectPdf,
                    icon: const Icon(Icons.lock),
                    label: const Text(AppStrings.protectPdf),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ] else if (!_isMergeMode) ...[
                  const SizedBox(height: 16),
                  if (widget.initialMode == 'protect') ...[
                    const Icon(Icons.lock_outline, size: 64, color: Colors.deepPurple),
                    const SizedBox(height: 16),
                    const Text(AppStrings.protectPdf, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(AppStrings.descProtectPdf, style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _pickFile(isFile2: false);
                        if (_selectedFile != null) {
                          await _protectPdf();
                          if (mounted) setState(() => _selectedFile = null);
                        }
                      },
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Select PDF to Encrypt'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ] else ...[
                    const Text(AppStrings.whatWouldYouLikeToDo, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    _buildActionCard(
                      icon: Icons.call_split,
                      title: AppStrings.splitPdf,
                      description: AppStrings.descSplitPdf,
                      onTap: () async {
                        await _pickFile(isFile2: false);
                        if (_selectedFile != null) {
                          await _splitPdf();
                          if (mounted) setState(() => _selectedFile = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      icon: Icons.merge_type,
                      title: AppStrings.mergePdf,
                      description: AppStrings.descMergePdf,
                      onTap: () {
                        setState(() {
                          _selectedFile = null;
                          _mergeFile2 = null;
                          _isMergeMode = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      icon: Icons.compress,
                      title: AppStrings.compressPdfTitle,
                      description: AppStrings.descCompressPdf,
                      onTap: () async {
                        await _pickFile(isFile2: false);
                        if (_selectedFile != null) {
                          await _compressPdf();
                          if (mounted) setState(() => _selectedFile = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      icon: Icons.image,
                      title: AppStrings.exportImagesTitle,
                      description: AppStrings.descExportImages,
                      onTap: () async {
                        await _pickFile(isFile2: false);
                        if (_selectedFile != null) {
                          await _exportToImages();
                          if (mounted) setState(() => _selectedFile = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      icon: Icons.text_snippet,
                      title: AppStrings.exportTextTitle,
                      description: AppStrings.descExportText,
                      onTap: () async {
                        await _pickFile(isFile2: false);
                        if (_selectedFile != null) {
                          await _exportToText();
                          if (mounted) setState(() => _selectedFile = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      icon: Icons.branding_watermark,
                      title: AppStrings.watermarkPdfTitle,
                      description: AppStrings.descWatermarkPdf,
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
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setState(() {
                          _isMergeMode = false;
                          if (widget.initialFile == null) _selectedFile = null;
                        }),
                      ),
                      const Text('Merge Setup', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedFile != null)
                    _buildFileCard(_selectedFile!, () => _pickFile(isFile2: false), 'File 1')
                  else
                    _buildEmptyFileCard('Select File 1', () => _pickFile(isFile2: false)),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: Icon(Icons.add, size: 32, color: Colors.grey)),
                  ),
                  
                  if (_mergeFile2 != null)
                    _buildFileCard(_mergeFile2!, () => _pickFile(isFile2: true), 'File 2')
                  else
                    _buildEmptyFileCard('Select File 2', () => _pickFile(isFile2: true)),
                    
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: (_selectedFile == null || _mergeFile2 == null) ? null : _startMergeProcess,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Merge'),
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
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  value: _progressValue,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              Text(
                                '${(_progressValue * 100).toInt()}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Processing...',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _progressMessage,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            AppStrings.processingBackground,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _cancelProcess,
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ));
  }
}
