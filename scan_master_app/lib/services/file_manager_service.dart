import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileManagerService {
  Future<List<FileSystemEntity>> getRecentFiles({int days = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();
      
      final now = DateTime.now();
      final validFiles = files.where((file) {
        if (!(file.path.endsWith('.pdf') || file.path.endsWith('.jpg') || file.path.endsWith('.jpeg') || file.path.endsWith('.png'))) {
          return false;
        }
        final stat = file.statSync();
        return now.difference(stat.modified).inDays <= days;
      }).toList();
      
      validFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return validFiles;
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }

  Future<List<FileSystemEntity>> getRootFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = directory.listSync();
      
      final validFiles = files.where((file) {
        return file.path.endsWith('.pdf') || file.path.endsWith('.jpg') || file.path.endsWith('.jpeg') || file.path.endsWith('.png');
      }).toList();
      
      validFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return validFiles;
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }

  Future<void> deletePermanently(String path) async {
    try {
      FileSystemEntity entity;
      if (await File(path).exists()) {
        entity = File(path);
      } else if (await Directory(path).exists()) {
        entity = Directory(path);
      } else {
        return;
      }
      await entity.delete(recursive: true);
    } catch (e) {
      print('Error deleting permanently: $e');
    }
  }

  Future<String?> moveToTrash(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final trashDir = await getTrashFolder();
        final rootDir = await getApplicationDocumentsDirectory();
        final parentDir = file.parent;
        
        String locationPrefix = 'ROOT';
        if (parentDir.path != rootDir.path && parentDir.path != trashDir.path) {
          locationPrefix = parentDir.path.split(Platform.pathSeparator).last;
        }

        final fileName = file.path.split(Platform.pathSeparator).last;
        final trashFileName = 'TRASH__${locationPrefix}__$fileName';
        final newFile = await file.rename('${trashDir.path}/$trashFileName');
        return newFile.path;
      }
    } catch (e) {
      print('Error moving to trash: $e');
    }
    return null;
  }

  Future<String?> moveFolderToTrash(String folderPath) async {
    try {
      final dir = Directory(folderPath);
      if (await dir.exists()) {
        final trashDir = await getTrashFolder();
        final folderName = dir.path.split(Platform.pathSeparator).last;
        final trashFolderName = 'TRASH_DIR__ROOT__$folderName';
        final newDir = await dir.rename('${trashDir.path}/$trashFolderName');
        return newDir.path;
      }
    } catch (e) {
      print('Error moving folder to trash: $e');
    }
    return null;
  }

  Future<String?> renameFile(String path, String newName) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final dir = file.parent.path;
        final ext = file.path.split('.').last;
        final newPath = '$dir/$newName.$ext';
        
        // Check for duplicates case-insensitively
        final parentDir = Directory(dir);
        final siblings = parentDir.listSync();
        for (final entity in siblings) {
          if (entity is File && entity.path.split(Platform.pathSeparator).last.toLowerCase() == '$newName.$ext'.toLowerCase()) {
            throw Exception('already_exists');
          }
        }
        
        final newFile = await file.rename(newPath);
        return newFile.path;
      }
      return null;
    } catch (e) {
      if (e.toString().contains('already_exists')) rethrow;
      print('Error renaming file: $e');
      return null;
    }
  }

  // --- Folder Management ---

  Future<List<Directory>> getFolders() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> entities = directory.listSync();
      
      final folders = entities
          .whereType<Directory>()
          .where((dir) => !dir.path.split(Platform.pathSeparator).last.startsWith('.'))
          .toList();
      // Sort folders alphabetically
      folders.sort((a, b) => a.path.split(Platform.pathSeparator).last.toLowerCase()
          .compareTo(b.path.split(Platform.pathSeparator).last.toLowerCase()));
      return folders;
    } catch (e) {
      print('Error getting folders: $e');
      return [];
    }
  }

  Future<Directory?> createFolder(String folderName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      // Case-insensitive check
      final existingEntities = directory.listSync();
      for (final entity in existingEntities) {
        if (entity is Directory && entity.path.split(Platform.pathSeparator).last.toLowerCase() == folderName.toLowerCase()) {
          throw Exception('already_exists');
        }
      }

      final folder = Directory('${directory.path}/$folderName');
      if (!(await folder.exists())) {
        return await folder.create();
      }
      return folder;
    } catch (e) {
      if (e.toString().contains('already_exists')) rethrow;
      print('Error creating folder: $e');
      return null;
    }
  }

  Future<Directory?> renameFolder(String folderPath, String newName) async {
    try {
      final folder = Directory(folderPath);
      if (await folder.exists()) {
        final parentDir = folder.parent;
        
        // Case-insensitive check
        final existingEntities = parentDir.listSync();
        for (final entity in existingEntities) {
          if (entity is Directory && entity.path.split(Platform.pathSeparator).last.toLowerCase() == newName.toLowerCase()) {
            throw Exception('already_exists');
          }
        }

        final newPath = '${parentDir.path}/$newName';
        final newFolder = await folder.rename(newPath);
        return Directory(newFolder.path);
      }
      return null;
    } catch (e) {
      if (e.toString().contains('already_exists')) rethrow;
      print('Error renaming folder: $e');
      return null;
    }
  }

  Future<List<FileSystemEntity>> getFilesInFolder(String folderPath) async {
    try {
      final directory = Directory(folderPath);
      if (await directory.exists()) {
        final List<FileSystemEntity> files = directory.listSync();
        final validFiles = files.where((file) {
          return file.path.endsWith('.pdf') || file.path.endsWith('.jpg') || file.path.endsWith('.jpeg') || file.path.endsWith('.png');
        }).toList();
        validFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        return validFiles;
      }
      return [];
    } catch (e) {
      print('Error getting files in folder: $e');
      return [];
    }
  }

  Future<bool> moveFileToFolder(String filePath, String folderPath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        await file.rename('$folderPath/$fileName');
        return true;
      }
      return false;
    } catch (e) {
      print('Error moving file: $e');
      return false;
    }
  }

  Future<bool> removeFileFromFolder(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = file.path.split(Platform.pathSeparator).last;
        await file.rename('${directory.path}/$fileName');
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing file from folder: $e');
      return false;
    }
  }

  // --- Trash Management ---

  Future<Directory> getTrashFolder() async {
    final directory = await getApplicationDocumentsDirectory();
    final trashFolder = Directory('${directory.path}/.trash');
    if (!(await trashFolder.exists())) {
      await trashFolder.create();
    }
    return trashFolder;
  }

  Future<List<FileSystemEntity>> getTrashFiles() async {
    try {
      final trashFolder = await getTrashFolder();
      final List<FileSystemEntity> files = trashFolder.listSync();
      // Only include files and directories, but not the parent directory link if any
      final validFiles = files.where((file) => file is File || file is Directory).toList();
      validFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return validFiles;
    } catch (e) {
      print('Error getting trash files: $e');
      return [];
    }
  }

  Future<bool> restoreFromTrash(String trashFilePath) async {
    try {
      FileSystemEntity entity;
      if (await File(trashFilePath).exists()) {
        entity = File(trashFilePath);
      } else if (await Directory(trashFilePath).exists()) {
        entity = Directory(trashFilePath);
      } else {
        return false;
      }

      final trashFileName = entity.path.split(Platform.pathSeparator).last;
      final rootDir = await getApplicationDocumentsDirectory();
      
      // If it's a folder, it starts with TRASH_DIR__ROOT__
      if (trashFileName.startsWith('TRASH_DIR__')) {
        final parts = trashFileName.split('__');
        if (parts.length >= 3) {
           final originalFolderName = parts.sublist(2).join('__');
           await entity.rename('${rootDir.path}/$originalFolderName');
           return true;
        }
        return false;
      }

      // Format: TRASH__<location>__<filename>
      final parts = trashFileName.split('__');
      if (parts.length >= 3) {
        final location = parts[1];
        final originalFileName = parts.sublist(2).join('__');
        
        String targetDirPath = rootDir.path;
        if (location != 'ROOT') {
          targetDirPath = '${rootDir.path}/$location';
          final targetDir = Directory(targetDirPath);
          if (!(await targetDir.exists())) {
            await targetDir.create(); // Recreate folder if it was deleted
          }
        }
        
        await entity.rename('$targetDirPath/$originalFileName');
        return true;
      }
      return false;
    } catch (e) {
      print('Error restoring file: $e');
      return false;
    }
  }

  Future<void> emptyTrash() async {
    try {
      final trashFolder = await getTrashFolder();
      if (await trashFolder.exists()) {
        final files = trashFolder.listSync();
        for (final file in files) {
          await file.delete(recursive: true);
        }
      }
    } catch (e) {
      print('Error emptying trash: $e');
    }
  }

  Future<void> cleanupTrash(int retentionDays) async {
    if (retentionDays <= 0) return; // 'Never' or disabled
    try {
      final trashFolder = await getTrashFolder();
      if (await trashFolder.exists()) {
        final files = trashFolder.listSync();
        final now = DateTime.now();
        for (final file in files) {
          final stat = file.statSync();
          final difference = now.difference(stat.modified);
          if (difference.inDays >= retentionDays) {
            await file.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      print('Error cleaning up trash: $e');
    }
  }
}
