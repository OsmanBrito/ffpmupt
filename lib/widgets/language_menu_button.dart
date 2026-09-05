import 'dart:async';

import 'package:ffpmupt/settings/app_language.dart';
import 'package:flutter/material.dart';

/// Compact language switcher shared by the onboarding and admin entry points.
/// It intentionally disappears when a screen is rendered in isolation (for
/// example in a widget test without AppLanguageScope).
class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key, this.showLabel = false});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scope = AppLanguageScope.maybeWatch(context);
    if (scope == null) {
      return const SizedBox.shrink();
    }

    final label = _shortLanguageLabel(scope.language);
    return PopupMenuButton<AppLanguage>(
      tooltip: appLanguageLabel(scope.language),
      icon: showLabel ? null : const Icon(Icons.translate),
      child: showLabel
          ? Semantics(
              button: true,
              label: appLanguageLabel(scope.language),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate, size: 20),
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            )
          : null,
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

String _shortLanguageLabel(AppLanguage language) => switch (language) {
  AppLanguage.portuguese => 'PT',
  AppLanguage.brazilian => 'PT-BR',
  AppLanguage.korean => 'KO',
  AppLanguage.english => 'EN',
  AppLanguage.spanish => 'ES',
  AppLanguage.german => 'DE',
  AppLanguage.italian => 'IT',
  AppLanguage.french => 'FR',
};
