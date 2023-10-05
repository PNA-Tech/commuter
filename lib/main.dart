import 'package:commuter/auth.dart';
import 'package:commuter/clubs.dart';
import 'package:commuter/homepage.dart';
import 'package:commuter/pb.dart';
import 'package:commuter/record.dart';
import 'package:commuter/settings.dart';
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
        routes: {
          "/": (context) => const Home(),
          "/auth": (context) => const Auth(),
        });
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int pageIndex = 0;
  bool initializing = true;

  void initPb() async {
    await Pb.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        initializing = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    initPb();
  }

  @override
  Widget build(BuildContext context) {
    if (initializing) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (!Pb.pb.authStore.isValid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, "/auth");
      });
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
          NavigationDestination(icon: Icon(Icons.groups), label: "Clubs"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
      body: const [
        HomePage(),
        RecordPage(),
        ClubsPage(),
        SettingsPage(),
      ][pageIndex],
    );
  }
}
