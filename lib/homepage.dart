import 'package:commuter/components/activity_preview.dart';
import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ResultList<RecordModel> activities;
  bool initializing = true;

  Future refresh() async {
    activities = await Pb.pb.collection("feed").getList(
        page: 1,
        perPage: 50,
        filter: "target.id=\"${Pb.pb.authStore.model.id}\" && kind=\"post\"",
        sort: "-created",
        expand: "activity");
    setState(() {
      activities = activities;
    });
  }

  @override
  void initState() {
    super.initState();
    refresh().then((v) {
      setState(() {
        initializing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: RefreshIndicator(
        onRefresh: refresh,
        child: ListView.builder(
          itemBuilder: (context, index) => ActivityPreview(
            activity: activities.items[index].expand["activity"]![0],
          ),
          itemCount: activities.items.length,
        ),
      ),
    );
  }
}
