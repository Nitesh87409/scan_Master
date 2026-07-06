import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_strings.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = 'Loading...';
  String _thumbnailSize = 'Small'; // Default
  int _trashRetention = 30; // Default 30 days
  int _themeMode = 0; // Default System

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadPreferences();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _thumbnailSize = prefs.getString('thumbnail_size') ?? 'Small';
      _trashRetention = prefs.getInt('trash_retention_days') ?? 30;
      _themeMode = prefs.getInt('theme_mode') ?? 0;
    });
  }

  Future<void> _saveThumbnailSize(String? size) async {
    if (size == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('thumbnail_size', size);
    if (!mounted) return;
    setState(() {
      _thumbnailSize = size;
    });
  }

  Future<void> _saveTrashRetention(int? days) async {
    if (days == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trash_retention_days', days);
    if (!mounted) return;
    setState(() {
      _trashRetention = days;
    });
  }

  Future<void> _saveThemeMode(int? modeIndex) async {
    if (modeIndex == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', modeIndex);
    if (!mounted) return;
    setState(() {
      _themeMode = modeIndex;
    });
    themeNotifier.value = ThemeMode.values[modeIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('General', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Thumbnail Size'),
            subtitle: const Text('Adjust the size of recent files preview'),
            trailing: DropdownButton<String>(
              value: _thumbnailSize,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'Small', child: Text('Small')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'Large', child: Text('Large')),
              ],
              onChanged: _saveThumbnailSize,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text(AppStrings.settingTheme),
            subtitle: const Text('Change application theme'),
            trailing: DropdownButton<int>(
              value: _themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 0, child: Text(AppStrings.themeSystem)),
                DropdownMenuItem(value: 1, child: Text(AppStrings.themeLight)),
                DropdownMenuItem(value: 2, child: Text(AppStrings.themeDark)),
              ],
              onChanged: _saveThemeMode,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text(AppStrings.settingTrashRetention),
            subtitle: const Text('Automatically delete files from trash'),
            trailing: DropdownButton<int>(
              value: _trashRetention,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 Days')),
                DropdownMenuItem(value: 15, child: Text('15 Days')),
                DropdownMenuItem(value: 30, child: Text('30 Days')),
                DropdownMenuItem(value: 60, child: Text('60 Days')),
                DropdownMenuItem(value: -1, child: Text('Never')),
              ],
              onChanged: _saveTrashRetention,
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('About', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: Text(_version),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const Text(
                    'Scan Master automatically sends anonymous crash and error reports (device model, OS version, app version, and technical error details) to help us fix bugs. No document content, file names, or personal files are ever included in these reports.\n\nAll your scanned documents and files remain private and are processed locally on your device.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
