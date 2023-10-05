import 'package:flutter/material.dart';

class ActivityViewArgs {
  final String activityId;

  ActivityViewArgs(this.activityId);
}

class ActivityViewPage extends StatefulWidget {
  const ActivityViewPage({super.key});

  @override
  State<ActivityViewPage> createState() => _ActivityViewPageState();
}

class _ActivityViewPageState extends State<ActivityViewPage> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ActivityViewArgs;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("CO₂mmuter"),
      ),
      body: Center(
        child: Text("Activity ${args.activityId}"),
      ),
    );
  }
}
