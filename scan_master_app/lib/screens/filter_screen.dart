import 'dart:io';
import 'package:flutter/material.dart';
import '../pdf_toolkit/pdf_service.dart';

class FilterScreen extends StatelessWidget {
  final String imagePath;

  const FilterScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Document'),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.file(File(imagePath), fit: BoxFit.contain, cacheWidth: 2000),
            ),
          ),
          Container(
            color: Colors.white10,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.crop, 'Crop', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Crop feature coming soon!')),
                  );
                }),
                _buildActionButton(Icons.brightness_6, 'Filter', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters coming soon!')),
                  );
                }),
                _buildActionButton(Icons.check_circle, 'Save PDF', () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saving document...')),
                  );
                  final pdfService = PdfService();
                  final filename = 'doc_${DateTime.now().millisecondsSinceEpoch}';
                  final path = await pdfService.imageToPdf(imagePath, filename);
                  if (context.mounted && path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF saved at: $path')),
                    );
                    Navigator.pop(context); // Go back home
                  }
                }, color: Colors.blue),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
