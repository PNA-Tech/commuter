import 'package:commuter/components/activity_preview.dart';
import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:pocketbase/pocketbase.dart';

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
  late RecordModel activity;
  late ActivityMapData mapData;
  bool loaded = false;
  bool loading = false;
  List<RecordModel> likes = [];
  late ResultList<RecordModel> comments;
  final commentController = TextEditingController();
  bool postingComment = false;

  Future loadLikes() async {
    likes = await Pb.pb
        .collection("likes")
        .getFullList(filter: "post=\"${activity.id}\"");
    setState(() {
      likes = likes;
    });
  }

  Future loadComments() async {
    comments = await Pb.pb.collection("comments").getList(
        filter: "activity=\"${activity.id}\"",
        sort: "-created",
        expand: "author");
    setState(() {
      comments = comments;
    });
  }

  String? hasLiked() {
    for (var like in likes) {
      if (like.data["author"] == Pb.pb.authStore.model.id) {
        return like.id;
      }
    }
    return null;
  }

  void like() async {
    String? liked = hasLiked();
    if (liked != null) {
      await Pb.pb.collection("likes").delete(liked);
    } else {
      await Pb.pb.collection("likes").create(body: {
        "post": activity.id,
        "author": Pb.pb.authStore.model.id,
      });

      // Push to feed
      final followers = await Pb.pb.collection('users').getFullList(
            filter: "following.id ?= \"${Pb.pb.authStore.model.id}\"",
          );
      for (final follower in followers) {
        await Pb.pb.collection('feed').create(body: {
          "target": follower.id,
          "activity": activity.id,
          "kind": "like",
          "author": Pb.pb.authStore.model.id,
        });
      }
    }
    loadLikes();
  }

  void init(ActivityViewArgs args) async {
    setState(() {
      loading = true;
    });

    activity = await Pb.pb.collection("activities").getOne(args.activityId);
    mapData = getActivityBounds(activity);
    await loadLikes();
    await loadComments();

    setState(() {
      loading = false;
      loaded = true;
    });
  }

  void comment() async {
    setState(() {
      postingComment = true;
    });

    await Pb.pb.collection("comments").create(body: {
      "activity": activity.id,
      "author": Pb.pb.authStore.model.id,
      "comment": commentController.value.text,
    });
    await loadComments();

    setState(() {
      postingComment = false;
      commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && !loaded) {
      init(ModalRoute.of(context)!.settings.arguments as ActivityViewArgs);
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text(
            "CO₂mmuter",
          ),
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 2.5,
            child: FlutterMap(
              options: MapOptions(
                bounds: mapData.bounds,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      strokeWidth: 3,
                      points: mapData.points,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListTile(
                  title: const Text(
                    "Distance",
                    textAlign: TextAlign.center,
                  ),
                  subtitle: Text(
                    "${activity.data["length"].toStringAsFixed(2)} miles",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text(
                    "Time",
                    textAlign: TextAlign.center,
                  ),
                  subtitle: Text(
                    formatDuration(DateTime.parse(activity.data["end"])
                        .difference(DateTime.parse(activity.data["start"]))),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text(
                    "CO₂ Saved",
                    textAlign: TextAlign.center,
                  ),
                  subtitle: Text(
                    "${activity.data["savings"].toStringAsFixed(2)} lbs",
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
              icon: Icon(hasLiked() == null
                  ? Icons.thumb_up_outlined
                  : Icons.thumb_up),
              onPressed: like,
              label: Text(
                "${likes.length} Like${likes.length == 1 ? "" : "s"}",
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Comment",
                    ),
                    controller: commentController,
                    onSubmitted: (v) => comment(),
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.post_add),
                  onPressed: postingComment ? null : comment,
                  label: const Text("Post"),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: comments.items.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  comments.items[index].expand["author"]![0].data["username"],
                ),
                subtitle: Text(
                  comments.items[index].data["comment"],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
