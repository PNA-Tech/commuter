import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class UserSearch extends StatelessWidget {
  final Future Function(String) onTap;
  final String hint;

  const UserSearch(
      {super.key, required this.onTap, this.hint = "Search users"});

  Future<ResultList<RecordModel>> search(String query) async {
    return Pb.pb.collection("users").getList(
          page: 1,
          perPage: 50,
          filter: 'username~"$query"',
          sort: "+created",
        );
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor.bar(
      suggestionsBuilder: (BuildContext context, SearchController controller) {
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
                          title: Text(list.items[index].data["username"]),
                          onTap: () {
                            onTap(list.items[index].id).then((_) {
                              controller.closeView("");
                            });
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
      barHintText: hint,
    );
  }
}
