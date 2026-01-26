import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../services/hive_service.dart';
import '../models/log_entry.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'about_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const platform = MethodChannel('com.example.eye_strain_log/native');
  double _strainedSeconds = 0;
  bool _isPlaying = true; // Assuming service starts? Actually autoStart is false.
  String _searchQuery = '';
  
  // Timer to fetch logs
  Timer? _logTimer;

  @override
  void initState() {
    super.initState();
    _startListeningToService();
    _startLogTimer();
    _syncServiceState();
  }
  
  void _syncServiceState() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    setState(() {
      _isPlaying = isRunning;
    });
    // Check if we need to start it
    if (!isRunning && _isPlaying) { // If we default to playing? 
       // Actually instructions say: "If the Android foreground service does not exist the app should start... if user presses play"
       // So initially _isPlaying could be false if service is off.
       setState(() { _isPlaying = false; });
    }
  }

  void _startListeningToService() {
    FlutterBackgroundService().on('updateStrainedSeconds').listen((event) {
      if (event != null && event.containsKey('strainedSeconds')) {
        setState(() {
          _strainedSeconds = (event['strainedSeconds'] as num).toDouble();
        });
      }
    });
  }
  
  void _startLogTimer() {
    // Check logs every 60s
    _logTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      setState(() {}); // Rebuild to refresh Hive List
    });
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    
    if (isRunning) {
      // Logic for pause? The instructions say "send signal to pause". 
      // BackgroundService doesn't have built-in pause, we'd need to implement 'pauseTracker' event.
      // But for now, if we "Pause", maybe we just stop the service or set a flag? 
      // Instructions: "If the user presses the pause button, the app should send a signal... to pause".
      // I need to add 'setPause' listener in background service.
      // For now I'll just assume start/stop service or add 'setPause'.
      // I'll stick to Service Start/Stop for Play/Pause if simpler, but instruction differentiates Stop vs Pause.
      // Stop is "Close app completely". Pause is just "Pause tracker".
      service.invoke('setPause', {'paused': true});
      setState(() => _isPlaying = false);
    } else {
      await service.startService();
      // Send initial settings
      // Sync settings to service
      service.invoke('setPause', {'paused': false});
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _stopAndClose() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop and Close?'),
        content: const Text('This will fully stop the background service and exit the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Stop')),
        ],
      ),
    );

    if (confirm == true) {
      final service = FlutterBackgroundService();
      service.invoke('stopService');
      await Hive.close(); // Close boxes
      exit(0);
    }
  }
  
  Future<void> _lockScreen() async {
    try {
      await platform.invokeMethod('lockScreen');
      HiveService.addLog('MANUAL_LOCK', 'User manually locked screen');
    } on PlatformException catch (e) {
      if (e.code == 'NO_ADMIN') {
        // Request Admin
        try {
          await platform.invokeMethod('enableAdmin');
        } catch (_) {}
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      }
    }
  }
  
  Future<void> _exportLogs() async {
    String? outputDir = await FilePicker.platform.getDirectoryPath();
    if (outputDir != null) {
      final logs = HiveService.logBox.values.toList();
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Descending
      
      final File file = File('$outputDir/eye_strain_logs.txt');
      final buffer = StringBuffer();
      for (var log in logs) {
        buffer.writeln('[${DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)}] ${log.activityType}: ${log.details}');
      }
      await file.writeAsString(buffer.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logs exported to ${file.path}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eye Strain Log'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                 Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stop Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Even if you close the app it will still continue running in the background. To fully stop it, press the stop button.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop_circle, color: Colors.red),
                    onPressed: _stopAndClose,
                  )
                ],
              ),
              const Divider(),
              
              // Lock Section
              Row(
                children: [
                  const Text("Lock screen now"),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.lock),
                    onPressed: _lockScreen,
                  )
                ],
              ),
              const Divider(),
              
              // Tracker Section
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 48,
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Strained for: ${_formatTime(_strainedSeconds)}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const Divider(),
              
              // Activity Log Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Activity logs", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState((){})),
                      IconButton(icon: const Icon(Icons.download), onPressed: _exportLogs),
                    ],
                  )
                ],
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search logs by activity type',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 10),
              Container(
                height: 300,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                child: ValueListenableBuilder<Box<LogEntry>>(
                  valueListenable: HiveService.logBox.listenable(),
                  builder: (context, box, _) {
                    var logs = box.values.toList();
                    // Sort descending
                    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    
                    if (_searchQuery.isNotEmpty) {
                      logs = logs.where((l) => l.activityType.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                    }
                    
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return ListTile(
                          title: Text(log.activityType),
                          subtitle: Text(log.details),
                          trailing: Text(DateFormat('MM-dd HH:mm').format(log.timestamp)),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = (seconds % 60).toInt();
    if (h > 0) return '$h hr : $m min : $s sec';
    return '$m min : $s sec';
  }
}
