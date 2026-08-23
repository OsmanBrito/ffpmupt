import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/community_notice.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:firebase_core/firebase_core.dart';

class CommunityNoticeRepository {
  CommunityNoticeRepository({
    required this.countryCode,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final String countryCode;
  final FirebaseFirestore? _firestore;

  String get _cacheKey => 'community_notices.$countryCode.v1';

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
        .collection('notices');
  }

  Stream<List<CommunityNotice>> watchPublic() async* {
    final cached = await _readCache();
    yield _sorted(cached);

    if (_database == null) {
      return;
    }
    try {
      await for (final snapshot
          in _collection.where('enabled', isEqualTo: true).snapshots()) {
        final notices = _decode(snapshot.docs);
        await _writeCache(notices);
        yield notices;
      }
    } on FirebaseException {
      return;
    }
  }

  Stream<List<CommunityNotice>> watchAdmin() {
    return _collection.snapshots().map((snapshot) => _decode(snapshot.docs));
  }

  String newId() => _collection.doc().id;

  Future<void> save(CommunityNotice notice) async {
    final id = notice.id.isEmpty ? newId() : notice.id;
    final document = _collection.doc(id);
    final existing = await document.get();
    await document.set({
      ...notice.toMap(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setEnabled(CommunityNotice notice, bool enabled) {
    return _collection.doc(notice.id).update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<CommunityNotice> _decode(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return _sorted(
      documents
          .map(
            (document) => CommunityNotice.fromMap(
              id: document.id,
              map: document.data(),
              countryCodeOverride: countryCode,
            ),
          )
          .whereType<CommunityNotice>()
          .toList(),
    );
  }

  List<CommunityNotice> _sorted(Iterable<CommunityNotice> notices) {
    return notices.toList()..sort(CommunityNotice.compare);
  }

  Future<List<CommunityNotice>> _readCache() async {
    final encoded = await LocalStore.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map(
            (value) => CommunityNotice.fromMap(
              id: value['id'] is String ? value['id']! as String : '',
              map: Map<String, Object?>.from(value),
              countryCodeOverride: countryCode,
            ),
          )
          .whereType<CommunityNotice>()
          .where((notice) => notice.enabled)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeCache(List<CommunityNotice> notices) {
    return LocalStore.setString(
      _cacheKey,
      jsonEncode([
        for (final notice in notices) {'id': notice.id, ...notice.toMap()},
      ]),
    );
  }
}
