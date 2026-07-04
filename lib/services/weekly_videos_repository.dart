import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/content/videos.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:firebase_core/firebase_core.dart';

const weeklyVideosCountryCode = 'pt';
const weeklyVideosCollectionPath = 'countries/pt/settings';
const weeklyVideosDocumentId = 'weeklyVideos';

class WeeklyVideosSettings {
  const WeeklyVideosSettings({required this.youtube, required this.vimeo});

  final WeeklyVideo youtube;
  final WeeklyVideo vimeo;

  List<WeeklyVideo> get videos => [youtube, vimeo];

  Map<String, Object?> toMap() {
    return {
      'countryCode': weeklyVideosCountryCode,
      'youtube': youtube.toMap(),
      'vimeo': vimeo.toMap(),
    };
  }

  static WeeklyVideosSettings get fallback {
    return WeeklyVideosSettings(
      youtube: weeklyVideos[0],
      vimeo: weeklyVideos[1],
    );
  }

  static WeeklyVideosSettings? fromMap(Map<String, Object?> map) {
    final youtube = map['youtube'];
    final vimeo = map['vimeo'];

    if (youtube is! Map || vimeo is! Map) {
      return null;
    }

    final youtubeVideo = WeeklyVideo.fromMap(
      Map<String, Object?>.from(youtube),
    );
    final vimeoVideo = WeeklyVideo.fromMap(Map<String, Object?>.from(vimeo));

    if (youtubeVideo == null || vimeoVideo == null) {
      return null;
    }

    return WeeklyVideosSettings(youtube: youtubeVideo, vimeo: vimeoVideo);
  }
}

class WeeklyVideosRepository {
  WeeklyVideosRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;

  static const _localSettingsKey = 'weekly_videos_settings';

  final FirebaseFirestore? _firestore;

  bool get _canUseFirestore => Firebase.apps.isNotEmpty;

  DocumentReference<Map<String, dynamic>>? get _document {
    if (!_canUseFirestore) {
      return null;
    }

    return (_firestore ?? FirebaseFirestore.instance)
        .collection(weeklyVideosCollectionPath)
        .doc(weeklyVideosDocumentId);
  }

  Future<WeeklyVideosSettings> load() async {
    final firestoreSettings = await _loadFromFirestore();
    if (firestoreSettings != null) {
      await _saveLocal(firestoreSettings);
      return firestoreSettings;
    }

    return await _loadLocal() ?? WeeklyVideosSettings.fallback;
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

      return WeeklyVideosSettings.fromMap(data);
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

    return WeeklyVideosSettings.fromMap(Map<String, Object?>.from(decoded));
  }

  Future<void> _saveLocal(WeeklyVideosSettings settings) {
    return LocalStore.setString(
      _localSettingsKey,
      jsonEncode(settings.toMap()),
    );
  }
}
