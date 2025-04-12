import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String university,
    required String department,
    required int graduationYear,
  }) async {
    try {
      // Validate university email domain
      bool isValidUniversityEmail = false;
      
      for (var entry in AppConstants.universityEmailDomains.entries) {
        if (email.endsWith('@${entry.value}') && 
            university.contains(entry.key)) {
          isValidUniversityEmail = true;
          break;
        }
      }
      
      if (!isValidUniversityEmail) {
        throw FirebaseAuthException(
          code: 'invalid-email-domain',
          message: 'Please use your university email address for registration.',
        );
      }

      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _createUserDocument(
        uid: result.user!.uid,
        email: email,
        fullName: fullName,
        university: university,
        department: department,
        graduationYear: graduationYear,
      );

      // Send email verification
      await result.user!.sendEmailVerification();

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String fullName,
    required String university,
    required String department,
    required int graduationYear,
  }) async {
    UserModel newUser = UserModel(
      uid: uid,
      email: email,
      fullName: fullName,
      university: university,
      department: department,
      graduationYear: graduationYear,
      verificationStatus: AppConstants.verificationStatusPending,
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(newUser.toMap());
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last active timestamp
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastActive': DateTime.now(),
      });

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Verify user's university email
  Future<bool> verifyUniversityEmail() async {
    try {
      User? user = currentUser;
      if (user == null) return false;

      // Reload user to get the latest email verification status
      await user.reload();
      user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        // Update verification status in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'verificationStatus': AppConstants.verificationStatusVerified,
        });
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Check if email is from a supported university
  bool isUniversityEmail(String email) {
    for (var domain in AppConstants.universityEmailDomains.values) {
      if (email.endsWith('@$domain')) {
        return true;
      }
    }
    return false;
  }
}
