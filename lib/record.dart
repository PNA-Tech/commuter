import 'dart:convert';

import 'package:commuter/activity_view.dart';
import 'package:commuter/components/activity_preview.dart';
import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'dart:math';

double routePointDistance(double lat1, double lon1, double lat2, double lon2) {
  // Convert the latitudes and longitudes to radians.
  double lat1Rad = lat1 * (pi / 180);
  double lon1Rad = lon1 * (pi / 180);
  double lat2Rad = lat2 * (pi / 180);
  double lon2Rad = lon2 * (pi / 180);

  // Calculate the distance using the Haversine formula.
  double distance = 2 *
      asin(sqrt(pow(sin((lat2Rad - lat1Rad) / 2), 2) +
          cos(lat1Rad) * cos(lat2Rad) * pow(sin((lon2Rad - lon1Rad) / 2), 2))) *
      6371;

  // Return the distance in miles.
  return distance * 0.621371;
}

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  bool recording = false;
  bool saving = false;
  bool uploading = false;
  Activity currentActivity = Activity();

  final emissionsPerMile = const {
    "carpool": 0.603,
    "bike": 0.057,
    "walk": 0.085,
    "bus": 0.344,
    "ev": 0.167,
    "hybrid": 0.241,
  };

  void init() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.enableBackgroundMode(enable: true);

    location.onLocationChanged.listen((LocationData currentLocation) {
      if (!recording || saving) {
        return;
      }

      currentActivity.route.add(RoutePoint(
          currentLocation.latitude!,
          currentLocation.longitude!,
          currentLocation.altitude!,
          currentLocation.speed!,
          currentLocation.time!));

      if (currentActivity.route.length > 1) {
        final curr = currentActivity.route[currentActivity.route.length - 1];
        final prev = currentActivity.route[currentActivity.route.length - 2];

        setState(() {
          currentActivity.distance += routePointDistance(
              curr.latitude, curr.longitude, prev.latitude, prev.longitude);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  double calcSavings() {
    double original = currentActivity.distance *
        emissionsPerMile["carpool"]!; // Emissions if using car
    double real = currentActivity.distance *
        emissionsPerMile[currentActivity.kind]!; // Emissions if using kind
    // Account for carpool
    if (currentActivity.kind == "carpool" ||
        currentActivity.kind == "hybrid" ||
        currentActivity.kind == "ev") {
      real /= currentActivity.carpoolCount;
    }
    return original - real;
  }

  void save() async {
    setState(() {
      uploading = true;
    });

    // Upload
    final body = <String, dynamic>{
      "author": Pb.pb.authStore.model.id,
      "length": currentActivity.distance,
      "start":
          DateFormat("yyyy-MM-dd HH:mm:ss.SSSZ").format(currentActivity.start),
      "end": DateFormat("yyyy-MM-dd HH:mm:ss.SSSZ").format(currentActivity.end),
      "kind": currentActivity.kind,
      "carpool_count": currentActivity.carpoolCount,
      "route": jsonEncode(currentActivity.route),
      "savings": calcSavings()
    };
    final activity = await Pb.pb.collection('activities').create(body: body);

    // Get users following, give notification
    final followers = await Pb.pb.collection('users').getFullList(
          filter: "following.id ?= \"${Pb.pb.authStore.model.id}\"",
        );
    for (final follower in followers) {
      await Pb.pb.collection('feed').create(body: {
        "target": follower.id,
        "activity": activity.id,
        "kind": "post",
        "author": Pb.pb.authStore.model.id,
      });
    }

    // Done, navigate
    setState(() {
      uploading = false;
      saving = false;
      recording = false;
    });
    Navigator.pushNamed(context, "/view",
        arguments: ActivityViewArgs(activity.id));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!recording && !saving) ...[
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    recording = true;
                    currentActivity = Activity();
                  });
                },
                child: const Text('Record Activity'),
              ),
            )
          ] else if (recording && !saving) ...[
            ListTile(
              leading: const Icon(Icons.location_pin),
              title: const Text("Distance"),
              trailing: Chip(
                label: Text(currentActivity.distance.toStringAsFixed(2)),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.location_pin),
              title: const Text("Speed"),
              trailing: Chip(
                label: Text(currentActivity.route.isNotEmpty
                    ? "${(currentActivity.route[currentActivity.route.length - 1].speed * 2.23694) // m/s to mph
                        .toStringAsFixed(2)} mph"
                    : "0 mph"),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.location_pin),
              title: const Text("Time"),
              trailing: Chip(
                label: Text(formatDuration(
                    DateTime.now().difference(currentActivity.start))),
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  recording = false;
                  saving = true;
                  currentActivity.end = DateTime.now();
                });
              },
              child: const Text('Stop Recording'),
            )
          ] else ...[
            Text(
              "Congrats! You saved ${calcSavings().toStringAsFixed(2)} pounds of CO₂!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DropdownMenu(
              label: const Text("Activity Kind"),
              initialSelection: "walk",
              dropdownMenuEntries: const [
                // carpool, bike, walk, bus, ev
                DropdownMenuEntry(value: "carpool", label: "Carpool"),
                DropdownMenuEntry(value: "bike", label: "Bike"),
                DropdownMenuEntry(value: "walk", label: "Walk"),
                DropdownMenuEntry(value: "bus", label: "Bus"),
                DropdownMenuEntry(value: "ev", label: "Electric Vehicle"),
                DropdownMenuEntry(value: "hybrid", label: "Hybrid Vehicle"),
              ],
              onSelected: (kind) {
                setState(() {
                  currentActivity.kind = kind!;
                });
              },
              width: MediaQuery.of(context).size.width - 20,
            ),
            if (currentActivity.kind == "carpool" ||
                currentActivity.kind == "hybrid" ||
                currentActivity.kind == "ev") ...[
              const SizedBox(height: 20),
              const Text("Carpool Members"),
              Slider(
                value: currentActivity.carpoolCount.toDouble(),
                min: 1,
                max: 8,
                divisions: 8,
                label: currentActivity.carpoolCount.toString(),
                onChanged: (double value) {
                  setState(() {
                    currentActivity.carpoolCount = value.toInt();
                  });
                },
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploading ? null : save,
              child: const Text('Upload Activity'),
            )
          ]
        ],
      ),
    );
  }
}
