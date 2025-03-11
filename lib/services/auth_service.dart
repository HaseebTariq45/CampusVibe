import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool isValidUniversityEmail(String email) {
    // List of approved university domains
    const List<String> validDomains = [
      'edu.pk',
      'lums.edu.pk',
      'uet.edu.pk',
      // Add more university domains
    ];
    
    return validDomains.any((domain) => email.toLowerCase().endsWith(domain));
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    if (!isValidUniversityEmail(email)) {
      throw 'Please use your university email address';
    }
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<UserModel?> registerWithEmail(
    String email, 
    String password, 
    String name,
    String university,
    String department,
    int year
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      
      if (user != null) {
        final UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email!,
          name: name,
          university: university,
          department: department,
          year: year,
        );
        
        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
        return newUser;
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data()!);
        }
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toJson());
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<String> uploadProfileImage(String uid, String imagePath) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');
      
      await ref.putFile(File(imagePath));
      return await ref.getDownloadURL();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      print('Error using biometrics: $e');
      return false;
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> resetPassword(String email) async {
    if (!isValidUniversityEmail(email)) {
      throw 'Please use your university email address';
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> refreshUserSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await user.getIdToken(true);
      await _firestore.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
        'deviceInfo': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        },
      });
    } catch (e) {
      print('Error refreshing session: $e');
      rethrow;
    }
  }

  Future<void> updateUserStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] ?? false);
  }
}
