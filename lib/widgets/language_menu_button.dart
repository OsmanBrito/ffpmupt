import 'dart:async';

import 'package:ffpmupt/settings/app_language.dart';
import 'package:flutter/material.dart';

/// Compact language switcher shared by the onboarding and admin entry points.
/// It intentionally disappears when a screen is rendered in isolation (for
/// example in a widget test without AppLanguageScope).
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppLanguageScope.maybeWatch(context);
    if (scope == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<AppLanguage>(
      tooltip: appLanguageLabel(scope.language),
      icon: const Icon(Icons.translate),
      onSelected: (language) =>
          unawaited(AppLanguageScope.read(context).setLanguage(language)),
      itemBuilder: (context) => [
        for (final language in AppLanguage.values)
          PopupMenuItem(
            value: language,
            child: Row(
              children: [
                if (language == scope.language)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check, size: 18),
                  )
                else
                  const SizedBox(width: 26),
                Text(appLanguageLabel(language)),
              ],
            ),
          ),
      ],
    );
  }
}
