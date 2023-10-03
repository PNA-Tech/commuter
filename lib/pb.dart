import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pb {
  static late SharedPreferences prefs;
  static late PocketBase pb;

  static Future init() async {
    prefs = await SharedPreferences.getInstance();
    pb = PocketBase('https://commuter.nv7haven.com/',
        authStore: AsyncAuthStore(
          save: (String data) async => prefs.setString('pb_auth', data),
          initial: prefs.getString('pb_auth'),
        ));
  }
}
