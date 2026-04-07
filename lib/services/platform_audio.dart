// 平台条件导出：编译期自动选择实现
export 'audio_stub/audio_mobile.dart'
    if (dart.library.html) 'audio_stub/audio_web.dart';
