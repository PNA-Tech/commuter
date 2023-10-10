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
  bool loading = false;
  bool loaded = false;

  void init(UserViewArgs args) async {
    setState(() {
      loading = true;
    });

    user = await Pb.pb.collection("users").getOne(args.userId);

    setState(() {
      loading = false;
      loaded = true;
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
        title: const Text("CO₂mmuter"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              'User: ${user.data["username"]}',
            ),
          ],
        ),
      ),
    );
  }
}
