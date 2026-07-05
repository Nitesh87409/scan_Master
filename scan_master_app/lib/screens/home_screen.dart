import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'dart:typed_data';
import '../constants/document_filters.dart';
import '../services/scanner_service.dart';
import '../services/file_manager_service.dart';
import '../services/ad_service.dart';
import '../ocr/ocr_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/file_manager_service.dart';
import 'viewer_screen.dart';
import '../widgets/file_thumbnail.dart';
import '../utils/file_options_helper.dart';
import '../utils/file_filter_util.dart';
import 'folders_screen.dart';
import 'trash_screen.dart';
import '../widgets/file_filter_bar.dart';
import 'settings_screen.dart';
import 'signature_screen.dart';
import 'qr_toolkit_screen.dart';
import '../core/animations.dart';
import 'qr_toolkit_screen.dart';
import 'pdf_tools_screen.dart';
import '../constants/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileManagerService _fileManager = FileManagerService();
  final ScannerService _scannerService = ScannerService();
  List<FileSystemEntity> _recentFiles = [];
  bool _isLoading = true;
  double _thumbnailSize = 80.0;
  FileFilterType _currentFilter = FileFilterType.all;
  int _currentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    if (_recentFiles.isEmpty) setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final sizePref = prefs.getString('thumbnail_size') ?? 'Small';
    if (sizePref == 'Small') _thumbnailSize = 50.0;
    else if (sizePref == 'Large') _thumbnailSize = 120.0;
    else _thumbnailSize = 80.0;

    final newFiles = await _fileManager.getRecentFiles();
    
    if (mounted) {
      setState(() {
        _recentFiles = newFiles;
        _isLoading = false;
      });
    }
  }

  Future<void> _startScan({bool isGallery = false}) async {
    try {
      final files = await _scannerService.scanDocument(isGalleryImport: isGallery);
      if (files.isNotEmpty) {
        _loadFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved ${files.length} file(s)')),
          );
        }
        // Show Interstitial Ad after a successful scan/save
        AdService.showInterstitialAd();
      }
    } catch (e) {
      if (e.toString().contains('Operation cancelled')) {
        return; // User just backed out of the scanner, not an actual error.
      }
      
      if (mounted) {
        AppAnimations.showPremiumDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Scan Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // old file options removed

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _currentIndex != 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                )
              : null,
          title: const Text('Scan Master', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: AppStrings.titleTrashBin,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TrashScreen()),
                ).then((_) => _loadFiles());
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ).then((_) => _loadFiles());
              },
            ),
          ],
        ),
      body: Column(
        children: [
          Expanded(
            child: _currentIndex == 0 ? _buildRecentTab() : const FoldersScreen(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  AppStrings.badgePrivacy,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
      floatingActionButton: _GlowingScanButton(
        onPressed: () => _startScan(isGallery: true),
      ),
      floatingActionButtonLocation: const _FixedCenterDockedFabLocation(),
      bottomNavigationBar: BottomAppBar(
        height: 58,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(
              icon: Icons.home_filled,
              label: 'Home',
              index: 0,
            ),
            const SizedBox(width: 48), // Space for FAB
            _buildTabItem(
              icon: Icons.folder,
              label: 'Folders',
              index: 1,
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildTabItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        if (index == 0) {
          _loadFiles();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.purple : Colors.grey.shade600,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.purple : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    List<FileSystemEntity> filteredFiles = _searchQuery.isEmpty 
        ? _recentFiles 
        : _recentFiles.where((f) => f.path.split(Platform.pathSeparator).last.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    filteredFiles = FileFilterUtil.filterFiles(filteredFiles, _currentFilter);

    return RefreshIndicator(
        onRefresh: _loadFiles,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Search documents...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_searchQuery.isEmpty) ...[
                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'Signature',
                        'Draw & Save',
                        Icons.draw,
                        Colors.orangeAccent,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignatureScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'QR Toolkit',
                        'Scan & Gen',
                        Icons.qr_code,
                        Colors.teal,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const QrToolkitScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'OCR Text',
                        'Extract Text',
                        Icons.text_fields,
                        Colors.indigo,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OcrScreen()),
                          ).then((_) => AdService.showInterstitialAd());
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'PDF Tools',
                        'Merge & Split',
                        Icons.picture_as_pdf,
                        Colors.redAccent,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PdfToolsScreen()),
                          ).then((value) {
                            if (value == true) _loadFiles();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        AppStrings.protectPdfTitle,
                        AppStrings.addPassword,
                        Icons.lock,
                        Colors.deepPurple,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PdfToolsScreen(initialMode: 'protect')),
                          ).then((value) {
                            if (value == true) _loadFiles();
                          });
                        },
                        isPremium: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: const SizedBox(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              Text(
                _searchQuery.isEmpty ? 'Recent Files' : 'Search Results',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Filter Chips
              FileFilterBar(
                currentFilter: _currentFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _currentFilter = filter;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      _isLoading
          ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
          : filteredFiles.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No files found', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                )
              : SliverList.builder(
                  itemCount: filteredFiles.length,
                  itemBuilder: (context, index) {
                    final file = filteredFiles[index];
                    final fileName = file.path.split(Platform.pathSeparator).last;
                    return RepaintBoundary(
                      child: Dismissible(
                        key: Key(file.path),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          final messenger = ScaffoldMessenger.of(context);
                          final trashPath = await _fileManager.moveToTrash(file.path);
                          _loadFiles();
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
                                    _loadFiles();
                                  },
                                ),
                              ),
                            );
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) messenger.hideCurrentSnackBar();
                            });
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
                                    onPressed: () => FileOptionsHelper.showFileOptions(
                                      context: context,
                                      file: file,
                                      fileManager: _fileManager,
                                      onFileChanged: _loadFiles,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ],
  ));
}

Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {bool isPremium = false}) {
  return GestureDetector(
    onTap: onTap,
    child: Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (isPremium)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.workspace_premium, size: 16, color: Colors.white),
            ),
          ),
      ],
    ),
  );
}

}

class _GlowingScanButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _GlowingScanButton({required this.onPressed});

  @override
  State<_GlowingScanButton> createState() => _GlowingScanButtonState();
}

class _GlowingScanButtonState extends State<_GlowingScanButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_animation.value * 0.06),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 10 + (_animation.value * 6),
                  spreadRadius: 2 + (_animation.value * 3),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: FloatingActionButton(
        heroTag: 'home_screen_fab',
        onPressed: widget.onPressed,
        backgroundColor: Colors.purple,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: const Icon(Icons.document_scanner, color: Colors.white, size: 28),
      ),
    );
  }
}


class _FixedCenterDockedFabLocation extends FloatingActionButtonLocation {
  const _FixedCenterDockedFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height - 58.0 - (scaffoldGeometry.floatingActionButtonSize.height / 2.0) + 15.0; // 58 is bottom app bar height
    return Offset(fabX, fabY);
  }
}




