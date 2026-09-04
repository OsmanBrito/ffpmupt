class WeeklyVideo {
  const WeeklyVideo.unconfigured({
    required this.sourceName,
    required this.sourceUrl,
  }) : title = '',
       watchUrl = '',
       embedUrl = '';

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

  bool get isConfigured =>
      watchUrl.trim().isNotEmpty && embedUrl.trim().isNotEmpty;

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

    final parsed = weeklyVideoFromUrl(
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      title: title,
      url: watchUrl,
    );
    if (parsed == null) {
      return null;
    }

    final savedEmbedUrl = map['embedUrl'];
    if (savedEmbedUrl is! String ||
        !_isTrustedEmbedUrl(savedEmbedUrl, sourceName)) {
      return parsed;
    }

    return WeeklyVideo(
      title: parsed.title,
      sourceName: parsed.sourceName,
      sourceUrl: parsed.sourceUrl,
      watchUrl: parsed.watchUrl,
      embedUrl: savedEmbedUrl,
    );
  }
}

bool _isTrustedEmbedUrl(String value, String sourceName) {
  final uri = Uri.tryParse(value);
  if (uri == null || !_isSecureWebUrl(uri)) {
    return false;
  }

  final host = uri.host.toLowerCase();
  return switch (sourceName) {
    'YouTube' => host == 'www.youtube-nocookie.com' && uri.port == 443,
    'Vimeo' => host == 'player.vimeo.com' && uri.port == 443,
    _ => false,
  };
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
  if (uri == null || !_isSecureWebUrl(uri)) {
    return null;
  }

  final sourceUri = Uri.tryParse(sourceUrl);
  if (sourceUri == null || !_isSecureWebUrl(sourceUri)) {
    return null;
  }

  if (sourceName == 'YouTube') {
    if (!_youtubeHosts.contains(uri.host.toLowerCase()) ||
        !_youtubeHosts.contains(sourceUri.host.toLowerCase())) {
      return null;
    }
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
    if (!_vimeoHosts.contains(uri.host.toLowerCase()) ||
        !_vimeoHosts.contains(sourceUri.host.toLowerCase())) {
      return null;
    }
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
    final videoId = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    return videoId != null && _youtubeIdPattern.hasMatch(videoId)
        ? videoId
        : null;
  }

  if (_youtubeHosts.contains(host)) {
    if (uri.queryParameters['v'] case final videoId?) {
      return _youtubeIdPattern.hasMatch(videoId) ? videoId : null;
    }

    if (uri.pathSegments.length >= 2 &&
        (uri.pathSegments.first == 'embed' ||
            uri.pathSegments.first == 'shorts')) {
      final videoId = uri.pathSegments[1];
      return _youtubeIdPattern.hasMatch(videoId) ? videoId : null;
    }
  }

  return null;
}

String? _vimeoVideoId(Uri uri) {
  final host = uri.host.toLowerCase();
  if (!_vimeoHosts.contains(host)) {
    return null;
  }

  for (final segment in uri.pathSegments.reversed) {
    if (RegExp(r'^\d{1,12}$').hasMatch(segment)) {
      return segment;
    }
  }

  return null;
}

const _youtubeHosts = {
  'www.youtube.com',
  'youtube.com',
  'm.youtube.com',
  'music.youtube.com',
  'youtu.be',
};

final _youtubeIdPattern = RegExp(r'^[A-Za-z0-9_-]{6,20}$');

const _vimeoHosts = {'vimeo.com', 'www.vimeo.com', 'player.vimeo.com'};

bool _isSecureWebUrl(Uri uri) {
  return uri.scheme.toLowerCase() == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      uri.port == 443;
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
