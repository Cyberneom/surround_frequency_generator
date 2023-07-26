import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:surround_sound/src/sound_controller.dart';
import 'package:surround_sound/src/web_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class SoundWidget extends StatefulWidget {
  final SoundController soundController;
  final Color backgroundColor;
  WebViewController? webViewAndroidController;
  PlatformWebViewController? webViewIosController;

  SoundWidget({
    Key? key,
    required this.soundController,
    this.backgroundColor = Colors.white,
    this.webViewAndroidController,
    this.webViewIosController,
  }) : super(key: key);

  @override
  _SoundWidgetState createState() => _SoundWidgetState();
}

class _SoundWidgetState extends State<SoundWidget> {
  late String htmlText;
  late WebViewController webViewAndroidController;

  PlatformWebViewCookieManager? cookieManager;
  late PlatformWebViewController webViewIosController;

  @override
  void initState() {
    super.initState();
    if(widget.webViewAndroidController != null) {
      webViewAndroidController = widget.webViewAndroidController!;
    } else if(widget.webViewIosController != null) {
      webViewIosController = widget.webViewIosController!;
    }

    _init();
  }

  @override
  void dispose() {
    if(Platform.isAndroid) {
      webViewAndroidController.clearCache(); // Clear the WebView cache (optional)
      webViewAndroidController.goBack();    // Dispose of the WebView
    } else {
      webViewIosController.clearCache();
      webViewIosController.goBack();
    }

    super.dispose();
  }

  void _init() {

    final color = widget.backgroundColor.value.toRadixString(16).substring(2);
    final String htmlBase64 = base64Encode(
      const Utf8Encoder().convert(html('#$color')),
    );

    if(Platform.isAndroid) {
      setWebViewForAndroid(Uri.parse('data:text/html;base64,$htmlBase64'));
    } else {
      setWebViewForIOS(Uri.parse('data:text/html;base64,$htmlBase64'));
    }

  }

  @override
  void didUpdateWidget(SoundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.backgroundColor != oldWidget.backgroundColor) {
      _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: 1,
      child: Platform.isAndroid ? WebViewWidget(
        controller: webViewAndroidController,
      ) : PlatformWebViewWidget(
        PlatformWebViewWidgetCreationParams(controller: webViewIosController),
      ).build(context),
    );
  }

  void setWebViewForAndroid(Uri uri) {

    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    webViewAndroidController = WebViewController.fromPlatformCreationParams(params);
    webViewAndroidController.setJavaScriptMode(JavaScriptMode.unrestricted);
    // #enddocregion platform_features
    webViewAndroidController.loadRequest(uri);
    webViewAndroidController.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            widget.soundController.complete(androidController: webViewAndroidController);
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            webViewAndroidController.runJavaScript('init_sound();');
            print('Page finished loading: $url');
          },
        )
    );
  }

  void setWebViewForIOS(Uri uri) {

    webViewIosController= PlatformWebViewController(
      WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setPlatformNavigationDelegate(
        PlatformNavigationDelegate(
          const PlatformNavigationDelegateCreationParams(),
        )
          ..setOnProgress((int progress) {
            print('WebView is loading (progress : $progress%)');
          })
          ..setOnPageStarted((String url) {
            widget.soundController.complete(iOSController: webViewIosController);
            print('Page started loading: $url');
          })
          ..setOnPageFinished((String url) {
            webViewIosController.runJavaScript('init_sound();');
            print('Page finished loading: $url');
          })
          ..setOnWebResourceError((WebResourceError error) {
            print('''
              Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
              url: ${error.url}
            ''');
          })
      )
      ..addJavaScriptChannel(JavaScriptChannelParams(
        name: 'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      ))
      ..setOnPlatformPermissionRequest(
            (PlatformWebViewPermissionRequest request) {
          debugPrint(
            'requesting permissions for ${request.types.map((WebViewPermissionResourceType type) => type.name)}',
          );
          request.grant();
        },
      )
      ..loadRequest(LoadRequestParams(uri: uri),);
  }

}
