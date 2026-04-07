import 'package:flutter/foundation.dart';
import '../services/settings_service.dart';
import '../config/constants.dart';

class SettingsController extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  String _apiKey = '';
  String _voice = AppConstants.defaultVoice;
  bool _useIntlEndpoint = false;
  bool _isLoaded = false;

  String get apiKey => _apiKey;
  String get voice => _voice;
  bool get useIntlEndpoint => _useIntlEndpoint;
  bool get isLoaded => _isLoaded;
  bool get hasApiKey => _apiKey.isNotEmpty;

  // 脱敏显示
  String get apiKeyMasked {
    if (_apiKey.length < 8) return '未设置';
    return '${_apiKey.substring(0, 4)}****${_apiKey.substring(_apiKey.length - 4)}';
  }

  Future<void> load() async {
    _apiKey = await _service.getApiKey();
    _voice = await _service.getVoice();
    _useIntlEndpoint = await _service.getUseIntlEndpoint();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    _apiKey = key.trim();
    await _service.saveApiKey(_apiKey);
    notifyListeners();
  }

  Future<void> saveVoice(String voice) async {
    _voice = voice;
    await _service.saveVoice(voice);
    notifyListeners();
  }

  Future<void> saveUseIntlEndpoint(bool value) async {
    _useIntlEndpoint = value;
    await _service.saveUseIntlEndpoint(value);
    notifyListeners();
  }
}
