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
}
