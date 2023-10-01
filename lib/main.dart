import 'package:commuter/screens/home_screen.dart';
import 'package:commuter/screens/record_screen.dart';
import 'package:commuter/screens/settings_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const Commuter());
}

class Commuter extends StatelessWidget {
  const Commuter({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CO₂mmuter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("CO₂mmuter"),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            pageIndex = index;
          });
        },
        selectedIndex: pageIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Feed"),
          NavigationDestination(
              icon: Icon(Icons.radio_button_checked), label: "Record"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
      body: const [HomeScreen(), RecordScreen(), SettingsScreen()][pageIndex],
    );
  }
}
