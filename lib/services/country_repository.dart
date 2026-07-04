import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:firebase_core/firebase_core.dart';

class CountryRepository {
  CountryRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore? get _database {
    if (Firebase.apps.isEmpty) {
      return null;
    }

    return _firestore ?? FirebaseFirestore.instance;
  }

  DocumentReference<Map<String, dynamic>>? document(String countryCode) {
    return _database?.collection('countries').doc(countryCode);
  }

  Future<CountryModel> load(String countryCode) async {
    final reference = document(countryCode);
    if (reference == null) {
      return CountryModel.portugal;
    }

    try {
      final snapshot = await reference.get();
      final data = snapshot.data();
      if (data == null) {
        return CountryModel.portugal;
      }

      return CountryModel.fromMap(data) ?? CountryModel.portugal;
    } on FirebaseException {
      return CountryModel.portugal;
    }
  }

  Future<bool> save(CountryModel country) async {
    final reference = document(country.code);
    if (reference == null) {
      return false;
    }

    try {
      final snapshot = await reference.get();
      await reference.set({
        ...country.toMap(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } on FirebaseException {
      return false;
    }
  }
}
