import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:pdf_manipulator/io.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../constants/app_strings.dart';

class OrganizePagesScreen extends StatefulWidget {
  final File file;
  const OrganizePagesScreen({super.key, required this.file});

  @override
  State<OrganizePagesScreen> createState() => _OrganizePagesScreenState();
}

class _OrganizePagesScreenState extends State<OrganizePagesScreen> {
  PdfDocument? _document;
  List<int> _pageOrder = [];
  final Map<int, ui.Image> _thumbnails = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _progressText = "";

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      _document = await PdfDocument.openFile(widget.file.path);
      _pageOrder = List.generate(_document!.pages.length, (index) => index);
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
      // Render at a small scale for thumbnail
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

  Future<void> _saveReorderedPdf() async {
    if (_document == null || _pageOrder.isEmpty) return;
    setState(() {
      _isSaving = true;
      _progressText = "Saving new page order...";
    });

    try {
      final pdf = Pdf();
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final sourceBytes = await widget.file.readAsBytes();
      final source = MemorySource(sourceBytes);

      final finalOutputPath = '${outputDir.path}/Reordered_$timestamp.pdf';
      final outSink = await FileSink.create(File(finalOutputPath));
      
      // The native Rust backend supports rearranging pages by passing them in the desired order
      await pdf.extractPages(
        source,
        outSink,
        pages: _pageOrder,
      );
      
      await outSink.close();
      await pdf.dispose();

      if (mounted) {
        Navigator.pop(context, finalOutputPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  void dispose() {
    for (final image in _thumbnails.values) {
      image.dispose();
    }
    _document?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pre-calculate positions to avoid O(n^2) indexOf lookup in the loop
    final Map<int, int> pagePositions = {};
    for (int i = 0; i < _pageOrder.length; i++) {
      pagePositions[_pageOrder[i]] = i;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Organize Pages', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ReorderableGridView.count(
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        final element = _pageOrder.removeAt(oldIndex);
                        _pageOrder.insert(newIndex, element);
                      });
                    },
                    children: _pageOrder.map((pageIndex) {
                      return Card(
                        key: ValueKey(pageIndex),
                        color: Colors.grey[900],
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_thumbnails[pageIndex] != null)
                              RawImage(image: _thumbnails[pageIndex]!, fit: BoxFit.cover)
                            else
                              const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '${pagePositions[pageIndex]! + 1}', // Display current visual sequence number
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            _progressText,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _isSaving || _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saveReorderedPdf,
              backgroundColor: Colors.white,
              icon: const Icon(Icons.save, color: Colors.black),
              label: const Text('Save Order', style: TextStyle(color: Colors.black)),
            ),
    );
  }
}
