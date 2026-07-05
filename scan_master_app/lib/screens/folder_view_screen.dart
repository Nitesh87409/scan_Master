import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../constants/document_filters.dart';
import '../utils/file_options_helper.dart';
import '../utils/file_filter_util.dart';
import '../constants/app_strings.dart';
import '../services/file_manager_service.dart';
import '../services/ad_service.dart';
import '../widgets/file_thumbnail.dart';
import '../core/animations.dart';
import 'viewer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pdf_tools_screen.dart';
import '../widgets/file_filter_bar.dart';

class FolderViewScreen extends StatefulWidget {
  final Directory folder;

  const FolderViewScreen({super.key, required this.folder});

  @override
  State<FolderViewScreen> createState() => _FolderViewScreenState();
}

class _FolderViewScreenState extends State<FolderViewScreen> {
  final FileManagerService _fileManager = FileManagerService();
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  bool _isZipping = false;
  double _thumbnailSize = 50.0;
  FileFilterType _currentFilter = FileFilterType.all;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadFiles();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final sizePref = prefs.getString('thumbnail_size') ?? 'Small';
        if (sizePref == 'Small') _thumbnailSize = 50.0;
        else if (sizePref == 'Large') _thumbnailSize = 120.0;
        else _thumbnailSize = 80.0;
      });
    }
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final files = await _fileManager.getFilesInFolder(widget.folder.path);
    if (mounted) {
      setState(() {
        _files = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _addFilesToFolder() async {
    final rootFiles = await _fileManager.getRecentFiles();
    if (!mounted) return;

    if (rootFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files available to add')),
      );
      return;
    }

    AppAnimations.showPremiumBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16).copyWith(bottom: 32),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Add Files to Folder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: rootFiles.isEmpty
                      ? const Center(child: Text('No more files to add'))
                      : ListView.builder(
                          itemCount: rootFiles.length,
                          itemBuilder: (context, index) {
                            final file = rootFiles[index];
                            final fileName = file.path.split(Platform.pathSeparator).last;
                            return ListTile(
                              leading: FileThumbnail(file: file, size: _thumbnailSize * 0.7),
                              title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: const Icon(Icons.add_circle_outline, color: Colors.blue),
                              onTap: () async {
                                final success = await _fileManager.moveFileToFolder(file.path, widget.folder.path);
                                if (success) {
                                  setModalState(() {
                                    rootFiles.removeAt(index);
                                  });
                                  _loadFiles();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Added $fileName to folder')),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareFolder() async {
    if (_files.isEmpty) return;
    
    setState(() => _isZipping = true);
    
    final folderName = widget.folder.path.split(Platform.pathSeparator).last;
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/$folderName.zip');
    
    try {
      final archive = Archive();
      for (final file in _files) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final bytes = await File(file.path).readAsBytes();
        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
      }
      
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      if (zipBytes != null) {
        await zipFile.writeAsBytes(zipBytes);
        await Share.shareXFiles([XFile(zipFile.path)], text: 'Shared $folderName from Scan Master');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share folder: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isZipping = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final folderName = widget.folder.path.split(Platform.pathSeparator).last;
    final filteredFiles = FileFilterUtil.filterFiles(_files, _currentFilter);

    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
      ),
      body: Column(
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFiles.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.insert_drive_file, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(AppStrings.msgFolderEmpty, style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
                    ],
                  ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                      itemCount: filteredFiles.length,
                      itemBuilder: (context, index) {
                        final file = filteredFiles[index];
                        final fileName = file.path.split(Platform.pathSeparator).last;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ViewerScreen(file: file)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
                                onPressed: () => FileOptionsHelper.showFileOptions(
                                  context: context,
                                  file: file,
                                  fileManager: _fileManager,
                                  onFileChanged: _loadFiles,
                                  onRemoveFromFolder: () async {
                                    final success = await _fileManager.removeFileFromFolder(file.path);
                                    if (success) {
                                      _loadFiles();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('File removed from folder')),
                                        );
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to remove file')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_files.isNotEmpty)
            FloatingActionButton.extended(
              heroTag: 'share_fab',
              onPressed: _isZipping ? null : _shareFolder,
              icon: _isZipping 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share),
              label: Text(_isZipping ? 'Zipping...' : AppStrings.btnShareFolder),
            ),
          if (_files.isNotEmpty) const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_fab',
            onPressed: _addFilesToFolder,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
