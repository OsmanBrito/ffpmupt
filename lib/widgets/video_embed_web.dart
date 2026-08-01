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
      final container = html.DivElement()
        ..style.position = 'relative'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#eef2ef';
      final status = html.DivElement()
        ..text = title
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.left = '0'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.padding = '24px'
        ..style.textAlign = 'center'
        ..style.fontFamily = 'sans-serif'
        ..style.color = '#42504b';
      final frame = html.IFrameElement()
        ..src = embedUrl
        ..title = title
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..allowFullscreen = true
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.opacity = '0';
      frame.onLoad.first.then((_) {
        frame.style.opacity = '1';
        status.remove();
      });
      frame.onError.first.then((_) {
        status.text = '$title · $watchUrl';
      });
      container.children.addAll([status, frame]);
      return container;
    });
  }

  return HtmlElementView(viewType: viewType);
}
