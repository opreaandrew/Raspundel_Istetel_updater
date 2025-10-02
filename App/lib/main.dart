import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';
import 'dart:io';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isWindows || Platform.isLinux) {
    setWindowTitle('Raspundel Updater');
    setWindowMinSize(const Size(800, 600));
  }
  
  runApp(const RaspundelUpdaterApp());
}

class RaspundelUpdaterApp extends StatelessWidget {
  const RaspundelUpdaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raspundel Updater',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}