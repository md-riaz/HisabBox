import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinLockService {
  PinLockService._();

  static final PinLockService instance = PinLockService._();

  static const _pinHashKey = 'security.pin_hash';

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinHashKey);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, _hashPin(pin));
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinHashKey);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinHashKey);
    if (storedHash == null) {
      return false;
    }
    return storedHash == _hashPin(pin);
  }

  String _hashPin(String pin) {
    final normalized = pin.trim();
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }
}
