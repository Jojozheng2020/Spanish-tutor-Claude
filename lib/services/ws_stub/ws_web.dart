// Web 平台的 WebSocket Stub — Web 不支持真实语音通话
import 'dart:async';

class PlatformWebSocket {
  bool get isConnected => false;

  Future<void> connect(
    String url,
    Map<String, dynamic> headers, {
    required void Function(dynamic data) onMessage,
    required void Function() onDone,
    required void Function(Object error) onError,
  }) async {
    // Web 平台不支持 dart:io WebSocket + 自定义 Header
    // 直接触发错误回调，展示友好提示
    Future.delayed(const Duration(milliseconds: 300), () {
      onError(Exception('web_not_supported'));
    });
  }

  void send(String data) {}

  Future<void> close() async {}
}
