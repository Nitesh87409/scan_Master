import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pdf_manipulator/io.dart';
import '../constants/app_strings.dart';

class VisualSplitPdfScreen extends StatefulWidget {
  final File file;

  const VisualSplitPdfScreen({super.key, required this.file});

  @override
  State<VisualSplitPdfScreen> createState() => _VisualSplitPdfScreenState();
}

class _VisualSplitPdfScreenState extends State<VisualSplitPdfScreen> {
  PdfDocument? _document;
  final Map<int, ui.Image> _thumbnails = {};
  bool _isLoading = true;
  bool _isSplitting = false;
  int _splitAfterIndex = -1;
  String _progressText = "";

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    for (final image in _thumbnails.values) {
      image.dispose();
    }
    _document?.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      _document = await PdfDocument.openFile(widget.file.path);
      setState(() => _isLoading = false);
      _generateThumbnails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading PDF: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _generateThumbnails() async {
    if (_document == null) return;
    for (int i = 0; i < _document!.pages.length; i++) {
      if (!mounted) return;
      final page = _document!.pages[i];
      final image = await page.render(
        fullWidth: page.width / 4,
        fullHeight: page.height / 4,
      );
      if (image != null) {
        ui.decodeImageFromPixels(
          image.pixels,
          image.width,
          image.height,
          ui.PixelFormat.bgra8888,
          (ui.Image uiImage) {
            if (mounted) {
              setState(() {
                _thumbnails[i] = uiImage;
              });
            }
            image.dispose();
          },
        );
      }
    }
  }

  Future<void> _executeSplit() async {
    if (_document == null || _splitAfterIndex < 0 || _splitAfterIndex >= _document!.pages.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid split point.')));
      return;
    }

    setState(() {
      _isSplitting = true;
      _progressText = "Splitting PDF...";
    });

    try {
      final pdf = Pdf();
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final sourceBytes = await widget.file.readAsBytes();
      final source = MemorySource(sourceBytes);

      // Part 1
      final path1 = '${outputDir.path}/scan_split1_$timestamp.pdf';
      final sink1 = await FileSink.create(File(path1));
      final pages1 = List.generate(_splitAfterIndex + 1, (index) => index);
      await pdf.extractPages(source, sink1, pages: pages1);
      await sink1.close();

      // Part 2
      final path2 = '${outputDir.path}/scan_split2_$timestamp.pdf';
      final sink2 = await FileSink.create(File(path2));
      final pages2 = List.generate(_document!.pages.length - (_splitAfterIndex + 1), (index) => _splitAfterIndex + 1 + index);
      await pdf.extractPages(source, sink2, pages: pages2);
      await sink2.close();

      await pdf.dispose();

      if (mounted) {
        Navigator.pop(context, true); // Success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error splitting: $e')));
        setState(() => _isSplitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split(Platform.pathSeparator).last;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF'),
        actions: [
          if (!_isLoading && _splitAfterIndex >= 0 && _splitAfterIndex < (_document?.pages.length ?? 0) - 1)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isSplitting ? null : _executeSplit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selected File:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(fileName, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 8),
                          const Text('Tap on a page to split the document AFTER it.', style: TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _document!.pages.length,
                        itemBuilder: (context, index) {
                          final hasImage = _thumbnails.containsKey(index);
                          final isSelected = index == _splitAfterIndex;
                          final isLastPage = index == _document!.pages.length - 1;
                          
                          return GestureDetector(
                            onTap: isLastPage ? null : () {
                              setState(() {
                                _splitAfterIndex = index;
                              });
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: isSelected ? Colors.redAccent : Colors.grey.shade300,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        color: isSelected ? Colors.redAccent : Colors.grey.shade200,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          'Page ${index + 1}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: hasImage
                                            ? Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: RawImage(
                                                  image: _thumbnails[index],
                                                  fit: BoxFit.contain,
                                                ),
                                              )
                                            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    right: -20,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.content_cut, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_isSplitting)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(_progressText, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
