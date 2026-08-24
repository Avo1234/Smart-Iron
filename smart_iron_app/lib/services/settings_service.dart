import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _deviceKey = 'remembered_device';
  static const _alertsKey = 'safety_alerts';
  Future<String?> rememberedDevice() async =>
      (await SharedPreferences.getInstance()).getString(_deviceKey);
  Future<void> rememberDevice(String id) async =>
      (await SharedPreferences.getInstance()).setString(_deviceKey, id);
  Future<void> forgetDevice() async =>
      (await SharedPreferences.getInstance()).remove(_deviceKey);
  Future<bool> alertsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_alertsKey) ?? true;
  Future<void> setAlertsEnabled(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(_alertsKey, value);
}
