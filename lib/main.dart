import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FarmTrackApp());
}

class FarmTrackApp extends StatelessWidget {
  const FarmTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FarmTrack',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            "Firebase conectado holaaa✅",
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
