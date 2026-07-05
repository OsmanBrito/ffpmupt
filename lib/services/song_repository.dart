import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:ffpmupt/songs/bundled_song_catalog.dart';
import 'package:firebase_core/firebase_core.dart';

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
  SongRepository({required this.countryCode, FirebaseFirestore? firestore})
    : _firestore = firestore;

  final String countryCode;
  String get _cacheKey => 'songs.$countryCode.catalog.v1';
  String get _lastSyncKey => 'songs.$countryCode.lastSync.v1';

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
        .doc(countryCode)
        .collection('songs');
  }

  Stream<SongCatalogState> watchCatalog() async* {
    final cached = await _readCache();
    var current = cached == null
        ? bundledCatalogForCountry(countryCode)
        : _mergeDefaults(cached);
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

        current = _mergeDefaults(remoteSongs);
        final syncedAt = DateTime.now().toUtc();
        await _writeCacheIfChanged(current);
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
    final missing = bundledCatalogForCountry(
      countryCode,
    ).where((song) => !existingIds.contains(song.id)).toList();
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

  Future<bool> canRunInitialImport() async {
    final marker = await _database!
        .collection('countries')
        .doc(countryCode)
        .collection('settings')
        .doc('songImport')
        .get();
    if (marker.data()?['completed'] == true) {
      return false;
    }

    final existing = await _songsCollection.get();
    return !existing.docs.any((document) {
      final category = document.data()['category'];
      return category != SongCategory.worship.value;
    });
  }

  Future<int> importInitialSongs(List<SongDocument> songs) async {
    if (songs.isEmpty) {
      return 0;
    }
    if (!await canRunInitialImport()) {
      throw StateError('A importação inicial já foi concluída para este país.');
    }

    final usedIds = <String>{};
    final prepared = <SongDocument>[];
    for (var index = 0; index < songs.length; index++) {
      final song = songs[index];
      final baseId = _songId(song.title);
      var id = baseId;
      var suffix = 2;
      while (!usedIds.add(id)) {
        id = '$baseId-$suffix';
        suffix++;
      }
      prepared.add(song.copyWith(id: id));
    }

    final database = _database!;
    for (var start = 0; start < prepared.length; start += 400) {
      final end = (start + 400).clamp(0, prepared.length);
      final batch = database.batch();
      for (final song in prepared.sublist(start, end)) {
        batch.set(_songsCollection.doc(song.id), {
          ...song.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    await database
        .collection('countries')
        .doc(countryCode)
        .collection('settings')
        .doc('songImport')
        .set({
          'completed': true,
          'songCount': prepared.length,
          'completedAt': FieldValue.serverTimestamp(),
        });
    return prepared.length;
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
        decoded.add(normalizeLegacyWorshipSong(song));
      }
    }
    decoded.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return decoded;
  }

  List<SongDocument> _enabledSongs(List<SongDocument> source) {
    return source
        .where((song) => song.enabled)
        .map(normalizeLegacyWorshipSong)
        .toList(growable: false);
  }

  List<SongDocument> _mergeDefaults(List<SongDocument> saved) {
    final byId = {
      for (final song in bundledCatalogForCountry(countryCode)) song.id: song,
      for (final song in saved) song.id: normalizeLegacyWorshipSong(song),
    };
    return byId.values.toList()
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
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

String _songId(String title) {
  final normalized = title
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'song' : normalized;
}
