import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/content/videos.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:firebase_core/firebase_core.dart';

const weeklyVideosDocumentId = 'weeklyVideos';

class WeeklyVideosSettings {
  const WeeklyVideosSettings({
    required this.countryCode,
    required this.youtube,
    required this.vimeo,
  });

  final String countryCode;
  final WeeklyVideo youtube;
  final WeeklyVideo vimeo;

  List<WeeklyVideo> get videos => [youtube, vimeo];

  Map<String, Object?> toMap() {
    return {
      'countryCode': countryCode,
      'youtube': youtube.toMap(),
      'vimeo': vimeo.toMap(),
    };
  }

  static WeeklyVideosSettings fallback(String countryCode) {
    return WeeklyVideosSettings(
      countryCode: countryCode,
      youtube: weeklyVideos[0],
      vimeo: weeklyVideos[1],
    );
  }

  static WeeklyVideosSettings? fromMap(
    Map<String, Object?> map, {
    String? fallbackCountryCode,
  }) {
    final countryCode = map['countryCode'] ?? fallbackCountryCode;
    final youtube = map['youtube'];
    final vimeo = map['vimeo'];

    if (countryCode is! String || youtube is! Map || vimeo is! Map) {
      return null;
    }

    final youtubeVideo = WeeklyVideo.fromMap(
      Map<String, Object?>.from(youtube),
    );
    final vimeoVideo = WeeklyVideo.fromMap(Map<String, Object?>.from(vimeo));

    if (youtubeVideo == null || vimeoVideo == null) {
      return null;
    }

    return WeeklyVideosSettings(
      countryCode: countryCode,
      youtube: youtubeVideo,
      vimeo: vimeoVideo,
    );
  }
}

class WeeklyVideosRepository {
  WeeklyVideosRepository({
    required this.countryCode,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final String countryCode;
  String get _localSettingsKey => 'weekly_videos_settings.$countryCode';

  final FirebaseFirestore? _firestore;

  bool get _canUseFirestore => Firebase.apps.isNotEmpty;

  DocumentReference<Map<String, dynamic>>? get _document {
    if (!_canUseFirestore) {
      return null;
    }

    return (_firestore ?? FirebaseFirestore.instance)
        .collection('countries/$countryCode/settings')
        .doc(weeklyVideosDocumentId);
  }

  Future<WeeklyVideosSettings> load() async {
    final firestoreSettings = await _loadFromFirestore();
    if (firestoreSettings != null) {
      await _saveLocal(firestoreSettings);
      return firestoreSettings;
    }

    return await _loadLocal() ?? WeeklyVideosSettings.fallback(countryCode);
  }

  Future<bool> save(WeeklyVideosSettings settings) async {
    await _saveLocal(settings);
    final document = _document;
    if (document == null) {
      return false;
    }

    try {
      await document.set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } on FirebaseException {
      return false;
    }
  }

  Future<WeeklyVideosSettings?> _loadFromFirestore() async {
    final document = _document;
    if (document == null) {
      return null;
    }

    try {
      final snapshot = await document.get();
      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      return WeeklyVideosSettings.fromMap(
        data,
        fallbackCountryCode: countryCode,
      );
    } on FirebaseException {
      return null;
    }
  }

  Future<WeeklyVideosSettings?> _loadLocal() async {
    final storedValue = await LocalStore.getString(_localSettingsKey);
    if (storedValue == null) {
      return null;
    }

    final decoded = jsonDecode(storedValue);
    if (decoded is! Map) {
      return null;
    }

    return WeeklyVideosSettings.fromMap(
      Map<String, Object?>.from(decoded),
      fallbackCountryCode: countryCode,
    );
  }

  Future<void> _saveLocal(WeeklyVideosSettings settings) {
    return LocalStore.setString(
      _localSettingsKey,
      jsonEncode(settings.toMap()),
    );
  }
}
