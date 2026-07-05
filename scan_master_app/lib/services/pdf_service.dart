import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  
  // Convert a single image to PDF
  Future<String?> imageToPdf(String imagePath, String outputFileName) async {
    try {
      final pdf = pw.Document();
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage),
            );
          },
        ),
      );

      final outputDir = await getApplicationDocumentsDirectory();
      final outputFile = File('${outputDir.path}/$outputFileName.pdf');
      await outputFile.writeAsBytes(await pdf.save());

      return outputFile.path;
    } catch (e) {
      return null;
    }
  }

}
