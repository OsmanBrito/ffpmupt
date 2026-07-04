import 'dart:io';

import 'package:ffpmupt/content/family_promise.dart';
import 'package:ffpmupt/content/motto.dart';
import 'package:ffpmupt/content/offering.dart';
import 'package:ffpmupt/content/videos.dart';
import 'package:ffpmupt/services/weekly_videos_repository.dart';
import 'package:ffpmupt/songs/songs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('content data', () {
    test('current motto is ready to display', () {
      expect(currentMotto.title.trim(), isNotEmpty);
      expect(currentMotto.body.trim(), isNotEmpty);
    });

    test('family pledge has content for each language', () {
      expect(FamilyPromiseLanguage.values, hasLength(3));

      for (final language in FamilyPromiseLanguage.values) {
        final pledgeItems = familyPromise[language]!;

        expect(familyPromiseTitle(language).trim(), isNotEmpty);
        expect(pledgeItems, hasLength(8));
        expect(pledgeItems.every((item) => item.trim().isNotEmpty), isTrue);
      }
    });

    test('family pledge speech is Korean native text only', () {
      final hangul = RegExp(r'[\uAC00-\uD7AF]');

      expect(koreanFamilyPromiseTtsLocale, 'ko-KR');
      expect(koreanFamilyPromiseSpeech, hasLength(8));
      expect(
        koreanFamilyPromiseSpeech.every((item) => hangul.hasMatch(item)),
        isTrue,
      );
    });

    test('songs have required metadata and lyrics', () {
      for (final song in songs) {
        expect(song.title.trim(), isNotEmpty);
        expect(song.page.trim(), isNotEmpty);
        expect(song.lyrics, isNotEmpty, reason: song.title);
        expect(
          song.lyrics.every((lyric) => lyric.trim().isNotEmpty),
          isTrue,
          reason: song.title,
        );
      }
    });

    test('song audio paths point to existing assets', () {
      final missingAssets = songs
          .where((song) => song.musicTrackPath.isNotEmpty)
          .where((song) => !File(song.musicTrackPath).existsSync())
          .map((song) => '${song.title}: ${song.musicTrackPath}')
          .toList();

      expect(missingAssets, isEmpty);
    });

    test('song timing data cannot read past available lyrics', () {
      for (final song in songs) {
        expect(
          song.times.length <= song.lyrics.length,
          isTrue,
          reason: song.title,
        );
        expect(
          song.timesToJump.length < song.lyrics.length,
          isTrue,
          reason: song.title,
        );
      }
    });

    test('offering payment opens public IBAN page', () {
      expect(offeringAccount.defaultAmount, isNull);
      expect(offeringAccount.iban.trim(), isNotEmpty);
      expect(
        offeringAccount.qrPayload,
        'https://ffpmupt-402e1.web.app/#/ofertas',
      );
    });

    test('weekly videos are ready to embed', () {
      expect(weeklyVideos, hasLength(2));
      expect(youtubeWeeklySourceUrl, startsWith('https://www.youtube.com/'));
      expect(vimeoWeeklySourceUrl, startsWith('https://vimeo.com/'));

      for (final video in weeklyVideos) {
        expect(video.title.trim(), isNotEmpty);
        expect(video.sourceName.trim(), isNotEmpty);
        expect(video.watchUrl, startsWith('https://'));
        expect(video.embedUrl, startsWith('https://'));
        expect(video.embedUrl, isNot(contains('/watch?')));
      }
    });

    test('weekly video links can be converted to embeds', () {
      final youtubeVideo = weeklyVideoFromUrl(
        sourceName: 'YouTube',
        sourceUrl: youtubeWeeklySourceUrl,
        title: 'YouTube test',
        url: 'https://www.youtube.com/watch?v=uXhZBoveiiM',
      );
      final shortYoutubeVideo = weeklyVideoFromUrl(
        sourceName: 'YouTube',
        sourceUrl: youtubeWeeklySourceUrl,
        title: 'YouTube short link test',
        url: 'https://youtu.be/uXhZBoveiiM',
      );
      final vimeoVideo = weeklyVideoFromUrl(
        sourceName: 'Vimeo',
        sourceUrl: vimeoWeeklySourceUrl,
        title: 'Vimeo test',
        url: 'https://vimeo.com/1202206348',
      );

      expect(
        youtubeVideo?.embedUrl,
        'https://www.youtube-nocookie.com/embed/uXhZBoveiiM',
      );
      expect(
        shortYoutubeVideo?.embedUrl,
        'https://www.youtube-nocookie.com/embed/uXhZBoveiiM',
      );
      expect(vimeoVideo?.embedUrl, 'https://player.vimeo.com/video/1202206348');
    });

    test('weekly video settings match Firestore document shape', () {
      final settings = WeeklyVideosSettings.fallback;
      final decoded = WeeklyVideosSettings.fromMap(settings.toMap());

      expect(weeklyVideosCollectionPath, 'countries/pt/settings');
      expect(weeklyVideosDocumentId, 'weeklyVideos');
      expect(settings.toMap()['countryCode'], 'pt');
      expect(decoded?.youtube.watchUrl, settings.youtube.watchUrl);
      expect(decoded?.vimeo.watchUrl, settings.vimeo.watchUrl);
    });
  });
}
