import 'package:flutter/material.dart';
import 'package:win/tools/hwnd.dart';
import 'package:win/tools/primitives.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final hwnd = Hwnd.fromMainWindow();

  void _increment() {
    final w = hwnd.size;
    hwnd.size = Size(w.width + 10, w.height + 10);
    hwnd.center();
  }

  void _decrement() {
    final w = hwnd.size;
    hwnd.size = Size(w.width + -10, w.height - 10);
    hwnd.center();
  }

  @override
  void dispose() {
    hwnd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _decrement,
              tooltip: 'Increment',
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              onPressed: _increment,
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
