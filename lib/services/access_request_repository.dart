import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/access_request.dart';
import 'package:firebase_core/firebase_core.dart';

class AccessRequestRepository {
  AccessRequestRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _database {
    if (_firestore != null) {
      return _firestore;
    }
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not available.');
    }
    return FirebaseFirestore.instance;
  }

  Future<void> submit(AccessRequest request) async {
    await _database.collection('accessRequests').add({
      ...request.toMap(),
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
