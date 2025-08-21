import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'en';
    _locale = Locale(language);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    notifyListeners();
  }

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Student Follow-up',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'profile': 'Profile',
      'settings': 'Settings',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'notifications': 'Notifications',
      'about': 'About',
      'logout': 'Logout',
      'dashboard': 'Dashboard',
      'tasks': 'Tasks',
      'attendance': 'Attendance',
      'categories': 'Categories',
      'students': 'Students',
      'sheikhs': 'Sheikhs',
      'reports': 'Reports',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'noResults': 'No results found',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'confirm': 'Confirm',
      'selectLanguage': 'Select Language',
      'english': 'English',
      'arabic': 'العربية',
      'enableDarkTheme': 'Enable dark theme',
      'enableNotifications': 'Enable push notifications',
      'autoBackup': 'Auto Backup',
      'enableAutoBackup': 'Enable automatic data backup',
      'restoreData': 'Restore Data',
      'restoreFromBackup': 'Restore from backup',
      'comingSoon': 'Coming soon',
      'version': 'Version',
      'appDescription': 'A comprehensive student tracking system for educational institutions.',
      'close': 'Close',
    },
    'ar': {
      'appName': 'متابعة الطلاب',
      'login': 'تسجيل الدخول',
      'register': 'تسجيل',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'name': 'الاسم',
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'darkMode': 'الوضع الداكن',
      'language': 'اللغة',
      'notifications': 'الإشعارات',
      'about': 'حول',
      'logout': 'تسجيل الخروج',
      'dashboard': 'لوحة التحكم',
      'tasks': 'المهام',
      'attendance': 'الحضور',
      'categories': 'الفئات',
      'students': 'الطلاب',
      'sheikhs': 'المشايخ',
      'reports': 'التقارير',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'search': 'بحث',
      'noResults': 'لا توجد نتائج',
      'loading': 'جار التحميل...',
      'error': 'خطأ',
      'success': 'نجاح',
      'confirm': 'تأكيد',
      'selectLanguage': 'اختر اللغة',
      'english': 'English',
      'arabic': 'العربية',
      'enableDarkTheme': 'تفعيل الوضع الداكن',
      'enableNotifications': 'تفعيل الإشعارات',
      'autoBackup': 'النسخ الاحتياطي التلقائي',
      'enableAutoBackup': 'تفعيل النسخ الاحتياطي التلقائي',
      'restoreData': 'استعادة البيانات',
      'restoreFromBackup': 'استعادة من النسخة الاحتياطية',
      'comingSoon': 'قريباً',
      'version': 'الإصدار',
      'appDescription': 'نظام شامل لمتابعة الطلاب للمؤسسات التعليمية.',
      'close': 'إغلاق',
    },
  };

  String translate(String key) {
    return _localizedValues[_locale.languageCode]?[key] ?? key;
  }
}
