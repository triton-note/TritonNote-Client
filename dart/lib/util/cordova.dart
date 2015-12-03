library triton_note.util.cordova;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';

final _logger = new Logger('Cordova');

final bool isCordova = window.location.protocol == "file:";

Completer<String> _onDeviceReady;

void onDeviceReady(proc(String)) {
  if (_onDeviceReady == null) {
    _onDeviceReady = new Completer<String>();
    if (isCordova) {
      document.on['deviceready'].listen((event) {
        _onDeviceReady.complete("cordova");
      });
    } else _onDeviceReady.complete("browser");
  }
  _onDeviceReady.future.then(proc);
}

void hideSplashScreen() {
  final splash = context['navigator']['splashscreen'];
  if (splash != null) {
    _logger.info("Hide SplashScreen.");
    splash.callMethod('hide', []);
  }
}

String get platformName => context['device']['platform'];
bool get isAndroid => platformName == "Android";
