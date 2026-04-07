// 平台条件导出：编译期自动选择实现
export 'ws_stub/ws_mobile.dart'
    if (dart.library.html) 'ws_stub/ws_web.dart';
