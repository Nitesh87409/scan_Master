import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class ScannerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  // Scans document and saves PDF/JPG to app directory
  Future<List<String>> scanDocument({bool isGalleryImport = false}) async {
    try {
      final DocumentScannerOptions options = DocumentScannerOptions(
        documentFormats: const {DocumentFormat.pdf, DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: 100,
        isGalleryImport: isGalleryImport,
      );
      
      final documentScanner = DocumentScanner(options: options);
      final result = await documentScanner.scanDocument();
      
      if (result == null) return [];
      
      final outputDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      List<String> savedFiles = [];
      
      print('=== SCAN RESULT ===');
      print('PDF: ${result.pdf?.uri}');
      print('IMAGES: ${result.images}');
      print('===================');
      
      // Save Images first so PDF appears at the top
      if (result.images != null) {
        for (int i = 0; i < result.images!.length; i++) {
           try {
             final imgFile = File(result.images![i]);
             final newPath = '${outputDir.path}/scan_${timestamp}_$i.jpg';
             await imgFile.copy(newPath);
             savedFiles.add(newPath);
           } catch(e) {
             print('FAILED TO COPY JPG: $e');
           }
        }
      }

      // Save PDF last so it has the newest modified timestamp
      if (result.pdf != null) {
         try {
           final String pdfUri = result.pdf!.uri;
           final String pdfPath = pdfUri.startsWith('file://') ? Uri.parse(pdfUri).toFilePath() : pdfUri;
           final pdfFile = File(pdfPath);
           final newPath = '${outputDir.path}/scan_$timestamp.pdf';
           await pdfFile.copy(newPath);
           savedFiles.add(newPath);
         } catch(e) {
           throw Exception('FAILED TO COPY PDF: $e. URI was: ${result.pdf!.uri}');
         }
      } else if (result.images != null && result.images!.isNotEmpty) {
         // FALLBACK: ML Kit didn't return a PDF, generate it manually!
         try {
           final pdf = pw.Document();
           for (final imgPath in result.images!) {
             final image = pw.MemoryImage(File(imgPath).readAsBytesSync());
             pdf.addPage(
               pw.Page(
                 build: (pw.Context context) {
                   return pw.Center(child: pw.Image(image));
                 },
               ),
             );
           }
           final newPath = '${outputDir.path}/scan_$timestamp.pdf';
           final file = File(newPath);
           await file.writeAsBytes(await pdf.save());
           savedFiles.add(newPath);
         } catch (e) {
           throw Exception('FAILED TO MANUALLY GENERATE PDF: $e');
         }
      }
      
      return savedFiles;
    } catch (e) {
      throw Exception('Error during document scanning: $e');
    }
  }
}
