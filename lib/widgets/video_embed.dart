import 'package:flutter/material.dart';

import 'video_embed_stub.dart'
    if (dart.library.html) 'video_embed_web.dart'
    as platform_video_embed;

class VideoEmbed extends StatelessWidget {
  const VideoEmbed({
    super.key,
    required this.embedUrl,
    required this.title,
    required this.watchUrl,
  });

  final String embedUrl;
  final String title;
  final String watchUrl;

  @override
  Widget build(BuildContext context) {
    return platform_video_embed.buildVideoEmbed(
      context: context,
      embedUrl: embedUrl,
      title: title,
      watchUrl: watchUrl,
    );
  }
}
