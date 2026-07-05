import 'dart:io';

enum FileFilterType {
  all("All Files"),
  pdf("PDFs Only"),
  signature("Signatures"),
  scanned("Scanned PDFs"),
  merged("Merged PDFs"),
  split("Split PDFs"),
  protected("Protected PDFs"),
  reordered("Organized PDFs");

  final String label;
  const FileFilterType(this.label);
}

class FileFilterUtil {
  static List<FileSystemEntity> filterFiles(List<FileSystemEntity> files, FileFilterType filterType) {
    if (filterType == FileFilterType.all) return files;

    return files.where((file) {
      final name = file.path.split(Platform.pathSeparator).last.toLowerCase();
      
      switch (filterType) {
        case FileFilterType.pdf:
          return name.endsWith('.pdf');
        case FileFilterType.signature:
          return name.endsWith('.png') || name.endsWith('.jpg') || name.contains('signature');
        case FileFilterType.scanned:
          return name.contains('scan_') && 
                 !name.contains('merged') && 
                 !name.contains('split') && 
                 !name.contains('protected');
        case FileFilterType.merged:
          return name.contains('merged');
        case FileFilterType.split:
          return name.contains('split');
        case FileFilterType.protected:
          return name.contains('protected');
        case FileFilterType.reordered:
          return name.contains('reordered');
        default:
          return true;
      }
    }).toList();
  }
}
