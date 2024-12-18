import 'package:flutter/material.dart';
import 'favorite.dart';
import 'welcome.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myresep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(), 
      routes: {
        '/favorite': (context) => FavoritePage(), // Tambahkan ini
      },
    );
  }
}
