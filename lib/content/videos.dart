class WeeklyVideo {
  const WeeklyVideo({
    required this.title,
    required this.sourceName,
    required this.watchUrl,
    required this.embedUrl,
  });

  final String title;
  final String sourceName;
  final String watchUrl;
  final String embedUrl;
}

WeeklyVideo? weeklyVideoFromUrl({
  required String sourceName,
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
    watchUrl: 'https://www.youtube.com/watch?v=uXhZBoveiiM',
    embedUrl: 'https://www.youtube-nocookie.com/embed/uXhZBoveiiM',
  ),
  WeeklyVideo(
    title: 'Weekly News',
    sourceName: 'Vimeo',
    watchUrl: 'https://vimeo.com/1202206348',
    embedUrl: 'https://player.vimeo.com/video/1202206348',
  ),
];
