import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'audio_param.dart';

class SoundController extends ValueNotifier<AudioParam> {

  WebViewController? _webViewAndroidController;
  Completer<WebViewController> _webAndroidController = Completer<WebViewController>();
  PlatformWebViewController? _webViewIOSController;
  Completer<PlatformWebViewController> _webIOSController = Completer<PlatformWebViewController>();

  SoundController() : super(AudioParam());

  set value(param) {
    setPosition(param.x, param.y, param.z);
    setFrequency(param.freq);
    setVolume(param.volume);
    super.value = param;
  }

  void complete({WebViewController? androidController, PlatformWebViewController? iOSController}) {
    if(Platform.isAndroid && androidController != null) {
      if (_webAndroidController.isCompleted) {
        _webAndroidController = Completer<WebViewController>();
        _webViewAndroidController = null;
      }
      _webAndroidController.complete(androidController);
    } else if(iOSController != null) {
      if (_webIOSController.isCompleted) {
        _webIOSController = Completer<PlatformWebViewController>();
        _webViewIOSController = null;
      }
      _webIOSController.complete(iOSController);
    }
  }

  Future init() async {

    try {
      if(Platform.isAndroid) {
        _webViewAndroidController = await _webAndroidController.future;
        await _webViewAndroidController!.runJavaScript('init_sound();');
      } else {
        _webViewIOSController = await _webIOSController.future;
        await _webViewIOSController!.runJavaScript('init_sound();');
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future _check() async {
    if(Platform.isAndroid) {
      if (_webViewAndroidController == null) {
        await init();
      }
    } else {
      if (_webViewIOSController == null) {
        await init();
      }
    }

  }

  Future play() async {
    await _check();
    if(Platform.isAndroid) {
      await _webViewAndroidController?.runJavaScript('play();');
    } else {
      await _webViewIOSController?.runJavaScript('play();');
    }
  }

  Future stop() async {
    await _check();
    if(Platform.isAndroid) {
      await _webViewAndroidController?.runJavaScript('stop();');
    } else {
      await _webViewIOSController?.runJavaScript('stop();');
    }
  }

  Future<bool> isPlaying() async {
    try {
      await _check();
      if(Platform.isAndroid) {
        final started = await _webViewAndroidController?.runJavaScriptReturningResult('started');
        if(started is bool) {return started;}
      } else {
        final started = await _webViewIOSController?.runJavaScriptReturningResult('started');
        if(started is bool) {return started;}
      }
    } catch (e) {
      print(e.toString());
    }

    return false;
  }

  Future setPosition(double x, double y, double z) async {
    await _check();
    x = x.clamp(-1.0, 1.0);
    y = y.clamp(-1.0, 1.0);
    z = z.clamp(-1.0, 1.0);
    super.value = super.value.copyWith(x: x, y: y, z: z);

    if(Platform.isAndroid) {
      await _webViewAndroidController?.runJavaScript('set_panner('
          '${x * 5.5 + 30}, '
          '${y * 5.5 + 30}, '
          '${z * 5.5 + 300}'
          ');');
    } else {
      await _webViewIOSController?.runJavaScript('set_panner('
          '${x * 5.5 + 30}, '
          '${y * 5.5 + 30}, '
          '${z * 5.5 + 300}'
          ');');
    }
  }

  Future forceSetFrequency(double freq) async {
    await _check();
    freq = freq.clamp(20.0, 20000.0);
    super.value = super.value.copyWith(freq: freq);

    if(Platform.isAndroid) {
      await _webViewAndroidController?.runJavaScript('force_set_freq($freq);');
    } else {
      await _webViewIOSController?.runJavaScript('force_set_freq($freq);');
    }

  }

  Future setFrequency(double freq) async {
    await _check();
    freq = freq.clamp(20.0, 20000.0);
    super.value = super.value.copyWith(freq: freq);
    if(Platform.isAndroid) {
      await _webViewAndroidController?.runJavaScript('set_freq($freq);');
    } else {
      await _webViewIOSController?.runJavaScript('set_freq($freq);');
    }
  }

  Future setVolume(double vol) async {
    await _check();
    vol = vol.clamp(0.0, 1.0);
    super.value = super.value.copyWith(volume: vol);
    if(Platform.isAndroid) {
      await _webViewAndroidController?.runJavaScript('set_volume($vol);');
    } else {
      await _webViewIOSController?.runJavaScript('set_volume($vol);');
    }
  }

}
