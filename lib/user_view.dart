import 'package:commuter/components/activity_preview.dart';
import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class UserViewArgs {
  final String userId;

  UserViewArgs(this.userId);
}

class UserViewPage extends StatefulWidget {
  const UserViewPage({super.key});

  @override
  State<UserViewPage> createState() => _UserViewPageState();
}

class _UserViewPageState extends State<UserViewPage> {
  late RecordModel user;
  late ResultList<RecordModel> activities;
  bool loading = false;
  bool loaded = false;

  bool following = false;

  int followers = 0;

  void init(UserViewArgs args) async {
    setState(() {
      loading = true;
    });

    user = await Pb.pb.collection("users").getOne(args.userId);
    followers = (await Pb.pb
            .collection("users")
            .getFullList(filter: "following.id ?= \"${user.id}\""))
        .length;
    activities = await Pb.pb
        .collection("activities")
        .getList(filter: "author.id = \"${user.id}\"", sort: "-start");

    setState(() {
      loading = false;
      loaded = true;
    });
  }

  void follow() async {
    setState(() {
      following = true;
    });

    if ((Pb.pb.authStore.model.data["following"] as List<dynamic>)
        .contains(user.id)) {
      (Pb.pb.authStore.model.data["following"] as List<dynamic>)
          .remove(user.id);
      followers--;
    } else {
      (Pb.pb.authStore.model.data["following"] as List<dynamic>).add(user.id);
      followers++;
    }
    await Pb.pb.collection("users").update(Pb.pb.authStore.model.id, body: {
      "following": Pb.pb.authStore.model.data["following"],
    });

    setState(() {
      following = false;
      user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && !loaded) {
      init(ModalRoute.of(context)!.settings.arguments as UserViewArgs);
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
          title: Text(user.data["username"])),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            (Pb.pb.authStore.model.data["following"] as List<dynamic>)
                    .contains(user.id)
                ? ListTile(
                    title: const Text("Followers"),
                    subtitle: Text(followers.toString()),
                    trailing: OutlinedButton.icon(
                      label: const Text("Unfollow"),
                      icon: const Icon(Icons.person_remove),
                      onPressed: following ? null : follow,
                    ),
                  )
                : ListTile(
                    title: const Text("Followers"),
                    subtitle: Text(followers.toString()),
                    trailing: FilledButton.icon(
                      label: const Text("Follow"),
                      icon: const Icon(Icons.person_add),
                      onPressed: following ? null : follow,
                    ),
                  ),
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) => ActivityPreview(
                  activity: activities.items[index],
                ),
                itemCount: activities.items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
