import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/content/family_promise.dart';
import 'package:ffpmupt/models/family_promise.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:firebase_core/firebase_core.dart';

class FamilyPromiseRepository {
  FamilyPromiseRepository({
    required this.countryCode,
    required this.defaultLanguage,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final String countryCode;
  final String defaultLanguage;
  final FirebaseFirestore? _firestore;

  String get _cacheKey => 'family_promises.$countryCode.v1';
  List<FamilyPromiseDocument> get bundledDefaults =>
      bundledFamilyPromisesForCountry(
        countryCode: countryCode,
        defaultLanguage: defaultLanguage,
      );

  FirebaseFirestore? get _database {
    if (_firestore != null) {
      return _firestore;
    }
    return Firebase.apps.isEmpty ? null : FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _collection {
    final database = _database;
    if (database == null) {
      throw StateError('Firebase is not available.');
    }
    return database
        .collection('countries')
        .doc(countryCode)
        .collection('promises');
  }

  Stream<List<FamilyPromiseDocument>> watchPublicPromises() async* {
    final cached = await _readCache();
    var current = cached ?? bundledDefaults;
    yield _enabled(current);

    if (_database == null) {
      return;
    }
    try {
      await for (final snapshot
          in _collection.orderBy('sortOrder').snapshots()) {
        final remote = _decodeSnapshot(snapshot);
        if (remote.isEmpty) {
          continue;
        }
        current = _mergeDefaults(remote);
        await _writeCacheIfChanged(current);
        yield _enabled(current);
      }
    } on FirebaseException {
      yield _enabled(current);
    }
  }

  Stream<List<FamilyPromiseDocument>> watchAdminPromises() {
    return _collection.orderBy('sortOrder').snapshots().map(_decodeSnapshot);
  }

  Future<int> importMissingDefaults() async {
    final snapshot = await _collection.get();
    final existing = snapshot.docs.map((document) => document.id).toSet();
    final missing = bundledDefaults
        .where((promise) => !existing.contains(promise.languageCode))
        .toList();
    if (missing.isEmpty) {
      return 0;
    }
    final batch = _database!.batch();
    for (final promise in missing) {
      batch.set(_collection.doc(promise.languageCode), {
        ...promise.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return missing.length;
  }

  Future<void> save(FamilyPromiseDocument promise) async {
    final document = _collection.doc(promise.languageCode);
    final existing = await document.get();
    await document.set({
      ...promise.toMap(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setEnabled(FamilyPromiseDocument promise, bool enabled) {
    return _collection.doc(promise.languageCode).set({
      ...promise.copyWith(enabled: enabled).toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<FamilyPromiseDocument> _decodeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final decoded =
        snapshot.docs
            .map((document) => FamilyPromiseDocument.fromMap(document.data()))
            .whereType<FamilyPromiseDocument>()
            .toList()
          ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return decoded;
  }

  List<FamilyPromiseDocument> _enabled(List<FamilyPromiseDocument> promises) {
    return promises.where((promise) => promise.enabled).toList();
  }

  List<FamilyPromiseDocument> _mergeDefaults(
    List<FamilyPromiseDocument> saved,
  ) {
    final byLanguage = {
      for (final promise in bundledDefaults) promise.languageCode: promise,
      for (final promise in saved) promise.languageCode: promise,
    };
    return byLanguage.values.toList()
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
  }

  Future<List<FamilyPromiseDocument>?> _readCache() async {
    final encoded = await LocalStore.getString(_cacheKey);
    if (encoded == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        return null;
      }
      final promises = decoded
          .whereType<Map>()
          .map(
            (value) =>
                FamilyPromiseDocument.fromMap(Map<String, Object?>.from(value)),
          )
          .whereType<FamilyPromiseDocument>()
          .toList();
      return promises.isEmpty ? null : promises;
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeCacheIfChanged(
    List<FamilyPromiseDocument> promises,
  ) async {
    final encoded = jsonEncode(
      promises.map((promise) => promise.toMap()).toList(),
    );
    if (await LocalStore.getString(_cacheKey) != encoded) {
      await LocalStore.setString(_cacheKey, encoded);
    }
  }
}
