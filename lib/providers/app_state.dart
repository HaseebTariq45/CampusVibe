import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AppState extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isDarkMode = false;
  String _selectedLanguage = 'en';
  final AuthService _authService = AuthService();

  UserModel? get currentUser => _currentUser;
  bool get isDarkMode => _isDarkMode;
  String get selectedLanguage => _selectedLanguage;

  Future<void> initializeApp() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    await _authService.updateUserProfile(user);
    _currentUser = user;
    notifyListeners();
  }

  void setLanguage(String languageCode) {
    _selectedLanguage = languageCode;
    notifyListeners();
  }

  Future<void> handleError(dynamic error, StackTrace stackTrace) async {
    try {
      await _analyticsService.logError(
        error.toString(),
        stackTrace,
        _currentUser?.uid ?? 'unknown',
      );
      
      if (error is FirebaseAuthException) {
        // Handle auth errors
      } else if (error is TimeoutException) {
        // Handle timeout errors
      }
    } catch (e) {
      print('Error handling error: $e');
    }
  }
}
