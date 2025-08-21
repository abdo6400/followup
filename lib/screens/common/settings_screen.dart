import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showNotifications = prefs.getBool('showNotifications') ?? true;
    });
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(languageProvider.translate('settings'))),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(languageProvider.translate('darkMode')),
            subtitle: Text(languageProvider.translate('enableDarkTheme')),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (bool value) async {
                await themeProvider.toggleTheme();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(languageProvider.translate('notifications')),
            subtitle: Text(languageProvider.translate('enableNotifications')),
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
            title: Text(languageProvider.translate('language')),
            subtitle: Text(
              _getLanguageName(languageProvider.locale.languageCode),
            ),
            onTap: () => _showLanguageDialog(languageProvider),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(languageProvider.translate('autoBackup')),
            subtitle: Text(languageProvider.translate('enableAutoBackup')),
            trailing: Switch(
              value: false, // TODO: Implement backup functionality
              onChanged: (bool value) async {
                await _saveSetting('autoBackup', value);
                setState(() {});
                // TODO: Implement auto backup
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(languageProvider.translate('restoreData')),
            subtitle: Text(languageProvider.translate('restoreFromBackup')),
            onTap: () {
              // TODO: Implement data restore
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(languageProvider.translate('comingSoon')),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(languageProvider.translate('about')),
            onTap: () => _showAboutDialog(languageProvider),
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

  Future<void> _showLanguageDialog(LanguageProvider languageProvider) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(languageProvider.translate('selectLanguage')),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'en'),
              child: Text(languageProvider.translate('english')),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'ar'),
              child: Text(languageProvider.translate('arabic')),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await languageProvider.setLocale(result);
    }
  }

  void _showAboutDialog(LanguageProvider languageProvider) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(languageProvider.translate('about')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languageProvider.translate('appName'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(languageProvider.translate('version') + ': 1.0.0'),
              const SizedBox(height: 8),
              Text(languageProvider.translate('appDescription')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(languageProvider.translate('close')),
            ),
          ],
        );
      },
    );
  }
}
