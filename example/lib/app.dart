import 'package:flutter/material.dart';
import 'pages/home/home_page.dart';

/// Mind Map Flutter editor example app
class MindMapExamplesApp extends StatelessWidget {
  const MindMapExamplesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mind Map Editor Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7490)),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
