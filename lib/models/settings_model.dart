import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 1)
class SettingsModel extends HiveObject {
  @HiveField(0)
  int workMinutes;

  @HiveField(1)
  int restMinutes;

  @HiveField(2)
  bool isDarkTheme;

  @HiveField(3)
  int maxLogEntries;

  @HiveField(4)
  int activityLogCheckInterval;

  @HiveField(5)
  int restReminderInterval;

  @HiveField(6)
  String audioNotificationType; // 'default', 'custom', 'tts'

  @HiveField(7)
  String? audioFilePath;

  @HiveField(8)
  String ttsText;

  @HiveField(9)
  String restTtsText;

  SettingsModel({
    this.workMinutes = 20,
    this.restMinutes = 5,
    this.isDarkTheme = true,
    this.maxLogEntries = 10000,
    this.activityLogCheckInterval = 60,
    this.restReminderInterval = 2,
    this.audioNotificationType = 'default',
    this.audioFilePath,
    this.ttsText = 'Please rest now',
    this.restTtsText = 'Rest obtained',
  });
}
