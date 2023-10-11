import 'package:commuter/club_view.dart';
import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';

class ClubNewPage extends StatefulWidget {
  const ClubNewPage({super.key});

  @override
  State<ClubNewPage> createState() => _ClubNewPageState();
}

class _ClubNewPageState extends State<ClubNewPage> {
  bool loading = false;
  String name = "";

  void create() async {
    setState(() {
      loading = true;
    });

    final club = await Pb.pb.collection("clubs").create(body: {
      "author": Pb.pb.authStore.model.id,
      "members": [Pb.pb.authStore.model.id],
      "name": name,
    });

    Navigator.popAndPushNamed(context, "/clubview",
        arguments: ClubViewArgs(club.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("CO₂mmuter"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                icon: Icon(Icons.title),
                labelText: "Club name",
              ),
              onChanged: (v) {
                setState(() {
                  name = v;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : create,
              child: const Text(
                'Create Club',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
