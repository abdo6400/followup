import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoBackupNotifier extends StateNotifier<bool> {
  AutoBackupNotifier() : super(false) {
    _loadAutoBackupPref();
  }

  Future<void> _loadAutoBackupPref() async {
    // TODO: Load auto-backup preference from SharedPreferences
  }

  Future<void> toggleAutoBackup() async {
    state = !state;
    // TODO: Save auto-backup preference to SharedPreferences
  }
}

final autoBackupProvider = StateNotifierProvider<AutoBackupNotifier, bool>((ref) {
  return AutoBackupNotifier();
});
