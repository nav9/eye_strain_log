import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/settings_model.dart';
import '../services/hive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsModel settings;
  late TextEditingController workController;
  late TextEditingController restController;

  @override
  void initState() {
    super.initState();
    settings = HiveService.settingsBox.getAt(0) ?? SettingsModel();
    workController = TextEditingController(text: settings.workMinutes.toString());
    restController = TextEditingController(text: settings.restMinutes.toString());
  }

  void _saveSettings() {
    settings.workMinutes = int.tryParse(workController.text) ?? 20;
    settings.restMinutes = int.tryParse(restController.text) ?? 5;
    settings.save();
    
    // Notify Service
    FlutterBackgroundService().invoke('updateSettings', {
      'workMinutes': settings.workMinutes,
      'restMinutes': settings.restMinutes,
      // Add others...
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: workController,
            decoration: const InputDecoration(labelText: 'Work Minutes'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _saveSettings(),
          ),
          TextField(
            controller: restController,
            decoration: const InputDecoration(labelText: 'Rest Minutes'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _saveSettings(),
          ),
          SwitchListTile(
            title: const Text('Dark Theme'),
            value: settings.isDarkTheme,
            onChanged: (val) {
              setState(() {
                settings.isDarkTheme = val;
              });
              settings.save();
              // Notify Service if needed? Theme is UI only mostly.
            },
          ),
          ElevatedButton(
            onPressed: () {
               setState(() {
                 workController.text = '20';
                 restController.text = '5';
                 _saveSettings();
               });
            },
            child: const Text('Reset Defaults'),
          )
        ],
      ),
    );
  }
}
