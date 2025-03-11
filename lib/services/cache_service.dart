import 'package:shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

  Future<void> cacheDataWithCompression(String key, dynamic data) async {
    final compressed = await compute(_compressData, jsonEncode(data));
    await _prefs.setString(key, base64Encode(compressed));
  }

  Future<T?> getCompressedData<T>(
    String key, 
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final compressed = _prefs.getString(key);
    if (compressed != null) {
      final decompressed = await compute(
        _decompressData, 
        base64Decode(compressed),
      );
      return fromJson(jsonDecode(decompressed));
    }
    return null;
  }

  Future<void> clearExpiredCache() async {
    final keys = _prefs.getKeys();
    final now = DateTime.now();
    
    for (final key in keys) {
      final data = await getEncryptedData(key, (json) => json);
      if (data != null && data['expiry'] != null) {
        final expiry = DateTime.parse(data['expiry']);
        if (expiry.isBefore(now)) {
          await _prefs.remove(key);
        }
      }
    }
  }
}
