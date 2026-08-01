import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/content/offering.dart';
import 'package:ffpmupt/models/payment_settings.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:firebase_core/firebase_core.dart';

class PaymentSettingsRepository {
  PaymentSettingsRepository({
    required this.countryCode,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final String countryCode;
  final FirebaseFirestore? _firestore;

  String get _cacheKey => 'payments.$countryCode.settings.v1';

  FirebaseFirestore? get _database {
    if (_firestore != null) {
      return _firestore;
    }
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance;
  }

  DocumentReference<Map<String, dynamic>> get _document {
    final database = _database;
    if (database == null) {
      throw StateError('Firebase is not available.');
    }
    return database
        .collection('countries')
        .doc(countryCode)
        .collection('settings')
        .doc('payments');
  }

  Stream<PaymentSettings> watch() async* {
    final cached = await _readCache();
    yield cached ?? defaultPaymentSettings(countryCode);

    if (_database == null) {
      return;
    }

    try {
      await for (final snapshot in _document.snapshots()) {
        final data = snapshot.data();
        if (data == null) {
          continue;
        }
        final settings = PaymentSettings.fromMap(data);
        if (settings == null) {
          continue;
        }
        await _writeCache(settings);
        yield settings;
      }
    } on FirebaseException {
      return;
    }
  }

  Future<PaymentSettings> loadForAdmin() async {
    final fallback = await _readCache() ?? defaultPaymentSettings(countryCode);
    if (_database == null) {
      return fallback;
    }

    try {
      final snapshot = await _document.get();
      final data = snapshot.data();
      if (data == null) {
        return fallback;
      }
      final settings = PaymentSettings.fromMap(data);
      if (settings == null) {
        return fallback;
      }
      await _writeCache(settings);
      return settings;
    } on FirebaseException {
      return fallback;
    }
  }

  Future<void> save(PaymentSettings settings) async {
    await _document.set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _writeCache(settings);
  }

  Future<PaymentSettings?> _readCache() async {
    final encoded = await LocalStore.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final value = jsonDecode(encoded);
      if (value is! Map) {
        return null;
      }
      return PaymentSettings.fromMap(Map<String, Object?>.from(value));
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeCache(PaymentSettings settings) {
    return LocalStore.setString(_cacheKey, jsonEncode(settings.toMap()));
  }
}
