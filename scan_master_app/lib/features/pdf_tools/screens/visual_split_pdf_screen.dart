import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pdf_manipulator/io.dart';

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

  // CHANGED: single int → Set of multiple split points
  final Set<int> _splitPoints = {};

  String _progressText = "";

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    // NOTE: this was already missing dispose for _document/_thumbnails
    // in an earlier bug report — make sure this stays in place.
    for (final img in _thumbnails.values) {
      img.dispose();
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

  // CHANGED: now creates N+1 parts based on however many split points are selected
  Future<void> _executeSplit() async {
    if (_document == null || _splitPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one split point.')),
      );
      return;
    }

    setState(() {
      _isSplitting = true;
      _progressText = "Splitting PDF...";
    });

    final List<String> createdPaths = [];

    try {
      final pdf = Pdf();
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sourceBytes = await widget.file.readAsBytes();
      final totalPages = _document!.pages.length;

      // Sorted split points + the last page index, so we always close out the final part
      final sortedPoints = _splitPoints.toList()..sort();
      final boundaries = [...sortedPoints, totalPages - 1];

      int startPage = 0;
      int partNumber = 1;

      for (final splitAfter in boundaries) {
        final source = MemorySource(sourceBytes); // fresh source per part
        final path = '${outputDir.path}/scan_split${partNumber}_$timestamp.pdf';
        final sink = await FileSink.create(File(path));

        final pageCount = splitAfter - startPage + 1;
        final pages = List.generate(pageCount, (i) => startPage + i);

        await pdf.extractPages(source, sink, pages: pages);
        await sink.close();

        createdPaths.add(path);
        startPage = splitAfter + 1;
        partNumber++;
      }

      await pdf.dispose();

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      // Clean up any partially-created files on failure
      for (final path in createdPaths) {
        try {
          final f = File(path);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
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
        title: Text('Split PDF'),
        actions: [
          // CHANGED: shows how many parts will be created
          if (!_isLoading && _splitPoints.isNotEmpty)
            TextButton.icon(
              onPressed: _isSplitting ? null : _executeSplit,
              icon: Icon(Icons.check),
              label: Text('${_splitPoints.length + 1} parts'),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                          Text('Selected File:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(fileName, style: TextStyle(fontSize: 14)),
                          SizedBox(height: 8),
                          // CHANGED: updated instructions text
                          Text(
                            'Tap on a page to mark a split point AFTER it. Tap multiple pages to split into more than 2 parts.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
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
                          // CHANGED: check membership in the Set instead of equality with single int
                          final isSelected = _splitPoints.contains(index);
                          final isLastPage = index == _document!.pages.length - 1;

                          return GestureDetector(
                            // CHANGED: toggle add/remove instead of overwrite
                            onTap: isLastPage
                                ? null
                                : () {
                                    setState(() {
                                      if (_splitPoints.contains(index)) {
                                        _splitPoints.remove(index);
                                      } else {
                                        _splitPoints.add(index);
                                      }
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
                                            : Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                                        child: Icon(Icons.content_cut, color: Colors.white, size: 20),
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
                              SizedBox(height: 16),
                              Text(_progressText, style: TextStyle(fontWeight: FontWeight.bold)),
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
