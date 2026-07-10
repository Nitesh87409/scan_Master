import 'dart:io';
import 'package:flutter/material.dart';

class PdfFileCard extends StatelessWidget {
  final File file;
  final VoidCallback onChange;
  final String label;

  const PdfFileCard({
    super.key,
    required this.file,
    required this.onChange,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
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
}

class PdfEmptyFileCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const PdfEmptyFileCard({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
