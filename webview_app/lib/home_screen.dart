import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_app/services/api_node.dart';
import 'package:workmanager/workmanager.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

var homeScreenUrl =
// 'https://www.jugaadcity.com/auth/sign-in';
    'https://www.bestcolleges.com/bootcamps/guides/best-youtube-channels-learn-coding/';
// 'https://www.shiksha.com/online-courses/articles/learn-to-code-for-free-on-top-7-youtube-programming-channels/';
// 'https://stockmarketwhatsappgroup.github.io/index.html'; // for whatsapp telegram links
// 'https://www.makeuseof.com/stop-google-sign-in-pop-ups/';

// "https://www.nanowerk.com/25-Best-Free-Anime-Streaming-Sites-to-Watch-Anime-Online.php"; // for google chrome

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.url = ''});
  final String url;
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late InAppWebViewController webViewController;
  late PullToRefreshController refreshController;
  late InAppWebViewController _webViewPopupController;
  // ignore: prefer_typing_uninitialized_variables
  late var url;
  String title = '';
  var initialUrl = homeScreenUrl;
  double _progress = 0;
  var urlController = TextEditingController();
  var willPop = false;
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];
  String text = '';

  NodeNotification notification = NodeNotification();

  @override
  void initState() {
    super.initState();
    refreshController = PullToRefreshController(
      onRefresh: () {
        webViewController.reload();
      },
      settings: PullToRefreshSettings(
        color: Colors.white,
        backgroundColor: Colors.black,
        // this setting changes the distance up to which it must pulled to reload
        distanceToTriggerSync: 300,
      ),
    );

    // Receive shared text from outside the app
    // Listen to text sharing coming from outside the app while the app is in memory.
    _intentSub =
        ReceiveSharingIntent.instance.getMediaStream().listen((value) async {
      print(value.map((f) => f.toMap()));
      print(value[0].duration);
      print(value[0].message);
      print(value[0].mimeType);
      print(value[0].path);
      print(value[0].thumbnail);
      print(value[0].type);
      text = value[0].path;

      // setState(() {
      //api request
      await webViewController.loadUrl(
          urlRequest: URLRequest(
              url: WebUri.uri(Uri.parse('https://www.google.com/'))));
      // _sharedFiles.clear();
      _sharedFiles.addAll(value);
      // });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      text = value[0].path;
      // setState(() {
      if (text.isNotEmpty) {
        webViewController.loadUrl(
          urlRequest: URLRequest(
            url: WebUri.uri(
              Uri.parse(
                'https://www.google.com/',
              ),
            ),
          ),
        );
      }
      // _sharedFiles.clear();
      _sharedFiles.addAll(value);

      // Tell the library that we are done processing the intent.
      ReceiveSharingIntent.instance.reset();
      // });
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SizedBox(
        width: 85.0,
        height: 85.0,
        child: ElevatedButton(
          onPressed: () async {
            await Workmanager().registerPeriodicTask(
              'workmanager',
              'taskone',
              frequency: const Duration(
                minutes: 15,
              ),
              constraints: Constraints(
                networkType: NetworkType.connected,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16.0),
              backgroundColor: const Color.fromARGB(255, 201, 213, 235)),
          child: const Text(
            'Periodic Task',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: Color.fromARGB(255, 73, 57, 75)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () async {
              if (await webViewController.canGoBack()) {
                webViewController.goBack();
              }
            },
            icon: const Icon(Icons.arrow_back)),
        backgroundColor: Colors.blueAccent,
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onSubmitted: (value) {},
              controller: urlController,
              textAlignVertical: TextAlignVertical.center,
              decoration: const InputDecoration(
                hintText: 'eg. google.com',
                prefixIcon: Icon(
                  Icons.search,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              webViewController.reload();
            },
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WillPopScope(
            onWillPop: () async {
              final url = await webViewController.getUrl();
              final String urls = url.toString();
              // urls -> home screen url
              if (urls == homeScreenUrl) {
                webViewController.clearHistory();
              }
              final bool canGoBack = await webViewController.canGoBack();
              if (canGoBack) {
                await webViewController.goBack();
                return Future.value(false);
              }
              return Future.value(true);
            },
            child: InAppWebView(
              initialSettings: InAppWebViewSettings(
                // prevent from zooming
                builtInZoomControls: false,
                allowBackgroundAudioPlaying: true,
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: false,
                useHybridComposition: true,
                javaScriptCanOpenWindowsAutomatically: true,
                supportMultipleWindows: true,
                userAgent:
                    'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.5304.105 Mobile Safari/537.36',
                // max & min zoom
              ),
              onLoadStart: (controller, url) {
                var u = url.toString();
                setState(() {
                  urlController.text = u;
                });
                // if (url.startsWith('https://example.com/launchapp')) {
                //   launchExternalApp(url);
                // }
              },
              onLoadStop: (controller, url) {
                refreshController.endRefreshing();
              },
              pullToRefreshController: refreshController,
              onWebViewCreated: (controller) async {
                webViewController = controller;
                if (_sharedFiles.isNotEmpty) {
                  await webViewController.evaluateJavascript(source: '''
        function showAlert(text) {
          alert(text);
        }
        showAlert("$text");
      ''');
                }
              },
              initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              // shouldOverrideUrlLoading: (controller, navigationAction) async {
              //   final urls = Uri.parse(navigationAction.request.url.toString());
              //   print('hello konichiwa ${urls.toString()}');
              //   if (await canLaunchUrl(urls)) {
              //     await launchUrl(urls, mode: LaunchMode.externalApplication);

              //     return NavigationActionPolicy.CANCEL;
              //   } else {
              //     print('Error opening Url: ${url}');
              //     return NavigationActionPolicy.ALLOW;
              //   }
              // },
              onCreateWindow: (
                controller,
                createWindowAction,
              ) async {
                print('kimi no nawa');
                final urls =
                    Uri.parse(createWindowAction.request.url.toString());
                if (await canLaunchUrl(urls) &&
                    (!urls
                        .toString()
                        .startsWith('https://accounts.google.com')) &&
                    (!urls
                        .toString()
                        .startsWith('https://Ih3.googleusercontent.com/'))) {
                  await launchUrl(urls, mode: LaunchMode.externalApplication);
                  return false;
                } else {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return WindowPopup(
                          createWindowAction: createWindowAction);
                    },
                  );
                  return true;
                }
              },
            ),
          ),
          if (_progress < 1)
            LinearProgressIndicator(
              value: _progress,
            )
          else
            const SizedBox(),
          ElevatedButton(
              onPressed: () {
                notification.SendNotification();
              },
              child: Text('Notification'))
        ],
      ),
    );
  }
}

