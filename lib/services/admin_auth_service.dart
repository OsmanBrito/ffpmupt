import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminAuthService {
  AdminAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth,
      _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth? get _firebaseAuth {
    if (!_isFirebaseReady) {
      return null;
    }

    return _auth ?? FirebaseAuth.instance;
  }

  FirebaseFirestore? get _firebaseFirestore {
    if (!_isFirebaseReady) {
      return null;
    }

    return _firestore ?? FirebaseFirestore.instance;
  }

  Stream<User?> authStateChanges() {
    return _firebaseAuth?.authStateChanges() ?? Stream.value(null);
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      return null;
    }

    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user;
  }

  Future<bool> isAdmin(User? user, {required String countryCode}) async {
    final firestore = _firebaseFirestore;
    if (user == null || firestore == null) {
      return false;
    }

    try {
      final snapshot = await firestore.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      if (data == null) {
        return false;
      }

      final countries = data['countryCodes'];
      return data['role'] == 'admin' &&
          data['enabled'] == true &&
          countries is List &&
          countries.contains(countryCode);
    } on FirebaseException {
      return false;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth?.signOut();
  }
}
