import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileManagerService {
  String _sanitizeName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').replaceAll('..', '').trim();
  }

  Future<List<String>> getPinnedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('pinned_files') ?? [];
  }

  Future<Directory> getVaultFolder() async {
    final rootDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${rootDir.path}/.Vault');
    if (!(await vaultDir.exists())) {
      await vaultDir.create();
    }
    return vaultDir;
  }

  Future<void> togglePin(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinned = prefs.getStringList('pinned_files') ?? [];
    if (pinned.contains(path)) {
      pinned.remove(path);
    } else {
      pinned.add(path);
    }
    await prefs.setStringList('pinned_files', pinned);
  }

  Future<void> _updatePinnedPath(String oldPath, [String? newPath]) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinned = prefs.getStringList('pinned_files') ?? [];
    if (pinned.contains(oldPath)) {
      pinned.remove(oldPath);
      if (newPath != null) {
        pinned.add(newPath);
      }
      await prefs.setStringList('pinned_files', pinned);
    }
  }

  Future<bool> isPinned(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pinned = prefs.getStringList('pinned_files') ?? [];
    return pinned.contains(path);
  }
  Future<List<FileSystemEntity>> _getSortedFilesAsync(Directory dir, {bool Function(FileSystemEntity)? filter, int? maxDays}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pinnedPaths = prefs.getStringList('pinned_files') ?? [];

    final List<FileSystemEntity> files = await dir.list().toList();
    
    final List<(FileSystemEntity, FileStat, bool)> filesWithStats = [];
    await Future.wait(files.map((file) async {
      if (filter != null && !filter(file)) return;
      try {
        final stat = await file.stat();
        if (maxDays != null) {
          final now = DateTime.now();
          if (now.difference(stat.modified).inDays > maxDays) return;
        }
        final isPinned = pinnedPaths.contains(file.path);
        filesWithStats.add((file, stat, isPinned));
      } catch (e) {
        // Skip files that can't be stat-ed
      }
    }));
    
    filesWithStats.sort((a, b) {
      if (a.$3 && !b.$3) return -1;
      if (!a.$3 && b.$3) return 1;
      return b.$2.modified.compareTo(a.$2.modified);
    });
    return filesWithStats.map((f) => f.$1).toList();
  }

  Future<List<FileSystemEntity>> getRecentFiles({int days = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return await _getSortedFilesAsync(directory, filter: (file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.pdf') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.zip') || path.endsWith('.txt');
      }, maxDays: days);
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }

  Future<List<FileSystemEntity>> getRootFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return await _getSortedFilesAsync(directory, filter: (file) {
        final path = file.path.toLowerCase();
        return path.endsWith('.pdf') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.zip') || path.endsWith('.txt');
      });
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
      await _updatePinnedPath(path, null);
    } catch (e) {
      print('Error deleting permanently: $e');
    }
  }

  Future<String> _getUniqueFilePath(String targetDir, String fileName) async {
    String name = fileName;
    String ext = '';
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1 && !fileName.startsWith('TRASH_DIR')) {
      name = fileName.substring(0, lastDotIndex);
      ext = fileName.substring(lastDotIndex);
    }
    int counter = 1;
    String newFileName = fileName;
    while (await File('$targetDir/$newFileName').exists() || await Directory('$targetDir/$newFileName').exists()) {
      newFileName = '$name ($counter)$ext';
      counter++;
    }
    return '$targetDir/$newFileName';
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
        final uniquePath = await _getUniqueFilePath(trashDir.path, trashFileName);
        final newFile = await file.rename(uniquePath);
        await _updatePinnedPath(filePath, null); // Remove pin when trashed
        return newFile.path;
      }
    } catch (e) {
      print('Error moving to trash: $e');
    }
    return null;
  }

  Future<String?> moveToVault(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final vaultDir = await getVaultFolder();
        final fileName = file.path.split(Platform.pathSeparator).last;
        final uniquePath = await _getUniqueFilePath(vaultDir.path, fileName);
        final newFile = await file.rename(uniquePath);
        await _updatePinnedPath(filePath, null); // Remove pin when vaulted
        return newFile.path;
      }
    } catch (e) {
      print('Error moving to vault: $e');
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
        final uniquePath = await _getUniqueFilePath(trashDir.path, trashFolderName);
        final newDir = await dir.rename(uniquePath);
        return newDir.path;
      }
    } catch (e) {
      print('Error moving folder to trash: $e');
    }
    return null;
  }

  Future<String?> renameFile(String path, String newName) async {
    try {
      newName = _sanitizeName(newName);
      if (newName.isEmpty) return null;
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
        await _updatePinnedPath(path, newFile.path); // Update pin to new path
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
      folderName = _sanitizeName(folderName);
      if (folderName.isEmpty) return null;
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
      newName = _sanitizeName(newName);
      if (newName.isEmpty) return null;
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
        return await _getSortedFilesAsync(directory, filter: (file) {
          final path = file.path.toLowerCase();
          return path.endsWith('.pdf') || path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png') || path.endsWith('.zip') || path.endsWith('.txt');
        });
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
        final uniquePath = await _getUniqueFilePath(folderPath, fileName);
        final newFile = await file.rename(uniquePath);
        await _updatePinnedPath(filePath, newFile.path);
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
        final uniquePath = await _getUniqueFilePath(directory.path, fileName);
        final newFile = await file.rename(uniquePath);
        await _updatePinnedPath(filePath, newFile.path);
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
      return await _getSortedFilesAsync(trashFolder, filter: (file) {
        return file is File || file is Directory;
      });
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
