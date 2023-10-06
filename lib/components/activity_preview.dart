import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class ActivityPreview extends StatefulWidget {
  final RecordModel activity;

  const ActivityPreview({super.key, required this.activity});

  @override
  State<ActivityPreview> createState() => _ActivityPreviewState();
}

class _ActivityPreviewState extends State<ActivityPreview> {
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Map"),
          Row(
            children: [
              Text("Distance"),
              Text("Duration"),
              Text("Speed"),
            ],
          )
        ],
      ),
    );
  }
}
