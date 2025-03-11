import 'package:shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class CacheService {
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  Future<void> cacheData(String key, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  T? getCachedData<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final data = _prefs.getString(key);
    if (data != null) {
      return fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<void> cacheWithExpiry(String key, dynamic data, Duration expiry) async {
    final expiryTime = DateTime.now().add(expiry);
    final encryptedData = await _encryptData(jsonEncode({
      'data': data,
      'expiry': expiryTime.toIso8601String(),
    }));
    
    await _prefs.setString(key, encryptedData);
  }

  Future<T?> getEncryptedData<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final encryptedData = _prefs.getString(key);
    if (encryptedData != null) {
      final decrypted = await _decryptData(encryptedData);
      final data = jsonDecode(decrypted);
      
      if (DateTime.parse(data['expiry']).isAfter(DateTime.now())) {
        return fromJson(data['data']);
      } else {
        await _prefs.remove(key);
      }
    }
    return null;
  }
}