class WindowPopup extends StatefulWidget {
  final CreateWindowAction createWindowAction;

  const WindowPopup({Key? key, required this.createWindowAction})
      : super(key: key);

  @override
  State<WindowPopup> createState() => _WindowPopupState();
}

class _WindowPopupState extends State<WindowPopup> {
  String title = '';

  @override
  Widget build(BuildContext context) {
    print('moshi moshi once again');
    return AlertDialog(
      content: SizedBox(
        width: double.infinity,
        height: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.max, children: [
              Expanded(
                child:
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close))
            ]),
            Expanded(
              child: InAppWebView(
                initialSettings: InAppWebViewSettings(
                    useShouldOverrideUrlLoading: false,
                    supportMultipleWindows: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    javaScriptEnabled: true),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                windowId: widget.createWindowAction.windowId,
                onTitleChanged: (controller, title) {
                  setState(() {
                    this.title = title ?? '';
                  });
                },
                onCloseWindow: (controller) {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


 // onCreateWindow: (
              //   controller,
              //   createWindowAction,
              // ) async {
              //   print('kimi no nawa');

              //   final urls = Uri.parse(controller.getUrl().toString());
              //   print('hello konichiwa ${urls.toString()}');
              //   // if (await canLaunchUrl(urls)) {
              //   //   await launchUrl(urls, mode: LaunchMode.externalApplication);
              //   if (![
              //     "http",
              //     "https",
              //     "file",
              //     "chrome",
              //     "data",
              //     "javascript",
              //     "about"
              //   ].contains(urls.scheme)) {
              //     if (await canLaunchUrl(url)) {
              //       // Launch the App
              //       await launchUrl(
              //         url,
              //       );
              //       return false;
              //     } else {
              //       print('Error opening Url: ${url}');
              //       return true;
              //     }
              //   } else {
              //     showDialog(
              //       context: context,
              //       builder: (context) {
              //         return WindowPopup(
              //             createWindowAction: createWindowAction);
              //       },
              //     );
              //     return true;
              //   }
              // },

                                // if (![
                  //   "http",
                  //   "https",
                  //   "file",
                  //   "chrome",
                  //   "data",
                  //   "javascript",
                  //   "about"
                  // ].contains(urls.scheme)) {
                  //   if (await canLaunchUrl(url)) {
                  //     // Launch the App
                  //     await launchUrl(url, mode: LaunchMode.externalApplication);