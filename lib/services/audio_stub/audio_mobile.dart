// Android 平台真实音频实现
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../constants_ref.dart';

class PlatformAudio {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  StreamController<Uint8List>? _recordStreamController;
  bool _isRecording = false;
  bool _isPlayerOpen = false;
  bool _isRecorderOpen = false;
  bool _isPlaying = false;

  final List<Uint8List> _audioQueue = [];
  bool _isFeedingAudio = false;

  Function(String base64Audio)? onAudioChunk;

  Future<void> init() async {
    if (!_isRecorderOpen) {
      await _recorder.openRecorder();
      _isRecorderOpen = true;
    }
    if (!_isPlayerOpen) {
      await _player.openPlayer();
      _isPlayerOpen = true;
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    if (!_isRecorderOpen) await init();

    _recordStreamController = StreamController<Uint8List>();
    _recordStreamController!.stream.listen((Uint8List data) {
      for (var i = 0; i < data.length; i += AudioConstants.audioChunkBytes) {
        final end = (i + AudioConstants.audioChunkBytes > data.length)
            ? data.length
            : i + AudioConstants.audioChunkBytes;
        onAudioChunk?.call(base64.encode(data.sublist(i, end)));
      }
    });

    await _recorder.startRecorder(
      codec: Codec.pcm16,
      sampleRate: AudioConstants.inputSampleRate,
      numChannels: AudioConstants.inputChannels,
      toStream: _recordStreamController!.sink,
    );
    _isRecording = true;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _recorder.stopRecorder();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await _recordStreamController?.close();
    _recordStreamController = null;
  }

  Future<void> feedAudio(List<int> pcmBytes) async {
    _audioQueue.add(Uint8List.fromList(pcmBytes));
    if (!_isFeedingAudio) _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isFeedingAudio) return;
    _isFeedingAudio = true;
    while (_audioQueue.isNotEmpty) {
      final chunk = _audioQueue.removeAt(0);
      try {
        if (!_isPlaying) {
          if (!_isPlayerOpen) await init();
          await _player.startPlayerFromStream(
            codec: Codec.pcm16,
            sampleRate: AudioConstants.outputSampleRate,
            numChannels: AudioConstants.outputChannels,
          );
          _isPlaying = true;
        }
        await _player.feedFromStream(chunk);
      } catch (e) {
        if (kDebugMode) debugPrint('[PlatformAudio] feedAudio: $e');
        break;
      }
    }
    _isFeedingAudio = false;
  }

  Future<void> stopPlayback() async {
    _audioQueue.clear();
    _isFeedingAudio = false;
    try {
      if (_isPlaying) {
        await _player.stopPlayer();
        _isPlaying = false;
      }
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> dispose() async {
    await stopRecording();
    await stopPlayback();
    if (_isRecorderOpen) {
      await _recorder.closeRecorder();
      _isRecorderOpen = false;
    }
    if (_isPlayerOpen) {
      await _player.closePlayer();
      _isPlayerOpen = false;
    }
  }

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
}
