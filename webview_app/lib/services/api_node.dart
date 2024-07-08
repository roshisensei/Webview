import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NodeNotification {
  void SendNotification() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final fcmTokens = await prefs.getString("fcmToken");
      print('ffcmToken: $fcmTokens');
      http.Response res = await http.post(
        Uri.parse('http://192.168.1.38:3000/send-notification'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          {
            "fcmToken": fcmTokens, 
            "title": "Notification Testing",
            "body": "Hello Mic Testing"
          },
        ),
      );
      if (res.statusCode != 201) {
        print('errorOcurred\n\n\n\n\n\n\n\n\n\n\n\n');
      } else {
        print('Notification Sent Successfully\n\n\n\n\n\n\n\n\n');
      }
    } catch (err) {
      print('ErrorPrint: $err');
    }
  }
}
