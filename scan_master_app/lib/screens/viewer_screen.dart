import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_strings.dart';
import 'organize_pages_screen.dart';

class ViewerScreen extends StatefulWidget {
  final FileSystemEntity file;

  const ViewerScreen({super.key, required this.file});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  bool _isPopping = false;
  late bool _isPdf;
  late String _fileName;
  
  bool _isReady = false;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final file = File(widget.file.path);
    _isPdf = widget.file.path.toLowerCase().endsWith('.pdf') || _checkIfPdf(file);
    _fileName = widget.file.path.split(Platform.pathSeparator).last;
    if (_isPdf && !_fileName.toLowerCase().endsWith('.pdf')) {
      _fileName += '.pdf';
    }
  }

  bool _checkIfPdf(File file) {
    RandomAccessFile? raf;
    try {
      raf = file.openSync(mode: FileMode.read);
      final bytes = raf.readSync(5);
      // '%PDF-' is [37, 80, 68, 70, 45]
      if (bytes.length >= 5 &&
          bytes[0] == 37 &&
          bytes[1] == 80 &&
          bytes[2] == 68 &&
          bytes[3] == 70 &&
          bytes[4] == 45) {
        return true;
      }
    } catch (e) {
      debugPrint('Error checking file header: $e');
    } finally {
      try {
        raf?.closeSync();
      } catch (_) {}
    }
    return false;
  }

  Future<void> _handleMenuAction(String action) async {
    final file = File(widget.file.path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found. It may have been deleted.')),
        );
        Navigator.pop(context);
      }
      return;
    }
    
    switch (action) {
      case 'share':
        await Share.shareXFiles([XFile(file.path)]);
        break;
      case 'open_with':
        await OpenFilex.open(file.path);
        break;
      case 'print':
        if (_isPdf) {
          await Printing.layoutPdf(
            onLayout: (_) => file.readAsBytesSync(),
            name: _fileName,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.printPdfOnly)),
          );
        }
        break;
      case 'download':
        try {
          final bytes = await file.readAsBytes();
          String? savePath = await FilePicker.platform.saveFile(
            dialogTitle: AppStrings.actionSaveToDevice,
            fileName: _fileName,
            bytes: bytes,
          );
          if (savePath != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${AppStrings.saveSuccess}$savePath')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppStrings.saveFailed}$e')),
            );
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_fileName, style: const TextStyle(fontSize: 16, color: Colors.white)),
            if (_isPdf && _totalPages > 0)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: _buildAppBarActions(),
      ),
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (_isPopping) return;
          if (mounted) {
            setState(() {
              _isPopping = true;
            });
            await Future.delayed(const Duration(milliseconds: 10));
            if (mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                SystemNavigator.pop();
              }
            }
          }
        },
        child: _isPopping
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SizedBox.expand(
                child: _isPdf
                    ? Stack(
                        children: [
                          PdfViewer.file(
                            widget.file.path,
                            passwordProvider: () => _showPasswordDialog(),
                            params: PdfViewerParams(
                              margin: 16.0,
                              pageDropShadow: null,
                              backgroundColor: Colors.black,
                              layoutPages: (pages, params) {
                                final height = pages.fold(0.0, (prev, page) => prev + page.height.ceilToDouble() + params.margin);
                                final width = pages.fold(0.0, (prev, page) => max(prev, page.width.ceilToDouble()));
                                final pageLayouts = <Rect>[];
                                double y = params.margin / 2;
                                for (final page in pages) {
                                  pageLayouts.add(Rect.fromLTWH(
                                    ((width - page.width) / 2).floorToDouble(),
                                    y.floorToDouble(),
                                    page.width.ceilToDouble(),
                                    page.height.ceilToDouble(),
                                  ));
                                  y += page.height.ceilToDouble() + params.margin;
                                }
                                return PdfPageLayout(pageLayouts: pageLayouts, documentSize: Size(width, height));
                              },
                              errorBannerBuilder: (context, error, stackTrace, documentRef) {
                                if (error.toString().contains('No password supplied')) {
                                  Future.microtask(() {
                                    if (mounted) Navigator.of(context).pop();
                                  });
                                  return const SizedBox.shrink();
                                }
                                return Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(24),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Failed to load PDF',
                                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'The document might be corrupted or in an unsupported format.\n\nError details: ${error.toString().split('\n').first}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              onViewerReady: (document, controller) {
                                if (!mounted) return;
                                setState(() {
                                  _totalPages = document.pages.length;
                                  _isReady = true;
                                });
                              },
                              onPageChanged: (pageNumber) {
                                if (pageNumber != null) {
                                  if (!mounted) return;
                                  setState(() {
                                    _currentPage = pageNumber - 1; // 0-indexed in our UI
                                  });
                                }
                              },
                            ),
                          ),
                          if (!_isReady)
                            const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                        ],
                      )
                    : InteractiveViewer(
                        child: Center(
                          child: Container(
                            color: Colors.white,
                            child: Image.file(File(widget.file.path), cacheWidth: 2000),
                          ),
                        ),
                      ),
              ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (_isPdf)
        IconButton(
          icon: const Icon(Icons.grid_view, color: Colors.white),
          tooltip: 'Organize Pages',
          onPressed: () async {
            final newPath = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrganizePagesScreen(file: File(widget.file.path)),
              ),
            );
            if (newPath != null && newPath is String && mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ViewerScreen(file: File(newPath))),
              );
            }
          },
        ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: _handleMenuAction,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        popUpAnimationStyle: AnimationStyle(
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 250),
        ),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            value: 'share',
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _isPdf ? AppStrings.actionShareDocument : AppStrings.actionShareImage,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ),
          PopupMenuItem(
            value: 'open_with',
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _isPdf ? AppStrings.actionOpenFile : AppStrings.actionOpenImage,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ),
          PopupMenuItem(
            value: 'download',
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                _isPdf ? AppStrings.actionSaveToDevice : AppStrings.actionSaveImage,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
          ),
          if (_isPdf)
            const PopupMenuItem(
              value: 'print',
              height: 48,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  AppStrings.actionPrintPdf,
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    ];
  }

  Future<String?> _showPasswordDialog() async {
    String? password;
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Password Required'),
          content: TextField(
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter PDF Password',
            ),
            onChanged: (val) => password = val,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back from viewer screen too
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
    return password;
  }
}
