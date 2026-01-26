import 'package:hive/hive.dart';

part 'log_entry.g.dart';

@HiveType(typeId: 0)
class LogEntry extends HiveObject {
  @HiveField(0)
  final String activityType;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final String details;

  LogEntry({
    required this.activityType,
    required this.timestamp,
    required this.details,
  });
}
