import 'dart:io';
import 'package:flutter/material.dart';
import '../services/file_manager_service.dart';
import '../constants/app_strings.dart';
import 'package:open_filex/open_filex.dart';
import '../core/animations.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final FileManagerService _fileManager = FileManagerService();
  List<FileSystemEntity> _trashFiles = [];
  final Map<String, FileStat> _fileStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    final files = await _fileManager.getTrashFiles();
    
    // Precompute stats to avoid blocking I/O in the build method
    final Map<String, FileStat> newStats = {};
    for (final file in files) {
      newStats[file.path] = file.statSync();
    }

    if (mounted) {
      setState(() {
        _trashFiles = files;
        _fileStats.clear();
        _fileStats.addAll(newStats);
        _isLoading = false;
      });
    }
  }

  String _getOriginalName(String trashName) {
    final parts = trashName.split('__');
    if (parts.length >= 3) {
      return parts.sublist(2).join('__');
    }
    return trashName;
  }

  String _getOriginalLocation(String trashName) {
    final parts = trashName.split('__');
    if (parts.length >= 3) {
      return parts[1] == 'ROOT' ? 'Recent Tab' : 'Folder: ${parts[1]}';
    }
    return 'Unknown';
  }

  void _showFileOptions(FileSystemEntity file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    
    AppAnimations.showPremiumBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  _getOriginalName(fileName),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Original Location: ${_getOriginalLocation(fileName)}'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.green),
                title: const Text(AppStrings.actionRestore),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await _fileManager.restoreFromTrash(file.path);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.msgFileRestored)));
                    _loadTrash();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(AppStrings.actionDeletePermanently),
                onTap: () async {
                  Navigator.pop(context);
                  await _fileManager.deletePermanently(file.path);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.msgFileDeleted)));
                    _loadTrash();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _emptyTrash() async {
    final confirm = await AppAnimations.showPremiumDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.actionEmptyTrash),
        content: const Text('Are you sure you want to permanently delete all files in the trash? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.actionEmptyTrash),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _fileManager.emptyTrash();
      _loadTrash();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.titleTrashBin),
        actions: [
          if (_trashFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: _emptyTrash,
              tooltip: AppStrings.actionEmptyTrash,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashFiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(AppStrings.msgTrashEmpty, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _trashFiles.length,
                  itemBuilder: (context, index) {
                    final file = _trashFiles[index];
                    final trashFileName = file.path.split(Platform.pathSeparator).last;
                    final originalName = _getOriginalName(trashFileName);
                    final location = _getOriginalLocation(trashFileName);
                    final stat = _fileStats[file.path];
                    final daysInTrash = stat != null ? DateTime.now().difference(stat.modified).inDays : 0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(
                          file is Directory ? Icons.folder : Icons.insert_drive_file,
                          color: file is Directory ? Colors.amber : Colors.grey,
                        ),
                        title: Text(originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$location\nIn trash for $daysInTrash days'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showFileOptions(file),
                        ),
                        onTap: () {
                          if (file is File) {
                            // Allow viewing the file while in trash
                            OpenFilex.open(file.path);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cannot open a folder in the trash. Restore it first.')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
