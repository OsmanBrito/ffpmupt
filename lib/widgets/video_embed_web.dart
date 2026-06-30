// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

final _registeredViewTypes = <String>{};

Widget buildVideoEmbed({
  required BuildContext context,
  required String embedUrl,
  required String title,
  required String watchUrl,
}) {
  final viewType = 'weekly-video-${embedUrl.hashCode}';

  if (_registeredViewTypes.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      return html.IFrameElement()
        ..src = embedUrl
        ..title = title
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..allowFullscreen = true
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  return HtmlElementView(viewType: viewType);
}
