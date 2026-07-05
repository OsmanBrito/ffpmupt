import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:firebase_core/firebase_core.dart';

class CountryRepository {
  CountryRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  static const _countriesCacheKey = 'countries.enabled.v1';

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

  Future<List<CountryModel>> loadEnabledCountries() async {
    final database = _database;
    if (database != null) {
      try {
        final snapshot = await database
            .collection('countries')
            .where('enabled', isEqualTo: true)
            .get();
        final countries =
            snapshot.docs
                .map((document) => CountryModel.fromMap(document.data()))
                .whereType<CountryModel>()
                .toList()
              ..sort((left, right) => left.name.compareTo(right.name));
        if (countries.isNotEmpty) {
          await LocalStore.setString(
            _countriesCacheKey,
            jsonEncode(countries.map((country) => country.toMap()).toList()),
          );
          return countries;
        }
      } on FirebaseException {
        // Fall through to the last local copy.
      }
    }

    final cached = await LocalStore.getString(_countriesCacheKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is List) {
          final countries = decoded
              .whereType<Map>()
              .map(
                (value) =>
                    CountryModel.fromMap(Map<String, Object?>.from(value)),
              )
              .whereType<CountryModel>()
              .where((country) => country.enabled)
              .toList();
          if (countries.isNotEmpty) {
            return countries;
          }
        }
      } on FormatException {
        // Use the bundled country below.
      }
    }

    return const [CountryModel.portugal];
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
