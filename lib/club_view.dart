import 'package:commuter/components/user_search.dart';
import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Map<String, double> scores = {};
  Map<String, String> usernames = {};

  bool loading = false;
  bool loaded = false;

  Future refresh() async {
    club = await Pb.pb.collection("clubs").getOne(club.id, expand: "members");

    final date = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 7)));

    // Get scores
    for (int i = 0; i < club.expand["members"]!.length; i++) {
      final user = club.data["members"][i];
      final activities = await Pb.pb
          .collection("activities")
          .getFullList(filter: "author.id = \"$user\" && start >= \"$date\"");
      scores[user] = 0;
      usernames[user] = club.expand["members"]![i].data["username"];
      for (final a in activities) {
        scores[user] = scores[user]! + a.data["savings"];
      }
    }

    // Sort
    (club.data["members"] as List<dynamic>).sort((a, b) {
      return (scores[a]! > scores[b]!) ? -1 : 1;
    });

    setState(() {
      club = club;
    });
  }

  void init(ClubViewArgs args) async {
    setState(() {
      loading = true;
    });
    club = RecordModel(id: args.clubId);
    await refresh();
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
        title: Text(club.data["name"]),
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
                    await refresh();
                  },
                  hint: "Add member"),
              const SizedBox(height: 20),
            ],
            const ListTile(
                title: Text("Member",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("CO₂ saved",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: club.data["members"].length,
                itemBuilder: (BuildContext context, int index) {
                  final user = club.data["members"][index];
                  return ListTile(
                    title: Text(usernames[user]!),
                    trailing: Text("${scores[user]!.toStringAsFixed(2)} lb",
                        style: DefaultTextStyle.of(context).style),
                  );
                },
                separatorBuilder: (_, __) => const Divider(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
