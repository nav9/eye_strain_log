// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 1;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      workMinutes: fields[0] as int,
      restMinutes: fields[1] as int,
      isDarkTheme: fields[2] as bool,
      maxLogEntries: fields[3] as int,
      activityLogCheckInterval: fields[4] as int,
      restReminderInterval: fields[5] as int,
      audioNotificationType: fields[6] as String,
      audioFilePath: fields[7] as String?,
      ttsText: fields[8] as String,
      restTtsText: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.workMinutes)
      ..writeByte(1)
      ..write(obj.restMinutes)
      ..writeByte(2)
      ..write(obj.isDarkTheme)
      ..writeByte(3)
      ..write(obj.maxLogEntries)
      ..writeByte(4)
      ..write(obj.activityLogCheckInterval)
      ..writeByte(5)
      ..write(obj.restReminderInterval)
      ..writeByte(6)
      ..write(obj.audioNotificationType)
      ..writeByte(7)
      ..write(obj.audioFilePath)
      ..writeByte(8)
      ..write(obj.ttsText)
      ..writeByte(9)
      ..write(obj.restTtsText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
