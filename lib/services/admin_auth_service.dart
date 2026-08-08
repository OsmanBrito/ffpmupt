import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminAccess {
  const AdminAccess({
    required this.isSuperAdmin,
    required this.canManageCountry,
  });

  final bool isSuperAdmin;
  final bool canManageCountry;

  static const denied = AdminAccess(
    isSuperAdmin: false,
    canManageCountry: false,
  );
}

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

  Future<void> sendPasswordReset(String email) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase authentication is not available.');
    }
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<bool> isAdmin(User? user, {required String countryCode}) async {
    final access = await getAccess(user, countryCode: countryCode);
    return access.canManageCountry;
  }

  Future<AdminAccess> getAccess(
    User? user, {
    required String countryCode,
  }) async {
    final firestore = _firebaseFirestore;
    if (user == null || firestore == null) {
      return AdminAccess.denied;
    }

    try {
      final snapshot = await firestore.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      if (data == null) {
        return AdminAccess.denied;
      }

      final countries = data['countryCodes'];
      final enabled = data['enabled'] == true;
      final isSuperAdmin = enabled && data['role'] == 'superadmin';
      final isCountryAdmin =
          enabled &&
          data['role'] == 'admin' &&
          countries is List &&
          countries.contains(countryCode);
      return AdminAccess(
        isSuperAdmin: isSuperAdmin,
        canManageCountry: isSuperAdmin || isCountryAdmin,
      );
    } on FirebaseException {
      return AdminAccess.denied;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth?.signOut();
  }
}
