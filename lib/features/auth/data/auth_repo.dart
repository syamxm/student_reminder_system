import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepo {
  AuthRepo({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    final UserCredential credential;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      credential = await _auth.signInWithPopup(googleProvider);
    } else {
      try {
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;

        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw FirebaseAuthException(
            code: 'missing-google-id-token',
            message: 'Google sign-in failed because no ID token was returned.',
          );
        }

        final googleCredential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        credential = await _auth.signInWithCredential(googleCredential);
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return null;
        }
        rethrow;
      }
    }

    await _createOrUpdateUserProfile(
      user: credential.user,
      authProvider: 'google',
    );

    return credential;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }

    await _auth.signOut();
  }

  Future<void> _createOrUpdateUserProfile({
    required User? user,
    required String authProvider,
  }) async {
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'No authenticated user found.',
      );
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userRef.get();

    final userData = <String, dynamic>{
      'uid': user.uid,
      'displayName': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL,
      'authProvider': authProvider,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!userSnapshot.exists) {
      userData.addAll({
        'username': '',
        'streakCount': 0,
        'lastStreakDate': null,
        'missedDeadlinesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await userRef.set(userData, SetOptions(merge: true));
  }
}
