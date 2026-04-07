// AudioService — 薄包装层，委托给平台实现
// Web → audio_stub/audio_web.dart（空实现）
// Android → audio_stub/audio_mobile.dart（flutter_sound 真实实现）
export 'platform_audio.dart' show PlatformAudio;

// 为保持 CallController 中的调用兼容，提供 AudioService 别名
import 'platform_audio.dart';
typedef AudioService = PlatformAudio;
