import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../services/file_manager_service.dart';
import '../services/auth_service.dart';
import '../core/animations.dart';
import '../constants/app_strings.dart';
import '../constants/document_filters.dart';
import '../screens/viewer_screen.dart';
import '../screens/pdf_tools_screen.dart';

class FileOptionsHelper {
  static bool _isShowing = false;

  static Future<void> showFileOptions({
    required BuildContext context,
    required FileSystemEntity file,
    required FileManagerService fileManager,
    required VoidCallback onFileChanged,
    Future<void> Function()? onRemoveFromFolder,
  }) async {
    if (_isShowing) return;
    _isShowing = true;

    final isPdf = file.path.toLowerCase().endsWith('.pdf');
    final isPinned = await fileManager.isPinned(file.path);
    
    if (!context.mounted) {
      _isShowing = false;
      return;
    }

    await AppAnimations.showPremiumBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new, color: Colors.green),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewerScreen(file: file)),
                  );
                },
              ),
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.purple),
                title: Text(isPinned ? 'Unpin' : 'Pin to Top'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  await fileManager.togglePin(file.path);
                  onFileChanged();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _renameFile(context, file, fileManager, onFileChanged);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move, color: Colors.indigo),
                title: const Text(AppStrings.actionMoveToFolder),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _moveToFolder(context, file, fileManager, onFileChanged);
                },
              ),
              if (onRemoveFromFolder != null)
                ListTile(
                  leading: const Icon(Icons.outbox, color: Colors.orange),
                  title: const Text('Remove from Folder'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await onRemoveFromFolder();
                  },
                ),
              if (!isPdf)
                ListTile(
                  leading: const Icon(Icons.save_alt, color: Colors.purple),
                  title: const Text('Save to Gallery'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    try {
                      final hasAccess = await Gal.hasAccess();
                      if (!hasAccess) await Gal.requestAccess();
                      await Gal.putImage(file.path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to Gallery!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save: $e')),
                        );
                      }
                    }
                  },
                ),
              if (isPdf)
                ListTile(
                  leading: const Icon(Icons.build, color: Colors.teal),
                  title: const Text('PDF Tools'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfToolsScreen(initialFile: file),
                      ),
                    ).then((value) {
                      if (value == true) onFileChanged();
                    });
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.build, color: Colors.teal),
                  title: const Text('Edit Image'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _editImage(context, file, onFileChanged);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Share.shareXFiles([XFile(file.path)], text: 'Shared from Scan Master');
                },
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.deepPurple),
                title: const Text('Move to Vault'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final authenticated = await AuthService.authenticate();
                  if (authenticated) {
                    await fileManager.moveToVault(file.path);
                    onFileChanged();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Moved to Secure Vault')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(AppStrings.actionTrash),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final messenger = ScaffoldMessenger.of(context);
                  final trashPath = await fileManager.moveToTrash(file.path);
                  onFileChanged();
                  if (context.mounted && trashPath != null) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text(AppStrings.msgMovedToTrash),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: AppStrings.actionUndo,
                          onPressed: () async {
                            await fileManager.restoreFromTrash(trashPath);
                            onFileChanged();
                          },
                        ),
                      ),
                    );
                    Future.delayed(const Duration(seconds: 2), () {
                      if (context.mounted) messenger.hideCurrentSnackBar();
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    _isShowing = false;
  }

  static Future<void> _renameFile(
    BuildContext context, 
    FileSystemEntity file, 
    FileManagerService fileManager, 
    VoidCallback onFileChanged
  ) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
    final controller = TextEditingController(text: nameWithoutExt);
    
    final newName = await AppAnimations.showPremiumDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New file name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Rename')),
        ],
      ),
    );
    controller.dispose();

    if (newName != null && newName.isNotEmpty && newName != nameWithoutExt) {
      try {
        final newFilePath = await fileManager.renameFile(file.path, newName);
        if (newFilePath != null) {
          onFileChanged();
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to rename file.')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File already exists')),
          );
        }
      }
    }
  }

  static Future<void> _moveToFolder(
    BuildContext context, 
    FileSystemEntity file, 
    FileManagerService fileManager, 
    VoidCallback onFileChanged
  ) async {
    final folders = await fileManager.getFolders();
    
    if (folders.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No folders available. Create a folder first in the Folders tab.')),
        );
      }
      return;
    }

    if (context.mounted) {
      final selectedFolder = await AppAnimations.showPremiumDialog<Directory>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Select Folder'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                final folderName = folder.path.split(Platform.pathSeparator).last;
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.amber),
                  title: Text(folderName),
                  onTap: () => Navigator.pop(dialogContext, folder),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.btnCancel),
            ),
          ],
        ),
      );

      if (selectedFolder != null) {
        final success = await fileManager.moveFileToFolder(file.path, selectedFolder.path);
        if (success) {
          onFileChanged();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Moved to ${selectedFolder.path.split(Platform.pathSeparator).last}')),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to move file')),
            );
          }
        }
      }
    }
  }

  static Future<void> _editImage(
    BuildContext context, 
    FileSystemEntity file, 
    VoidCallback onFileChanged
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (editorContext) => ProImageEditor.file(
          File(file.path),
          configs: ProImageEditorConfigs(
            filterEditor: FilterEditorConfigs(
              filterList: DocumentFilters.getFilters(),
            ),
          ),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              try {
                final originalFile = File(file.path);
                await originalFile.writeAsBytes(bytes);
                onFileChanged();
                if (editorContext.mounted) {
                  Navigator.pop(editorContext);
                  ScaffoldMessenger.of(editorContext).showSnackBar(
                    const SnackBar(content: Text('Image saved successfully!')),
                  );
                }
              } catch (e) {
                if (editorContext.mounted) {
                  ScaffoldMessenger.of(editorContext).showSnackBar(
                    SnackBar(content: Text('Error saving image: $e')),
                  );
                }
              }
            },
            onCloseEditor: (customArg1, [customArg2]) {
              Navigator.pop(editorContext);
            },
          ),
        ),
      ),
    );
  }
}
