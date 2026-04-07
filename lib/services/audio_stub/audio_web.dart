// Web 平台 Audio Stub — 不引用 flutter_sound，避免崩溃
import 'dart:async';

class PlatformAudio {
  Function(String base64Audio)? onAudioChunk;

  Future<void> init() async {}
  Future<void> startRecording() async {}
  Future<void> stopRecording() async {}
  Future<void> feedAudio(List<int> pcmBytes) async {}
  Future<void> stopPlayback() async {}
  Future<void> dispose() async {}

  bool get isRecording => false;
  bool get isPlaying => false;
}
