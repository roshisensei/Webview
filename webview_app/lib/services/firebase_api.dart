import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_notification_channel/flutter_notification_channel.dart';
import 'package:webview_app/home_screen.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

// all the firebase notification api are here
class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    const HomeScreen();
  }

  // request notification permission
  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();

    // get the device fcm token
    final fcmToken = await _firebaseMessaging.getToken();

    // storing token in shared Preferences to make api call to node backend in future
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcmToken', fcmToken!);

    print('Token: ${fcmToken}');
    initPushNotifications();
  }

  Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(
        handleMessage); // this handle the action when we open our terminated app via notification
    FirebaseMessaging.onMessageOpenedApp.listen(
        handleMessage); // this will handle the action when we open our app which is in background via notification
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String payload = jsonEncode(message.data);
      print("got a message in foregreound");
      if (message.notification != null) {
        showNotification(
            title: message.notification!.title,
            body: message.notification!.body,
            payLoad: payload);
      }
    });
  }

  // initialize local notification
  Future<void> localNotiInit() async {
    // set notification icon
    AndroidInitializationSettings initializationSettingsAndroid =
        const AndroidInitializationSettings('ic_launcher');

    // request Notification for android 13 or above

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()!
        .requestNotificationsPermission();

    // ios setting
    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) {});

    // android setting
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationTap);
  }

  // on tap local notification in foreground
  static void onNotificationTap(NotificationResponse notificationResponse) {
    const HomeScreen();
  }

  Future showNotification(
      {int id = 0, String? title, String? body, String? payLoad}) async {
    const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails('channelId', 'channelName',
            importance: Importance.max),
        iOS: DarwinNotificationDetails());
    return _flutterLocalNotificationsPlugin
        .show(id, title, body, notificationDetails, payload: payLoad);
  }
}
