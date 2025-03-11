import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class ErrorService {
  final FirebaseCrashlytics _crashlytics;
  final bool _isDevelopment = !kReleaseMode;

  ErrorService(this._crashlytics);

  Future<void> handleError(dynamic error, StackTrace? stackTrace, {String? userId}) async {
    if (_isDevelopment) {
      print('Error: $error\nStackTrace: $stackTrace');
      return;
    }

    await _crashlytics.setCustomKey('last_error', error.toString());
    if (userId != null) {
      await _crashlytics.setUserIdentifier(userId);
    }
    await _crashlytics.recordError(error, stackTrace);
  }
}
