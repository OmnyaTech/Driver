import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AndroidPermissionService {
  const AndroidPermissionService();

  static const _channel = MethodChannel('br.com.omnyatech.omnyadriver/android');
  static const _batteryPromptKey = 'driver_android_battery_prompt_v1';

  Future<void> requestStartupPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    await _invoke('requestNotificationPermission');
    await _requestBatteryOptimizationOnce();
  }

  Future<void> _requestBatteryOptimizationOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted = prefs.getBool(_batteryPromptKey) ?? false;
    final ignoring = await _invokeBool('isIgnoringBatteryOptimizations');
    if (alreadyPrompted || ignoring) return;

    final opened = await _invokeBool('requestIgnoreBatteryOptimizations');
    if (opened) {
      await prefs.setBool(_batteryPromptKey, true);
    }
  }

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } catch (_) {
      // Android permission prompts should not block app startup.
    }
  }

  Future<bool> _invokeBool(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (_) {
      return false;
    }
  }
}
