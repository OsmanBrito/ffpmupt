enum SongCategory {
  holy('holy'),
  fellowship('fellowship'),
  english('english'),
  worship('worship'),
  international('international');

  const SongCategory(this.value);
  final String value;

  static SongCategory? fromValue(String value) {
    for (final category in values) {
      if (category.value == value) {
        return category;
      }
    }
    return null;
  }
}

enum ChorusMode {
  none('none'),
  first('first'),
  second('second');

  const ChorusMode(this.value);
  final String value;

  static ChorusMode? fromValue(String value) {
    for (final mode in values) {
      if (mode.value == value) {
        return mode;
      }
    }
    return null;
  }
}

enum SongVideoProvider {
  youtube('youtube'),
  vimeo('vimeo'),
  other('other');

  const SongVideoProvider(this.value);
  final String value;

  static SongVideoProvider? fromValue(String value) {
    for (final provider in values) {
      if (provider.value == value) {
        return provider;
      }
    }
    return null;
  }
}

class SongAudioTrack {
  const SongAudioTrack({
    required this.id,
    required this.label,
    required this.url,
    required this.storagePath,
    required this.verseStartSeconds,
    required this.verseChangeSeconds,
    required this.enabled,
    required this.sortOrder,
  });

  final String id;
  final String label;
  final String url;
  final String? storagePath;
  final List<int> verseStartSeconds;
  final List<int> verseChangeSeconds;
  final bool enabled;
  final int sortOrder;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'label': label,
      'url': url,
      'storagePath': storagePath,
      'verseStartSeconds': verseStartSeconds,
      'verseChangeSeconds': verseChangeSeconds,
      'enabled': enabled,
      'sortOrder': sortOrder,
    };
  }

  static SongAudioTrack? fromMap(Map<String, Object?> map) {
    final id = map['id'];
    final label = map['label'];
    final url = map['url'];
    final storagePath = map['storagePath'];
    final verseStartSeconds = map['verseStartSeconds'];
    final verseChangeSeconds = map['verseChangeSeconds'];
    final enabled = map['enabled'];
    final sortOrder = map['sortOrder'];

    if (id is! String ||
        label is! String ||
        url is! String ||
        (storagePath != null && storagePath is! String) ||
        verseStartSeconds is! List ||
        (verseChangeSeconds != null && verseChangeSeconds is! List) ||
        enabled is! bool ||
        sortOrder is! int) {
      return null;
    }

    final starts = verseStartSeconds.whereType<int>().toList();
    if (starts.length != verseStartSeconds.length) {
      return null;
    }
    final changes = (verseChangeSeconds as List? ?? const <Object>[])
        .whereType<int>()
        .toList();
    if (verseChangeSeconds is List &&
        changes.length != verseChangeSeconds.length) {
      return null;
    }

    return SongAudioTrack(
      id: id,
      label: label,
      url: url,
      storagePath: storagePath as String?,
      verseStartSeconds: starts,
      verseChangeSeconds: changes,
      enabled: enabled,
      sortOrder: sortOrder,
    );
  }
}

class SongVideoLink {
  const SongVideoLink({
    required this.id,
    required this.provider,
    required this.label,
    required this.watchUrl,
    required this.embedUrl,
    required this.enabled,
    required this.sortOrder,
  });

  final String id;
  final SongVideoProvider provider;
  final String label;
  final String watchUrl;
  final String embedUrl;
  final bool enabled;
  final int sortOrder;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'provider': provider.value,
      'label': label,
      'watchUrl': watchUrl,
      'embedUrl': embedUrl,
      'enabled': enabled,
      'sortOrder': sortOrder,
    };
  }

  static SongVideoLink? fromMap(Map<String, Object?> map) {
    final id = map['id'];
    final providerValue = map['provider'];
    final label = map['label'];
    final watchUrl = map['watchUrl'];
    final embedUrl = map['embedUrl'];
    final enabled = map['enabled'];
    final sortOrder = map['sortOrder'];

    if (id is! String ||
        providerValue is! String ||
        label is! String ||
        watchUrl is! String ||
        embedUrl is! String ||
        enabled is! bool ||
        sortOrder is! int) {
      return null;
    }

    final provider = SongVideoProvider.fromValue(providerValue);
    if (provider == null) {
      return null;
    }

    return SongVideoLink(
      id: id,
      provider: provider,
      label: label,
      watchUrl: watchUrl,
      embedUrl: embedUrl,
      enabled: enabled,
      sortOrder: sortOrder,
    );
  }
}

