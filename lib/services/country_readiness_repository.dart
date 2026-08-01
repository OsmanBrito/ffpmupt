import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/country_readiness.dart';
import 'package:ffpmupt/models/family_promise.dart';
import 'package:ffpmupt/models/holy_ground.dart';
import 'package:ffpmupt/models/payment_settings.dart';
import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/services/offline_audio_cache.dart';
import 'package:ffpmupt/services/weekly_videos_repository.dart';
import 'package:firebase_core/firebase_core.dart';

class CountryReadinessRepository {
  CountryReadinessRepository({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _database {
    if (_firestore != null) {
      return _firestore;
    }
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not available.');
    }
    return FirebaseFirestore.instance;
  }

  Future<CountryReadiness> load({
    required CountryModel country,
    required bool hasAdminAccess,
  }) async {
    final countryRef = _database.collection('countries').doc(country.code);
    final results = await Future.wait([
      countryRef.collection('songs').get(),
      countryRef.collection('promises').get(),
      countryRef.collection('settings').doc('payments').get(),
      countryRef.collection('settings').doc('weeklyVideos').get(),
      countryRef.collection('holyGrounds').get(),
    ]);
    final songSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final promiseSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final paymentSnapshot =
        results[2] as DocumentSnapshot<Map<String, dynamic>>;
    final videoSnapshot = results[3] as DocumentSnapshot<Map<String, dynamic>>;
    final groundSnapshot = results[4] as QuerySnapshot<Map<String, dynamic>>;

    final songs = songSnapshot.docs
        .map(
          (document) =>
              SongDocument.fromMap(id: document.id, map: document.data()),
        )
        .whereType<SongDocument>()
        .where((song) => song.enabled)
        .toList();
    final promises = promiseSnapshot.docs
        .map((document) => FamilyPromiseDocument.fromMap(document.data()))
        .whereType<FamilyPromiseDocument>()
        .where((promise) => promise.enabled)
        .toList();
    final grounds = groundSnapshot.docs
        .map(
          (document) =>
              HolyGround.fromMap(id: document.id, map: document.data()),
        )
        .whereType<HolyGround>()
        .where((ground) => ground.enabled)
        .toList();
    final paymentData = paymentSnapshot.data();
    final payments = paymentData == null
        ? null
        : PaymentSettings.fromMap(paymentData);
    final videoData = videoSnapshot.data();
    final videos = videoData == null
        ? null
        : WeeklyVideosSettings.fromMap(
            videoData,
            fallbackCountryCode: country.code,
          );

    final issues = <ContentIssue>[];
    for (final song in songs) {
      if (song.title.trim().isEmpty ||
          song.lyrics.every((line) => line.trim().isEmpty)) {
        issues.add(
          ContentIssue(area: ReadinessArea.songs, subject: song.title),
        );
      }
      if (song.page.trim() == '0') {
        issues.add(
          ContentIssue(
            area: ReadinessArea.songs,
            subject: '${song.title} · page 0',
          ),
        );
      }
      for (final track in song.audioTracks.where((track) => track.enabled)) {
        if (!_validMediaLocation(track.url)) {
          issues.add(
            ContentIssue(
              area: ReadinessArea.songs,
              subject: '${song.title} · ${track.label}',
            ),
          );
        }
      }
    }

    final requiredLanguages = {
      country.defaultLanguage.toLowerCase(),
      'en',
      'ko',
    };
    final promisesByLanguage = {
      for (final promise in promises)
        promise.languageCode.toLowerCase(): promise,
    };
    for (final language in requiredLanguages) {
      final promise = promisesByLanguage[language];
      if (promise == null ||
          promise.title.trim().isEmpty ||
          promise.verses.length < 8 ||
          promise.verses.any((verse) => verse.trim().isEmpty)) {
        issues.add(
          ContentIssue(
            area: ReadinessArea.promise,
            subject: language.toUpperCase(),
          ),
        );
      }
    }

    final validPayments =
        payments != null &&
        payments.enabled &&
        payments.enabledMethods.isNotEmpty &&
        payments.enabledMethods.every(
          (method) =>
              method.label.trim().isNotEmpty &&
              (method.details.any(
                    (detail) =>
                        detail.label.trim().isNotEmpty &&
                        detail.value.trim().isNotEmpty,
                  ) ||
                  method.paymentUrl.trim().isNotEmpty ||
                  method.qrContent.trim().isNotEmpty),
        );
    if (!validPayments) {
      issues.add(
        const ContentIssue(
          area: ReadinessArea.payments,
          subject: 'configuration',
        ),
      );
    }
    if (videos == null) {
      issues.add(
        const ContentIssue(
          area: ReadinessArea.videos,
          subject: 'YouTube / Vimeo',
        ),
      );
    }
    for (final ground in grounds) {
      if (ground.name.trim().isEmpty ||
          ground.address.trim().isEmpty ||
          !_validHttpsUrl(ground.imageUrl)) {
        issues.add(
          ContentIssue(area: ReadinessArea.holyGrounds, subject: ground.name),
        );
      }
    }

    final cacheStatus = OfflineAudioCache().currentProgress.status;
    final offlineReady =
        cacheStatus == OfflineAudioCacheStatus.ready ||
        songs.every(
          (song) => song.audioTracks.where((track) => track.enabled).isEmpty,
        );
    final songIssues = issues.where(
      (issue) => issue.area == ReadinessArea.songs,
    );
    final promiseIssues = issues.where(
      (issue) => issue.area == ReadinessArea.promise,
    );

    return CountryReadiness(
      checks: [
        ReadinessCheck(
          area: ReadinessArea.country,
          ready: country.enabled,
          detail: country.name,
        ),
        ReadinessCheck(
          area: ReadinessArea.admin,
          ready: hasAdminAccess,
          detail: country.code.toUpperCase(),
        ),
        ReadinessCheck(
          area: ReadinessArea.songs,
          ready: songs.isNotEmpty && songIssues.isEmpty,
          detail: '${songs.length}',
        ),
        ReadinessCheck(
          area: ReadinessArea.promise,
          ready: promiseIssues.isEmpty,
          detail: requiredLanguages
              .map((code) => code.toUpperCase())
              .join(', '),
        ),
        ReadinessCheck(
          area: ReadinessArea.payments,
          ready: validPayments,
          detail: '${payments?.enabledMethods.length ?? 0}',
        ),
        ReadinessCheck(
          area: ReadinessArea.videos,
          ready: videos != null,
          detail: videos == null ? '0' : '2',
        ),
        ReadinessCheck(
          area: ReadinessArea.holyGrounds,
          ready:
              grounds.isNotEmpty &&
              issues.every((issue) => issue.area != ReadinessArea.holyGrounds),
          detail: '${grounds.length}',
        ),
        ReadinessCheck(
          area: ReadinessArea.offline,
          ready: offlineReady,
          detail: cacheStatus.name,
        ),
      ],
      issues: issues,
    );
  }

  bool _validMediaLocation(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith('assets/') || _validHttpsUrl(trimmed);
  }

  bool _validHttpsUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
}
