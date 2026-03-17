import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SOSApp());
}

class SOSApp extends StatelessWidget {
  const SOSApp({super.key});

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: "Emergency Alert System",
  theme: ThemeData(
    primarySwatch: Colors.blue,
  ),
  home: const HomeScreen(),
);
  }
}