import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scan_master_app/services/file_manager_service.dart';
import 'package:scan_master_app/services/auth_service.dart';
import 'package:scan_master_app/widgets/file_thumbnail.dart';
import 'package:scan_master_app/utils/file_options_helper.dart';
import 'package:path_provider/path_provider.dart';

class VaultScreen extends StatefulWidget {
  final bool initialAuthPassed;
  const VaultScreen({Key? key, this.initialAuthPassed = false}) : super(key: key);

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final FileManagerService _fileManager = FileManagerService();
  List<FileSystemEntity> _vaultFiles = [];
  bool _isLoading = true;

  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = widget.initialAuthPassed;
    if (_isAuthenticated) {
      _loadVaultFiles();
    } else {
      _checkAuth();
    }
  }

  Future<void> _checkAuth() async {
    final auth = await AuthService.authenticate();
    if (auth) {
      if (mounted) {
        setState(() { _isAuthenticated = true; });
        _loadVaultFiles();
      }
    } else {
      if (mounted) Navigator.pop(context); // Kick user out if auth fails
    }
  }

  Future<void> _loadVaultFiles() async {
    if (!_isAuthenticated) return;
    setState(() => _isLoading = true);
    final vaultDir = await _fileManager.getVaultFolder();
    final rawFiles = vaultDir.listSync().where((f) => f is File).toList();
    
    final List<(FileSystemEntity, FileStat)> filesWithStats = [];
    for (final file in rawFiles) {
      try {
        filesWithStats.add((file, file.statSync()));
      } catch (_) {}
    }
    filesWithStats.sort((a, b) => b.$2.modified.compareTo(a.$2.modified));
    final files = filesWithStats.map((f) => f.$1).toList();
    
    if (mounted) {
      setState(() {
        _vaultFiles = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _moveToNormal(FileSystemEntity file) async {
    try {
      final mainDir = await getApplicationDocumentsDirectory();

      final fileName = file.path.split(Platform.pathSeparator).last;
      final newPath = await _fileManager.getUniqueFilePath(mainDir.path, fileName);
      await (file as File).rename(newPath);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored from Vault')),
      );
      _loadVaultFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text('Secure Vault')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Authentication required', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Vault'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _vaultFiles.isEmpty 
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Vault is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _vaultFiles.length,
              itemBuilder: (context, index) {
                final file = _vaultFiles[index];
                final fileName = file.path.split(Platform.pathSeparator).last;
                return ListTile(
                  leading: Icon(Icons.lock, color: Colors.deepPurple),
                  title: Text(fileName),
                  subtitle: Text('Protected'),
                  trailing: IconButton(
                    icon: Icon(Icons.restore),
                    tooltip: 'Remove from Vault',
                    onPressed: () => _moveToNormal(file),
                  ),
                  onTap: () {
                    // Open the file options (but don't show move to vault since it's already in vault)
                    FileOptionsHelper.showFileOptions(
                      context: context, 
                      file: file as File, 
                      fileManager: _fileManager, 
                      onFileChanged: _loadVaultFiles
                    );
                  },
                );
              },
            ),
    );
  }
}
