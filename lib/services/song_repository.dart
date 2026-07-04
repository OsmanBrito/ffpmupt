import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:ffpmupt/songs/bundled_song_catalog.dart';
import 'package:firebase_core/firebase_core.dart';

const songsCountryCode = 'pt';

enum SongCatalogSource { bundled, localCache, firestore }

class SongCatalogState {
  const SongCatalogState({
    required this.songs,
    required this.source,
    required this.isSyncing,
    this.lastSyncedAt,
  });

  final List<SongDocument> songs;
  final SongCatalogSource source;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
}

class SongRepository {
  SongRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  static const _cacheKey = 'songs.$songsCountryCode.catalog.v1';
  static const _lastSyncKey = 'songs.$songsCountryCode.lastSync.v1';

  final FirebaseFirestore? _firestore;

  FirebaseFirestore? get _database {
    if (_firestore != null) {
      return _firestore;
    }
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>> get _songsCollection {
    final database = _database;
    if (database == null) {
      throw StateError('Firebase is not available.');
    }
    return database
        .collection('countries')
        .doc(songsCountryCode)
        .collection('songs');
  }

  Stream<SongCatalogState> watchCatalog() async* {
    final cached = await _readCache();
    var current = cached ?? bundledSongCatalog;
    final cachedSync = await _readLastSync();

    yield SongCatalogState(
      songs: _enabledSongs(current),
      source: cached == null
          ? SongCatalogSource.bundled
          : SongCatalogSource.localCache,
      isSyncing: _database != null,
      lastSyncedAt: cachedSync,
    );

    if (_database == null) {
      return;
    }

    try {
      await for (final snapshot
          in _songsCollection
              .orderBy('sortOrder')
              .snapshots(includeMetadataChanges: true)) {
        final remoteSongs = _decodeSnapshot(snapshot);
        if (remoteSongs.isEmpty) {
          continue;
        }

        current = remoteSongs;
        final syncedAt = DateTime.now().toUtc();
        await _writeCacheIfChanged(remoteSongs);
        await LocalStore.setString(_lastSyncKey, syncedAt.toIso8601String());

        yield SongCatalogState(
          songs: _enabledSongs(current),
          source: snapshot.metadata.isFromCache
              ? SongCatalogSource.localCache
              : SongCatalogSource.firestore,
          isSyncing: snapshot.metadata.isFromCache,
          lastSyncedAt: syncedAt,
        );
      }
    } on FirebaseException {
      yield SongCatalogState(
        songs: _enabledSongs(current),
        source: cached == null
            ? SongCatalogSource.bundled
            : SongCatalogSource.localCache,
        isSyncing: false,
        lastSyncedAt: cachedSync,
      );
    }
  }

  Stream<List<SongDocument>> watchAdminSongs() {
    return _songsCollection
        .orderBy('sortOrder')
        .snapshots()
        .map(_decodeSnapshot);
  }

  Future<int> importMissingBundledSongs() async {
    final existing = await _songsCollection.get();
    final existingIds = existing.docs.map((document) => document.id).toSet();
    final missing = bundledSongCatalog
        .where((song) => !existingIds.contains(song.id))
        .toList();
    if (missing.isEmpty) {
      return 0;
    }

    final database = _database!;
    final batch = database.batch();
    for (final song in missing) {
      batch.set(_songsCollection.doc(song.id), {
        ...song.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return missing.length;
  }

  Future<String> saveSong(SongDocument song) async {
    final document = song.id.isEmpty
        ? _songsCollection.doc()
        : _songsCollection.doc(song.id);
    final existing = await document.get();
    await document.set({
      ...song.toMap(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return document.id;
  }

  Future<void> setEnabled(SongDocument song, bool enabled) {
    return _songsCollection.doc(song.id).update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  List<SongDocument> _decodeSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final decoded = <SongDocument>[];
    for (final document in snapshot.docs) {
      final song = SongDocument.fromMap(id: document.id, map: document.data());
      if (song != null) {
        decoded.add(song);
      }
    }
    decoded.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return decoded;
  }

  List<SongDocument> _enabledSongs(List<SongDocument> source) {
    return source.where((song) => song.enabled).toList(growable: false);
  }

  Future<List<SongDocument>?> _readCache() async {
    final encoded = await LocalStore.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final value = jsonDecode(encoded);
      if (value is! List) {
        return null;
      }
      final decoded = <SongDocument>[];
      for (final item in value) {
        if (item is! Map) {
          return null;
        }
        final map = Map<String, Object?>.from(item);
        final id = map.remove('id');
        if (id is! String) {
          return null;
        }
        final song = SongDocument.fromMap(id: id, map: map);
        if (song == null) {
          return null;
        }
        decoded.add(song);
      }
      return decoded;
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeCacheIfChanged(List<SongDocument> songs) async {
    final encoded = jsonEncode(
      songs.map((song) => {'id': song.id, ...song.toMap()}).toList(),
    );
    final current = await LocalStore.getString(_cacheKey);
    if (current != encoded) {
      await LocalStore.setString(_cacheKey, encoded);
    }
  }

  Future<DateTime?> _readLastSync() async {
    final value = await LocalStore.getString(_lastSyncKey);
    return value == null ? null : DateTime.tryParse(value);
  }
}
