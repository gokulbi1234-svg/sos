import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {

  static FlutterSoundRecorder recorder = FlutterSoundRecorder();

  static bool isRecording = false;

  static Future<String?> startAudioRecording() async {

    if (isRecording) {
      print("Recorder already running");
      return null;
    }

    isRecording = true;

    await recorder.openRecorder();

    Directory dir = Directory("/storage/emulated/0/SOS_Audio");

if (!await dir.exists()) {
  await dir.create(recursive: true);
}
    String path =
        "${dir.path}/sos_audio_${DateTime.now().millisecondsSinceEpoch}.aac";

    await recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );

    // record for 5 seconds
    await Future.delayed(const Duration(seconds: 5));

    await recorder.stopRecorder();

    await recorder.closeRecorder(); // VERY IMPORTANT

    isRecording = false;

    print("Audio saved at: $path");

    return path;
  }
}