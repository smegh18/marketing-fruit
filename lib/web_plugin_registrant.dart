// lib/web_plugin_registrant.dart
import 'package:just_audio_web/just_audio_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins(Registrar registrar) {
  JustAudioPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
