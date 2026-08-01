class WeeklyVideo {
  const WeeklyVideo({
    required this.title,
    required this.sourceName,
    required this.sourceUrl,
    required this.watchUrl,
    required this.embedUrl,
  });

  final String title;
  final String sourceName;
  final String sourceUrl;
  final String watchUrl;
  final String embedUrl;

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
      'watchUrl': watchUrl,
      'embedUrl': embedUrl,
    };
  }

  static WeeklyVideo? fromMap(Map<String, Object?> map) {
    final sourceName = map['sourceName'];
    final title = map['title'];
    final sourceUrl = map['sourceUrl'];
    final watchUrl = map['watchUrl'];

    if (sourceName is! String ||
        title is! String ||
        sourceUrl is! String ||
        watchUrl is! String) {
      return null;
    }

    return weeklyVideoFromUrl(
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      title: title,
      url: watchUrl,
    );
  }
}

WeeklyVideo? weeklyVideoFromUrl({
  required String sourceName,
  required String sourceUrl,
  required String title,
  required String url,
}) {
  final trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmedUrl);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return null;
  }

  if (sourceName == 'YouTube') {
    final videoId = _youtubeVideoId(uri);
    if (videoId == null) {
      return null;
    }

    return WeeklyVideo(
      title: title,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      watchUrl: trimmedUrl,
      embedUrl: 'https://www.youtube-nocookie.com/embed/$videoId',
    );
  }

  if (sourceName == 'Vimeo') {
    final videoId = _vimeoVideoId(uri);
    if (videoId == null) {
      return null;
    }

    return WeeklyVideo(
      title: title,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      watchUrl: trimmedUrl,
      embedUrl: 'https://player.vimeo.com/video/$videoId',
    );
  }

  return null;
}

String? _youtubeVideoId(Uri uri) {
  final host = uri.host.toLowerCase();
  if (host == 'youtu.be') {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }

  if (host.contains('youtube.com')) {
    if (uri.queryParameters['v'] case final videoId?) {
      return videoId;
    }

    if (uri.pathSegments.length >= 2 &&
        (uri.pathSegments.first == 'embed' ||
            uri.pathSegments.first == 'shorts')) {
      return uri.pathSegments[1];
    }
  }

  return null;
}

String? _vimeoVideoId(Uri uri) {
  final host = uri.host.toLowerCase();
  if (!host.contains('vimeo.com')) {
    return null;
  }

  for (final segment in uri.pathSegments.reversed) {
    if (RegExp(r'^\d+$').hasMatch(segment)) {
      return segment;
    }
  }

  return null;
}

const youtubeWeeklySourceUrl = 'https://www.youtube.com/@hjpeacetv8814/videos';
const vimeoWeeklySourceUrl = 'https://vimeo.com/eume';

const weeklyVideos = [
  WeeklyVideo(
    title: 'HJ Global News Português (27.06.2026)',
    sourceName: 'YouTube',
    sourceUrl: youtubeWeeklySourceUrl,
    watchUrl: 'https://www.youtube.com/watch?v=uXhZBoveiiM',
    embedUrl: 'https://www.youtube-nocookie.com/embed/uXhZBoveiiM',
  ),
  WeeklyVideo(
    title: 'Weekly News',
    sourceName: 'Vimeo',
    sourceUrl: vimeoWeeklySourceUrl,
    watchUrl: 'https://vimeo.com/1202206348',
    embedUrl: 'https://player.vimeo.com/video/1202206348',
  ),
];
