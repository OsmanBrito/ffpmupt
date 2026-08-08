import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/holy_ground.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:firebase_core/firebase_core.dart';

enum HolyGroundSyncStatus { cached, live, unavailable }

class HolyGroundDirectoryState {
  const HolyGroundDirectoryState({
    required this.grounds,
    required this.status,
    this.error,
  });

  final List<HolyGround> grounds;
  final HolyGroundSyncStatus status;
  final Object? error;

  bool get isLive => status == HolyGroundSyncStatus.live;
  bool get isUnavailable => status == HolyGroundSyncStatus.unavailable;
}

class HolyGroundRepository {
  HolyGroundRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  static const _cacheKey = 'holyGrounds.europe.v1';

  FirebaseFirestore? get _database {
    if (_firestore != null) {
      return _firestore;
    }
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> _countryCollection(
    String countryCode,
  ) {
    final database = _database;
    if (database == null) {
      throw StateError('Firebase is not available.');
    }
    return database
        .collection('countries')
        .doc(countryCode)
        .collection('holyGrounds');
  }

  Stream<HolyGroundDirectoryState> watchAll() async* {
    final cached = await _readCache();
    if (cached.isNotEmpty) {
      yield HolyGroundDirectoryState(
        grounds: cached,
        status: HolyGroundSyncStatus.cached,
      );
    }
    final database = _database;
    if (database == null) {
      yield HolyGroundDirectoryState(
        grounds: cached,
        status: HolyGroundSyncStatus.unavailable,
        error: StateError('Firebase is not available.'),
      );
      return;
    }
    try {
      await for (final snapshot
          in database
              .collectionGroup('holyGrounds')
              .where('enabled', isEqualTo: true)
              .snapshots()) {
        final grounds = _decode(snapshot.docs);
        await _writeCache(grounds);
        yield HolyGroundDirectoryState(
          grounds: grounds,
          status: HolyGroundSyncStatus.live,
        );
      }
    } on FirebaseException catch (error) {
      yield HolyGroundDirectoryState(
        grounds: cached,
        status: HolyGroundSyncStatus.unavailable,
        error: error,
      );
    }
  }

  Stream<List<HolyGround>> watchAdmin(String countryCode) {
    return _countryCollection(
      countryCode,
    ).snapshots().map((snapshot) => _decode(snapshot.docs));
  }

  Future<void> save(HolyGround ground) async {
    final collection = _countryCollection(ground.countryCode);
    final document = ground.id.isEmpty
        ? collection.doc()
        : collection.doc(ground.id);
    final existing = await document.get();
    await document.set({
      ...ground.toMap(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setEnabled(HolyGround ground, bool enabled) {
    return _countryCollection(ground.countryCode).doc(ground.id).update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<HolyGround> _decode(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final grounds = documents
        .map(
          (document) => HolyGround.fromMap(
            id: document.id,
            map: document.data(),
            countryCodeOverride: document.reference.parent.parent?.id,
          ),
        )
        .whereType<HolyGround>()
        .toList();
    grounds.sort((left, right) {
      final country = left.countryCode.compareTo(right.countryCode);
      if (country != 0) {
        return country;
      }
      final order = left.sortOrder.compareTo(right.sortOrder);
      return order != 0 ? order : left.name.compareTo(right.name);
    });
    return grounds;
  }

  Future<List<HolyGround>> _readCache() async {
    final encoded = await LocalStore.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }
    try {
      final value = jsonDecode(encoded);
      if (value is! List) {
        return const [];
      }
      return value
          .whereType<Map>()
          .map((item) {
            final map = Map<String, Object?>.from(item);
            final id = map.remove('id');
            return id is String ? HolyGround.fromMap(id: id, map: map) : null;
          })
          .whereType<HolyGround>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeCache(List<HolyGround> grounds) {
    return LocalStore.setString(
      _cacheKey,
      jsonEncode(
        grounds.map((ground) => {'id': ground.id, ...ground.toMap()}).toList(),
      ),
    );
  }
}
