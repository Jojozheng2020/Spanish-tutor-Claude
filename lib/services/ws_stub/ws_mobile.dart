// Android/桌面平台的真实 WebSocket 实现
import 'dart:async';
import 'dart:io' as io;

class PlatformWebSocket {
  io.WebSocket? _ws;
  bool _connected = false;

  bool get isConnected => _connected;

  Future<void> connect(
    String url,
    Map<String, dynamic> headers, {
    required void Function(dynamic data) onMessage,
    required void Function() onDone,
    required void Function(Object error) onError,
  }) async {
    _ws = await io.WebSocket.connect(
      url,
      headers: headers,
    );
    _connected = true;
    _ws!.listen(
      onMessage,
      onDone: onDone,
      onError: onError,
      cancelOnError: false,
    );
  }

  void send(String data) {
    if (_ws != null && _connected) {
      try {
        _ws!.add(data);
      } catch (_) {}
    }
  }

  Future<void> close() async {
    _connected = false;
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
  }
}
