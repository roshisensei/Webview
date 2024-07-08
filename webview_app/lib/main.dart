import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_app/firebase_options.dart';
import 'package:webview_app/home_screen.dart';
import 'package:webview_app/no_internet_screen.dart';
import 'package:webview_app/services/firebase_api.dart';
import 'package:webview_app/services/notification_service.dart';
import 'package:workmanager/workmanager.dart';

// this denotes the entry point of a function which will communicate with native feature
@pragma('vm:entry-point')
late AudioHandler _audioHandler;

// this callbackdispatcher function must be static or top level/global function
void callBackDispatcher() {
  Workmanager().executeTask((taskName, inputData) {
    NotificationService().showNotification(
        title: 'Sample title', body: 'It works! ${DateTime.now()}');
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final _firebaseMessaging = FirebaseMessaging.instance;
  await _firebaseMessaging.getToken().then(
    (token) {
      _updateFCMToken(token!);
    },
  );
  // Listen for token updates
  _firebaseMessaging.onTokenRefresh.listen((token) {
    _updateFCMToken(token);
  });
  // intitialize firebase messaging
  await FirebaseApi().initNotifications();

  // initialize local notification
  await FirebaseApi().localNotiInit();

  await Permission.notification.request();

  // for background task
  await Workmanager().initialize(callBackDispatcher, isInDebugMode: true);
  runApp(const MyApp());
}

// Update and store FCM token in shared preferences
Future<void> _updateFCMToken(String token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcmToken', token);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView SearchEngine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InternetConnectionListener(),
    );
  }
}

class InternetConnectionListener extends StatefulWidget {
  const InternetConnectionListener({super.key});

  @override
  InternetConnectionListenerState createState() =>
      InternetConnectionListenerState();
}

class InternetConnectionListenerState
    extends State<InternetConnectionListener> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() {
      isConnected = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return MaterialApp(
          title: 'WebView SearchEngine',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: isConnected ? const HomeScreen() : const NoInternetScreen(),
        );
      },
    );
  }
}
