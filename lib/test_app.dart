// lib/test_app.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Тест')),
        body: ListView(
          children: [
            ListTile(title: Text('1. Приложение запущено')),
            ListTile(title: Text('2. Flutter работает')),
            ListTile(title: Text('3. Edge подключен')),
            ElevatedButton(
              onPressed: () {
                print('Кнопка нажата!');
              },
              child: Text('Тестовая кнопка'),
            ),
          ],
        ),
      ),
    );
  }
}