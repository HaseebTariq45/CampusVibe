import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _currentUser;
  bool _isLoading = false;

  AuthProvider({required AuthService authService}) : _authService = authService {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Listen to auth state changes
    _authService.userStream.listen((User? user) async {
      if (user != null) {
        // User is signed in, get user data from Firestore
        try {
          _currentUser = await _authService.getCurrentUserData();
        } catch (e) {
          _currentUser = null;
        }
      } else {
        // User is signed out
        _currentUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> refreshUserData() async {
    try {
      _currentUser = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<bool> verifyEmail() async {
    try {
      bool result = await _authService.verifyUniversityEmail();
      if (result) {
        await refreshUserData();
      }
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}
