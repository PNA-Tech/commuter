import 'package:commuter/activity_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:latlong2/latlong.dart';

class ActivityPreview extends StatefulWidget {
  final RecordModel activity;

  const ActivityPreview({super.key, required this.activity});

  @override
  State<ActivityPreview> createState() => _ActivityPreviewState();
}

String formatDuration(Duration d) {
  if (d.inMinutes > 60) {
    return "${d.inHours}h ${d.inMinutes % 60}m";
  }
  return "${d.inMinutes}m";
}

class ActivityMapData {
  final LatLngBounds bounds;
  final List<LatLng> points;

  ActivityMapData(this.bounds, this.points);
}

ActivityMapData getActivityBounds(RecordModel activity) {
  double topLat = -180;
  double bottomLat = 180;
  double leftLon = 180;
  double rightLon = -180;
  List<LatLng> points = [];
  for (var point in activity.data["route"]) {
    if (point["latitude"] > topLat) {
      topLat = point["latitude"];
    }
    if (point["latitude"] < bottomLat) {
      bottomLat = point["latitude"];
    }
    if (point["longitude"] > rightLon) {
      rightLon = point["longitude"];
    }
    if (point["longitude"] < leftLon) {
      leftLon = point["longitude"];
    }
    points.add(LatLng(point["latitude"], point["longitude"]));
  }
  return ActivityMapData(
      LatLngBounds(LatLng(topLat - 0.03, leftLon - 0.03),
          LatLng(bottomLat + 0.03, rightLon + 0.03)),
      points);
}

class _ActivityPreviewState extends State<ActivityPreview> {
  late ActivityMapData mapData;

  @override
  void initState() {
    super.initState();
    mapData = getActivityBounds(widget.activity);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, "/view",
              arguments: ActivityViewArgs(widget.activity.id));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 5,
              child: FlutterMap(
                options: MapOptions(
                  bounds: mapData.bounds,
                  interactiveFlags: InteractiveFlag.none,
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
                      "${widget.activity.data["length"].toStringAsFixed(2)} mi",
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
                      formatDuration(DateTime.parse(widget.activity.data["end"])
                          .difference(
                              DateTime.parse(widget.activity.data["start"]))),
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
                      "${widget.activity.data["savings"].toStringAsFixed(2)} lbs",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
