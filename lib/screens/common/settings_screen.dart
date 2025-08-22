import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/auto_backup_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showNotifications = prefs.getBool('showNotifications') ?? true;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final themeMode = ref.watch(themeProvider);
    final t = ref.watch(translationProvider);
    final autoBackupNotifier = ref.read(autoBackupProvider.notifier);
    final isAutoBackupEnabled = ref.watch(autoBackupProvider);
    final currentLocale = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('settings'))),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(t('darkMode')),
            subtitle: Text(t('enableDarkTheme')),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (bool value) async {
                await themeNotifier.toggleTheme();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(t('notifications')),
            subtitle: Text(t('enableNotifications')),
            trailing: Switch(
              value: _showNotifications,
              onChanged: (bool value) async {
                setState(() => _showNotifications = value);
                await _saveSetting('showNotifications', value);
                // TODO: Update notification settings
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t('language')),
            subtitle: Text(
              _getLanguageName(currentLocale.languageCode),
            ),
            onTap: () => _showLanguageDialog(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(t('autoBackup')),
            subtitle: Text(t('enableAutoBackup')),
            trailing: Switch(
              value: isAutoBackupEnabled,
              onChanged: (bool value) async {
                await autoBackupNotifier.toggleAutoBackup();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(t('restoreData')),
            subtitle: Text(t('restoreFromBackup')),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('comingSoon'))),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(t('about')),
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  Future<void> _showLanguageDialog() async {
    final t = ref.read(translationProvider);
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(t('selectLanguage')),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'en'),
              child: Text(t('english')),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'ar'),
              child: Text(t('arabic')),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await ref.read(languageProvider.notifier).setLocale(result);
    }
  }

  void _showAboutDialog() {
    final t = ref.read(translationProvider);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('about')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('appName'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('${t('version')}: 1.0.0'),
              const SizedBox(height: 8),
              Text(t('appDescription')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t('close')),
            ),
          ],
        );
      },
    );
  }
}
