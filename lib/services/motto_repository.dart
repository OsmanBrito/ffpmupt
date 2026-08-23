import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/motto.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:firebase_core/firebase_core.dart';

const mottoDocumentId = 'motto';

class MottoRepository {
  MottoRepository({required this.countryCode, FirebaseFirestore? firestore})
    : _firestore = firestore;

  final String countryCode;
  final FirebaseFirestore? _firestore;

  String get _cacheKey => 'motto.$countryCode.settings.v1';

  FirebaseFirestore? get _database {
    if (_firestore != null) {
      return _firestore;
    }
    return Firebase.apps.isEmpty ? null : FirebaseFirestore.instance;
  }

  DocumentReference<Map<String, dynamic>>? get _document {
    return _database
        ?.collection('countries')
        .doc(countryCode)
        .collection('settings')
        .doc(mottoDocumentId);
  }

  Stream<MottoSettings> watch() async* {
    final cached = await _readCache();
    var current = cached ?? MottoSettings.fallback(countryCode: countryCode);
    yield current;

    final document = _document;
    if (document == null) {
      return;
    }
    try {
      await for (final snapshot in document.snapshots()) {
        final data = snapshot.data();
        final settings = data == null ? null : MottoSettings.fromMap(data);
        if (settings == null) {
          continue;
        }
        current = settings;
        await _writeCache(settings);
        yield current;
      }
    } on FirebaseException {
      return;
    }
  }

  Future<MottoSettings> loadForAdmin() async {
    final fallback =
        await _readCache() ?? MottoSettings.fallback(countryCode: countryCode);
    final document = _document;
    if (document == null) {
      return fallback;
    }
    try {
      final snapshot = await document.get();
      final data = snapshot.data();
      final settings = data == null ? null : MottoSettings.fromMap(data);
      if (settings == null) {
        return fallback;
      }
      await _writeCache(settings);
      return settings;
    } on FirebaseException {
      return fallback;
    }
  }

  Future<void> save(MottoSettings settings) async {
    final document = _document;
    if (document == null) {
      throw StateError('Firebase is not available.');
    }
    await document.set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _writeCache(settings);
  }

  Future<MottoSettings?> _readCache() async {
    final encoded = await LocalStore.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return null;
      }
      return MottoSettings.fromMap(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeCache(MottoSettings settings) {
    return LocalStore.setString(_cacheKey, jsonEncode(settings.toMap()));
  }
}
