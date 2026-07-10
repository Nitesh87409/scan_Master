import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class _PdfRasterQueue {
  static final List<Function> _queue = [];
  static bool _isProcessing = false;

  static Future<T> enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _queue.add(() async {
      try {
        completer.complete(await task());
      } catch (e) {
        completer.completeError(e);
      }
    });
    _processNext();
    return completer.future;
  }

  static void _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;
    final task = _queue.removeAt(0);
    await task();
    _isProcessing = false;
    _processNext();
  }
}

class FileThumbnail extends StatefulWidget {
  final FileSystemEntity file;
  final double size;

  const FileThumbnail({super.key, required this.file, this.size = 50.0});

  @override
  State<FileThumbnail> createState() => _FileThumbnailState();
}

class _FileThumbnailState extends State<FileThumbnail> {
  late Future<Widget?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    if (widget.file.path.toLowerCase().endsWith('.pdf')) {
      _thumbnailFuture = _getOrGenerateThumbnailWidget();
    }
  }

  @override
  void didUpdateWidget(FileThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path && widget.file.path.toLowerCase().endsWith('.pdf')) {
      _thumbnailFuture = _getOrGenerateThumbnailWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.file.path.toLowerCase().endsWith('.pdf');

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: isPdf ? _buildPdfThumbnail() : _buildImageThumbnail(),
    );
  }

  Widget _buildImageThumbnail() {
    final extension = widget.file.path.split('.').last.toUpperCase();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(widget.file.path),
          fit: BoxFit.cover,
          cacheWidth: 250,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.grey),
        ),
        _buildBadge(extension == 'JPG' ? 'JPEG' : extension, Colors.blue),
      ],
    );
  }


  static Future<bool> _isPdfEncrypted(String path) async {
    try {
      final file = File(path);
      final raf = await file.open(mode: FileMode.read);
      final length = await raf.length();
      
      final firstRead = length > 4096 ? 4096 : length;
      final firstBytes = await raf.read(firstRead);
      if (String.fromCharCodes(firstBytes).contains('/Encrypt')) {
        await raf.close();
        return true;
      }
      
      if (length > 4096) {
        await raf.setPosition(length - 4096);
        final lastBytes = await raf.read(4096);
        if (String.fromCharCodes(lastBytes).contains('/Encrypt')) {
          await raf.close();
          return true;
        }
      }
      await raf.close();
      return false;
    } catch (e) {
      return false;
    }
  }

  Widget _buildPdfThumbnail() {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<Widget?>(
          future: _thumbnailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            if (snapshot.hasData) {
              return Container(
                color: Colors.white,
                child: snapshot.data!,
              );
            }
            return Icon(Icons.picture_as_pdf, color: Colors.redAccent);
          },
        ),
        _buildBadge('PDF', Colors.redAccent),
      ],
    );
  }

  Future<Widget?> _getOrGenerateThumbnailWidget() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/thumbnails');
      if (!await cacheDir.exists()) {
        await cacheDir.create();
      }

      final cacheFile = File('${cacheDir.path}/${widget.file.path.hashCode}.png');
      
      if (await cacheFile.exists()) {
        return Image.file(cacheFile, fit: BoxFit.cover, cacheWidth: 250);
      }

      if (await _isPdfEncrypted(widget.file.path)) {
        return Center(
          child: Icon(Icons.lock, color: Colors.redAccent, size: 24),
        );
      }

      return await _PdfRasterQueue.enqueue(() async {
        final bytes = await File(widget.file.path).readAsBytes();
        final raster = await Printing.raster(bytes, pages: [0], dpi: 36).first;
        final pngBytes = await raster.toPng();
        
        await cacheFile.writeAsBytes(pngBytes);
        return Image.memory(pngBytes, fit: BoxFit.cover, cacheWidth: 250);
      });
    } catch (e) {
      return null;
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}


