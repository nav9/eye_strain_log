import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text('Features', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ListTile(
            leading: Icon(Icons.play_arrow),
            title: Text('Start Tracking'),
            subtitle: Text('Starts the eye strain monitor service.'),
          ),
          ListTile(
            leading: Icon(Icons.pause),
            title: Text('Pause Tracking'),
            subtitle: Text('Pauses the monitor temporarily.'),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Lock Screen'),
            subtitle: Text('Immediately locks the device screen.'),
          ),
          ListTile(
            leading: Icon(Icons.stop_circle, color: Colors.red),
            title: Text('Stop & Close'),
            subtitle: Text('Fully stops the service and closes the app.'),
          ),
          SizedBox(height: 20),
          Text('FAQ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Q: Does it run in background?\nA: Yes, it monitors screen usage even when closed.'),
        ],
      ),
    );
  }
}
