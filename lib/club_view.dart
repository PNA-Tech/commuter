import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class ClubViewArgs {
  final String clubId;

  ClubViewArgs(this.clubId);
}

class ClubViewPage extends StatefulWidget {
  const ClubViewPage({super.key});

  @override
  State<ClubViewPage> createState() => _ClubViewPageState();
}

class _ClubViewPageState extends State<ClubViewPage> {
  late RecordModel club;
  bool loading = true;
  bool loaded = false;

  void init(ClubViewArgs args) async {
    setState(() {
      loading = true;
    });

    club = await Pb.pb.collection("users").getOne(args.clubId);

    setState(() {
      loading = false;
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && !loaded) {
      init(ModalRoute.of(context)!.settings.arguments as ClubViewArgs);
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("CO₂mmuter"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (loading && !loaded) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("CO₂mmuter"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("CO₂mmuter"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              'Club: ${club.data["name"]}',
            ),
          ],
        ),
      ),
    );
  }
}
