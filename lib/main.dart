import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/hive_service.dart';
import 'services/background_service.dart';
import 'screens/main_screen.dart';
import 'models/settings_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await initializeService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<SettingsModel>>(
      valueListenable: HiveService.settingsBox.listenable(),
      builder: (context, box, _) {
        final settings = box.getAt(0) ?? SettingsModel();
        return MaterialApp(
          title: 'Eye Strain Log',
          theme: ThemeData(
            brightness: settings.isDarkTheme ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}

