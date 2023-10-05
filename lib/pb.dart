import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pb {
  static late SharedPreferences prefs;
  static late PocketBase pb;
  static bool initialized = false;

  static Future init() async {
    if (initialized) {
      return;
    }

    prefs = await SharedPreferences.getInstance();
    pb = PocketBase('https://commuter.nv7haven.com/',
        authStore: AsyncAuthStore(
          save: (String data) async => prefs.setString('pb_auth', data),
          initial: prefs.getString('pb_auth'),
        ));
    initialized = true;
  }
}

class RoutePoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double time;

  RoutePoint(
      this.latitude, this.longitude, this.altitude, this.speed, this.time);

  Map toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'speed': speed,
        'time': time,
      };
}

class Activity {
  double distance = 0;
  DateTime start = DateTime.now(); // format yyyy-MM-dd HH:mm:ss.SSSZ
  DateTime end = DateTime.now(); // format yyyy-MM-dd HH:mm:ss.SSSZ
  List<RoutePoint> route = [];
  String kind = "walk"; // carpool, bike, walk, bus, ev
  String kindData = "{}";
  double savings = 0;
}
