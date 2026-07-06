import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/file_manager_service.dart';
import '../constants/app_strings.dart';
import '../core/animations.dart';
import 'folder_view_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
import 'viewer_screen.dart';
import '../widgets/file_thumbnail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/file_options_helper.dart';
import '../utils/file_filter_util.dart';
import '../widgets/file_filter_bar.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FileManagerService _fileManager = FileManagerService();
  List<Directory> _folders = [];
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  double _thumbnailSize = 80.0;
  FileFilterType _currentFilter = FileFilterType.all;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadFolders();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final sizePref = prefs.getString('thumbnail_size') ?? 'Small';
      if (sizePref == 'Small') _thumbnailSize = 50.0;
      else if (sizePref == 'Large') _thumbnailSize = 120.0;
      else _thumbnailSize = 80.0;
    });
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    final folders = await _fileManager.getFolders();
    final files = await _fileManager.getRootFiles();
    if (mounted) {
      setState(() {
        _folders = folders;
        _files = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewFolder() async {
    final controller = TextEditingController();
    final folderName = await AppAnimations.showPremiumDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Customer name or folder name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (folderName != null && folderName.trim().isNotEmpty) {
      try {
        final newFolder = await _fileManager.createFolder(folderName.trim());
        if (newFolder != null) {
          _loadFolders();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.errorCreateFolder)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder already exists')),
          );
        }
      }
    }
  }

  Future<void> _renameFolder(Directory folder) async {
    final controller = TextEditingController(text: folder.path.split(Platform.pathSeparator).last);
    final newName = await AppAnimations.showPremiumDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.actionRenameFolder),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: AppStrings.hintFolderName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text(AppStrings.btnRename),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName != null && newName.trim().isNotEmpty) {
      try {
        final renamedFolder = await _fileManager.renameFolder(folder.path, newName.trim());
        if (renamedFolder != null) {
          _loadFolders();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.msgFolderRenamed)),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.errorRenameFolder)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Folder already exists')),
          );
        }
      }
    }
  }

  Future<void> _shareFolder(Directory folder) async {
    final folderName = folder.path.split(Platform.pathSeparator).last;
    final files = folder.listSync().whereType<File>().toList();
    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder is empty')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zipping $folderName...')),
      );
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final zipFile = File('${tempDir.path}/$folderName.zip');
      
      final zipEncoder = ZipFileEncoder();
      zipEncoder.create(zipFile.path);
      for (final file in files) {
        zipEncoder.addFile(file);
      }
      zipEncoder.close();

      await Share.shareXFiles([XFile(zipFile.path)], text: 'Shared $folderName from Scan Master');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFiles = FileFilterUtil.filterFiles(_files, _currentFilter);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_folders.isEmpty && _files.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.msgNoFolders,
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a folder to organize customer documents.',
                        style: TextStyle(color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewFolder,
                        icon: const Icon(Icons.create_new_folder),
                        label: const Text('Create Folder'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFolders,
                  child: Column(
                    children: [
                      // Filter Chips
                      FileFilterBar(
                        currentFilter: _currentFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _currentFilter = filter;
                          });
                        },
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _folders.length + filteredFiles.length,
                          itemBuilder: (context, index) {
                            if (index < _folders.length) {
                        final folder = _folders[index];
                        final folderName = folder.path.split(Platform.pathSeparator).last;
                        
                        return Dismissible(
                          key: Key(folder.path),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() {
                              _folders.removeWhere((f) => f.path == folder.path);
                            });
                            _fileManager.moveFolderToTrash(folder.path).then((trashPath) {
                              _loadFolders();
                              if (mounted && trashPath != null) {
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text(AppStrings.msgFolderMovedToTrash),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: AppStrings.actionUndo,
                                      onPressed: () async {
                                        await _fileManager.restoreFromTrash(trashPath);
                                        _loadFolders();
                                      },
                                    ),
                                  ),
                                );
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) {
                                    messenger.hideCurrentSnackBar();
                                  }
                                });
                              }
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FolderViewScreen(folder: folder),
                                  ),
                                ).then((_) => _loadFolders());
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder, color: Colors.amber, size: 40),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        folderName,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) async {
                                        if (value == 'share') {
                                          _shareFolder(folder);
                                        } else if (value == 'rename') {
                                          _renameFolder(folder);
                                        } else if (value == 'delete') {
                                          final messenger = ScaffoldMessenger.of(context);
                                          final trashPath = await _fileManager.moveFolderToTrash(folder.path);
                                          _loadFolders();
                                          if (mounted && trashPath != null) {
                                            messenger.clearSnackBars();
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: const Text(AppStrings.msgFolderMovedToTrash),
                                                duration: const Duration(seconds: 2),
                                                action: SnackBarAction(
                                                  label: AppStrings.actionUndo,
                                                  onPressed: () async {
                                                    await _fileManager.restoreFromTrash(trashPath);
                                                    _loadFolders();
                                                  },
                                                ),
                                              ),
                                            );
                                            Future.delayed(const Duration(seconds: 2), () {
                                              if (mounted) {
                                                messenger.hideCurrentSnackBar();
                                              }
                                            });
                                          }
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'share',
                                          child: ListTile(
                                            leading: Icon(Icons.share, color: Colors.blue, size: 20),
                                            title: Text('Share Folder'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'rename',
                                          child: ListTile(
                                            leading: Icon(Icons.edit, size: 20),
                                            title: Text(AppStrings.actionRenameFolder),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(Icons.delete, color: Colors.red, size: 20),
                                            title: Text(
                                              AppStrings.actionTrash,
                                              style: TextStyle(color: Colors.red),
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        final file = filteredFiles[index - _folders.length];
                        final fileName = file.path.split(Platform.pathSeparator).last;
                        
                        return Dismissible(
                          key: Key(file.path),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() {
                              _files.removeWhere((f) => f.path == file.path);
                            });
                            _fileManager.moveToTrash(file.path).then((trashPath) {
                              _loadFolders();
                              if (mounted && trashPath != null) {
                                messenger.clearSnackBars();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text(AppStrings.msgMovedToTrash),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: AppStrings.actionUndo,
                                      onPressed: () async {
                                        await _fileManager.restoreFromTrash(trashPath);
                                        _loadFolders();
                                      },
                                    ),
                                  ),
                                );
                                Future.delayed(const Duration(seconds: 2), () {
                                  if (mounted) messenger.hideCurrentSnackBar();
                                });
                              }
                            });
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ViewerScreen(file: file)),
                                ).then((_) => _loadFolders());
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    FileThumbnail(file: file, size: _thumbnailSize),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        FileOptionsHelper.showFileOptions(
                                          context: context,
                                          file: file,
                                          fileManager: _fileManager,
                                          onFileChanged: _loadFolders,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'folders_screen_fab',
        onPressed: _createNewFolder,
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }
}
