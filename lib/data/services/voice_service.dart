import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  Future<void> init() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<String> _getPath(String username) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/voice_$username.aac';
  }

  Future<void> startRecording(String username) async {
    final path = await _getPath(username);
    await _recorder.startRecorder(toFile: path);
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
  }

  Future<bool> voiceExists(String username) async {
    final path = await _getPath(username);
    return File(path).exists();
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
  }
}