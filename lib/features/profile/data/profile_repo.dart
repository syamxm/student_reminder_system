import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_profile_model.dart';

class ProfileRepo {
  ProfileRepo({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String get _uid {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('User is not signed in.');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _profileRef =>
      _firestore.collection('users').doc(_uid).collection('profile').doc(_uid);

  Stream<UserProfileModel?> watchProfile() {
    return _profileRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    });
  }

  Future<UserProfileModel?> getProfile() async {
    final doc = await _profileRef.get();
    if (!doc.exists) return null;
    return UserProfileModel.fromFirestore(doc);
  }

  Future<void> saveProfile(UserProfileModel profile) async {
    await _profileRef.set(profile.toMap(), SetOptions(merge: true));
  }
}
