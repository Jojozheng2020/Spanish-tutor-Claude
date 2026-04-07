import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

// ============================================================
// SettingsService — 管理 API Key 等用户配置
// 修复：API Key 通过 SharedPreferences 持久化，不硬编码
// ============================================================

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ---- API Key ----

  Future<String> getApiKey() async {
    final sp = await _sp;
    return sp.getString(AppConstants.prefApiKey) ?? '';
  }

  Future<void> saveApiKey(String key) async {
    final sp = await _sp;
    await sp.setString(AppConstants.prefApiKey, key);
  }

  // ---- 音色 ----

  Future<String> getVoice() async {
    final sp = await _sp;
    return sp.getString(AppConstants.prefVoice) ?? AppConstants.defaultVoice;
  }

  Future<void> saveVoice(String voice) async {
    final sp = await _sp;
    await sp.setString(AppConstants.prefVoice, voice);
  }

  // ---- 端点（国内 / 国际）----

  Future<bool> getUseIntlEndpoint() async {
    final sp = await _sp;
    return sp.getBool(AppConstants.prefUseIntlEndpoint) ?? false;
  }

  Future<void> saveUseIntlEndpoint(bool value) async {
    final sp = await _sp;
    await sp.setBool(AppConstants.prefUseIntlEndpoint, value);
  }

  // ---- 是否首次使用 ----

  Future<bool> isFirstLaunch() async {
    final sp = await _sp;
    return sp.getBool('first_launch') ?? true;
  }

  Future<void> setFirstLaunchDone() async {
    final sp = await _sp;
    await sp.setBool('first_launch', false);
  }
}
