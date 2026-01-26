import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/log_entry.dart';
import '../models/settings_model.dart';
import 'package:flutter/foundation.dart';

class HiveService {
  static const String logBoxName = 'logs';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LogEntryAdapter());
    Hive.registerAdapter(SettingsModelAdapter());

    await Hive.openBox<SettingsModel>(settingsBoxName);
    // We open logs box efficiently or on demand if it gets large, 
    // but for now opening it is fine.
    await Hive.openBox<LogEntry>(logBoxName);
    
    // Ensure default settings exist
    final settingsBox = Hive.box<SettingsModel>(settingsBoxName);
    if (settingsBox.isEmpty) {
      settingsBox.add(SettingsModel());
    }
  }

  static Box<SettingsModel> get settingsBox => Hive.box<SettingsModel>(settingsBoxName);
  static Box<LogEntry> get logBox => Hive.box<LogEntry>(logBoxName);

  static Future<void> addLog(String type, String details) async {
    final log = LogEntry(
      activityType: type,
      timestamp: DateTime.now(),
      details: details,
    );
    await logBox.add(log);
  }
}