class SongDocument {
  const SongDocument({
    required this.id,
    required this.title,
    required this.page,
    required this.category,
    required this.languageCode,
    required this.lyrics,
    required this.chorusMode,
    required this.enabled,
    required this.sortOrder,
    required this.audioTracks,
    required this.videoLinks,
  });

  final String id;
  final String title;
  final String page;
  final SongCategory category;
  final String languageCode;
  final List<String> lyrics;
  final ChorusMode chorusMode;
  final bool enabled;
  final int sortOrder;
  final List<SongAudioTrack> audioTracks;
  final List<SongVideoLink> videoLinks;

  SongDocument copyWith({
    String? id,
    String? title,
    String? page,
    SongCategory? category,
    String? languageCode,
    List<String>? lyrics,
    ChorusMode? chorusMode,
    bool? enabled,
    int? sortOrder,
    List<SongAudioTrack>? audioTracks,
    List<SongVideoLink>? videoLinks,
  }) {
    return SongDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      page: page ?? this.page,
      category: category ?? this.category,
      languageCode: languageCode ?? this.languageCode,
      lyrics: lyrics ?? this.lyrics,
      chorusMode: chorusMode ?? this.chorusMode,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
      audioTracks: audioTracks ?? this.audioTracks,
      videoLinks: videoLinks ?? this.videoLinks,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'page': page,
      'category': category.value,
      'languageCode': languageCode,
      'lyrics': lyrics,
      'chorusMode': chorusMode.value,
      'enabled': enabled,
      'sortOrder': sortOrder,
      'audioTracks': audioTracks.map((track) => track.toMap()).toList(),
      'videoLinks': videoLinks.map((video) => video.toMap()).toList(),
    };
  }

  static SongDocument? fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    final title = map['title'];
    final page = map['page'];
    final categoryValue = map['category'];
    final languageCode = map['languageCode'];
    final lyricsValue = map['lyrics'];
    final chorusModeValue = map['chorusMode'];
    final enabled = map['enabled'];
    final sortOrder = map['sortOrder'];
    final audioTracksValue = map['audioTracks'];
    final videoLinksValue = map['videoLinks'];

    if (title is! String ||
        page is! String ||
        categoryValue is! String ||
        languageCode is! String ||
        lyricsValue is! List ||
        chorusModeValue is! String ||
        enabled is! bool ||
        sortOrder is! int ||
        audioTracksValue is! List ||
        videoLinksValue is! List) {
      return null;
    }

    final category = SongCategory.fromValue(categoryValue);
    final chorusMode = ChorusMode.fromValue(chorusModeValue);
    final lyrics = lyricsValue.whereType<String>().toList();
    final audioTracks = <SongAudioTrack>[];
    final videoLinks = <SongVideoLink>[];

    if (category == null ||
        chorusMode == null ||
        lyrics.length != lyricsValue.length) {
      return null;
    }

    for (final value in audioTracksValue) {
      if (value is! Map) {
        return null;
      }
      final track = SongAudioTrack.fromMap(Map<String, Object?>.from(value));
      if (track == null) {
        return null;
      }
      audioTracks.add(track);
    }

    for (final value in videoLinksValue) {
      if (value is! Map) {
        return null;
      }
      final video = SongVideoLink.fromMap(Map<String, Object?>.from(value));
      if (video == null) {
        return null;
      }
      videoLinks.add(video);
    }

    return SongDocument(
      id: id,
      title: title,
      page: page,
      category: category,
      languageCode: languageCode,
      lyrics: lyrics,
      chorusMode: chorusMode,
      enabled: enabled,
      sortOrder: sortOrder,
      audioTracks: audioTracks,
      videoLinks: videoLinks,
    );
  }
}
