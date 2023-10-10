import 'package:commuter/club_view.dart';
import 'package:commuter/pb.dart';
import 'package:commuter/user_view.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  Future<ResultList<RecordModel>> search(String query) async {
    return Pb.pb.collection("users").getList(
          page: 1,
          perPage: 50,
          filter: 'username~"$query"',
          sort: "+created",
        );
  }

  bool loading = true;
  late ResultList<RecordModel> clubs;

  Future refresh() async {
    clubs = await Pb.pb.collection("clubs").getList(
        page: 1,
        perPage: 50,
        filter: "members.id ?= \"${Pb.pb.authStore.model.id}\"",
        sort: "-created");

    setState(() {
      clubs = clubs;
    });
  }

  @override
  void initState() {
    super.initState();
    refresh().then((_) {
      setState(() {
        loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SearchAnchor.bar(
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) {
                final searchFuture = search(controller.text);
                return [
                  FutureBuilder(
                    future: searchFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        final list = snapshot.data;
                        if (list != null) {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.items.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                  title:
                                      Text(list.items[index].data["username"]),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      "/userview",
                                      arguments:
                                          UserViewArgs(list.items[index].id),
                                    );
                                  });
                            },
                          );
                        }
                      }
                      return const LinearProgressIndicator();
                    },
                  )
                ];
              },
              barHintText: "Search users",
            ),
            const SizedBox(height: 10),
            const Divider(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView.separated(
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(clubs.items[index].data["name"]),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/clubview",
                          arguments: ClubViewArgs(clubs.items[index].id),
                        );
                      },
                    );
                  },
                  itemCount: clubs.items.length,
                  separatorBuilder: (context, index) {
                    return Divider();
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, "/clubnew").then((_) {
                  refresh();
                });
              },
              label: const Text("Create Club"),
            )
          ],
        ),
      ),
    );
  }
}
