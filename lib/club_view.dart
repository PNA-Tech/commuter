import 'package:commuter/components/user_search.dart';
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
  bool loading = false;
  bool loaded = false;

  void init(ClubViewArgs args) async {
    setState(() {
      loading = true;
    });

    club = await Pb.pb.collection("clubs").getOne(args.clubId);

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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            if (club.data["author"] == Pb.pb.authStore.model.id) ...[
              UserSearch(
                  onTap: (String id) async {
                    if (club.data["members"].contains(id)) {
                      return;
                    }
                    club.data["members"].add(id);
                    await Pb.pb.collection("clubs").update(club.id, body: {
                      "members": club.data["members"],
                    });
                    setState(() {
                      club = club;
                    });
                  },
                  hint: "Add member"),
              const SizedBox(height: 20),
            ],
            Text(
              'Club: ${club.data["name"]}',
            ),
          ],
        ),
      ),
    );
  }
}
