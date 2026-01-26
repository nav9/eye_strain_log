import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:screen_state/screen_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings_model.dart';
import '../models/log_entry.dart';
import 'hive_service.dart';

// Notification Channel IDs
const String channelId = 'eye_strain_monitor';
const String channelName = 'Eye Strain Monitor';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    channelId,
    channelName,
    description: 'Monitors eye strain and reminds to rest',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // User starts it manually via UI
      isForegroundMode: true,
      notificationChannelId: channelId,
      initialNotificationTitle: 'Eye Strain Log',
      initialNotificationContent: 'Monitoring eye strain...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // Initialize Hive in background
  await HiveService.init();
  
  final screen = Screen();
  ScreenStateEvent lastScreenState = ScreenStateEvent.SCREEN_ON;
  
  // State variables - using defaults, will update from UI
  int workMinutes = 20;
  int restMinutes = 5;
  int restReminderInterval = 2; // Minutes
  
  // Current counters
  double strainedSeconds = 0;
  
  // Listen for settings updates from UI
  service.on('updateSettings').listen((event) {
    if (event != null) {
      if (event.containsKey('workMinutes')) workMinutes = event['workMinutes'] as int;
      if (event.containsKey('restMinutes')) restMinutes = event['restMinutes'] as int;
      if (event.containsKey('restReminderInterval')) restReminderInterval = event['restReminderInterval'] as int;
      // Handle other settings...
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Setup Notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  // Screen state listener
  try {
    screen.screenStateStream?.listen((event) {
      lastScreenState = event; // Use local variable from closure or check type?
      // Wait, Stream<ScreenStateEvent>
      if (event == ScreenStateEvent.SCREEN_ON) {
        HiveService.addLog('SCREEN_ON', 'Screen turned on');
      } else if (event == ScreenStateEvent.SCREEN_OFF) {
        HiveService.addLog('SCREEN_OFF', 'Screen turned off');
      }
    });
  } catch (e) {
    print('Error listening to screen stream: $e');
  }

  // Timer loop
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    // Check if service is stopped
    // ServiceInstance doesn't have isRunning check easily exposed here, but stopSelf kills isolate.
    
    if (lastScreenState == ScreenStateEvent.SCREEN_ON) {
      strainedSeconds++;
      
      // Update UI with current val
      service.invoke('updateStrainedSeconds', {'strainedSeconds': strainedSeconds});
      
      // Check for thresholds
      // Logic for reminders... 
      if (strainedSeconds > workMinutes * 60) {
         // Overworked!
         // Detailed reminder logic would go here (interval checks)
         
         if (strainedSeconds % 60 == 0) {
             flutterLocalNotificationsPlugin.show(
                id: 888,
                title: 'Eye Rest Needed',
                body: 'Strained: ${formatTime(strainedSeconds)}. Please rest!',
                notificationDetails: const NotificationDetails(
                  android: AndroidNotificationDetails(
                    channelId,
                    channelName,
                    importance: Importance.high,
                    priority: Priority.high,
                  ),
                ),
             );
         }
      } else {
         // Update foreground notification (silent)
         if (strainedSeconds % 60 == 0) { // Update every minute to be less spammy
             flutterLocalNotificationsPlugin.show(
                id: 888,
                title: 'Eye Strain Log',
                body: 'Strained: ${formatTime(strainedSeconds)}',
                notificationDetails: const NotificationDetails(
                  android: AndroidNotificationDetails(
                    channelId,
                    channelName,
                    importance: Importance.low,
                    priority: Priority.low,
                    showWhen: false,
                    ongoing: true,
                  ),
                ),
             );
         }
      }
    } else {
      // Screen OFF - Rest Logic
      if (strainedSeconds > 0) {
        // Decrease rate: WORK / REST
        // e.g. 20 / 5 = 4. Every 1 second of rest reduces strained time by 4 seconds.
        double restorationMultipler = workMinutes / restMinutes;
        strainedSeconds -= restorationMultipler; 
        
        // Update UI even if decreasing? Maybe not necessary if UI is likely off/background.
        service.invoke('updateStrainedSeconds', {'strainedSeconds': strainedSeconds});
        
        if (strainedSeconds <= 0) {
          strainedSeconds = 0;
          // Notify "Rest Obtained" once
          HiveService.addLog('REST_COMPLETE', 'Eyes sufficiently rested');
          
           flutterLocalNotificationsPlugin.show(
              id: 999, // Separate ID
              title: 'Rest Complete',
              body: 'You have rested enough. Eyes are fresh!',
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  channelId,
                  channelName,
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
           );
        }
      }
    }
  });
}

String formatTime(double seconds) {
  int h = seconds ~/ 3600;
  int m = (seconds % 3600) ~/ 60;
  int s = (seconds % 60).toInt();
  if (h > 0) return '$h hr $m min $s sec';
  return '$m min $s sec';
}
