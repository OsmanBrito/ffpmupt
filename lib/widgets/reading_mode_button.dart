import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/reading_song_strings.dart';
import 'package:flutter/material.dart';

class ReadingModeButton extends StatelessWidget {
  const ReadingModeButton({
    super.key,
    required this.isPresentation,
    required this.onPressed,
  });

  final bool isPresentation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final copy = ReadingSongStrings.of(
      AppLanguageScope.watch(context).language,
    );
    final label =
        copy[isPresentation
            ? ReadingSongText.readingMode
            : ReadingSongText.presentationMode];
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(
        isPresentation
            ? Icons.chrome_reader_mode_outlined
            : Icons.slideshow_outlined,
      ),
    );
  }
}
