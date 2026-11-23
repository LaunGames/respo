import 'package:flutter/material.dart';
import 'map_page.dart';

void main() => runApp(const CityInfraApp());

class CityInfraApp extends StatefulWidget {
  const CityInfraApp({super.key});

  @override
  State<CityInfraApp> createState() => _CityInfraAppState();
}

class _CityInfraAppState extends State<CityInfraApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'City Infra Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MapPage(onToggleTheme: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}