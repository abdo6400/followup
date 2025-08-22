import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) {
    _loadLocale();
  }


  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'en';
    state = Locale(language);
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }

  final Map<String, Map<String, String>> localizedValues = {
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

  String getTranslatedValue(String key) {
    return localizedValues[state.languageCode]?[key] ?? key;
  }
}

final translationProvider = Provider<String Function(String)>((ref) {
  final notifier = ref.read(languageProvider.notifier);
  return (String key) => notifier.getTranslatedValue(key);
});
