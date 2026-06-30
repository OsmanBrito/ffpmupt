import 'dart:async';

import 'package:ffpmupt/content/family_promise.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pledgeHistoryKey = 'family_promise_history_v1';

class FamilyPromiseScreen extends StatefulWidget {
  const FamilyPromiseScreen({Key? key}) : super(key: key);

  @override
  State<FamilyPromiseScreen> createState() => _FamilyPromiseScreenState();
}

class _FamilyPromiseScreenState extends State<FamilyPromiseScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  int _currentIndex = 0;
  List<int> _history = [];
  bool _isSpeaking = false;
  bool _hasConfiguredKoreanVoice = false;
  FamilyPromiseLanguage _currentLanguage = FamilyPromiseLanguage.korean;

  @override
  void initState() {
    super.initState();
    _configureTts();
    unawaited(_configureKoreanVoice());
    _loadHistory();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _configureTts() {
    _flutterTts.setCompletionHandler(() {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSpeaking = false;
      });
    });
    _flutterTts.setCancelHandler(() {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSpeaking = false;
      });
    });
    _flutterTts.setErrorHandler((message) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _configureKoreanVoice() async {
    try {
      await _flutterTts.setLanguage(koreanFamilyPromiseTtsLocale);
      await _flutterTts.setSpeechRate(0.42);
      await _flutterTts.setPitch(1);
    } catch (_) {
      return;
    }

    if (_hasConfiguredKoreanVoice) {
      return;
    }

    final dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      _hasConfiguredKoreanVoice = true;
      return;
    }

    if (voices is! List) {
      _hasConfiguredKoreanVoice = true;
      return;
    }

    for (final voice in voices) {
      if (voice is! Map) {
        continue;
      }

      final rawLocale = voice['locale']?.toString();
      final name = voice['name']?.toString();
      if (rawLocale == null || name == null) {
        continue;
      }

      final locale = rawLocale.replaceAll('_', '-').toLowerCase();
      if (locale != koreanFamilyPromiseTtsLocale.toLowerCase()) {
        continue;
      }

      try {
        await _flutterTts.setVoice({
          'name': name,
          'locale': rawLocale,
        });
      } catch (_) {
        _hasConfiguredKoreanVoice = true;
        return;
      }

      _hasConfiguredKoreanVoice = true;
      return;
    }

    _hasConfiguredKoreanVoice = true;
  }

  void _nextItem() {
    setState(() {
      final items = familyPromise[_currentLanguage]!;
      if (_currentIndex < items.length - 1) {
        _currentIndex = _currentIndex + 1;
      }
    });
    unawaited(_stopSpeech());
  }

  void _previousItem() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex = _currentIndex - 1;
      }
    });
    unawaited(_stopSpeech());
  }

  void _changeLanguage(FamilyPromiseLanguage language) {
    setState(() {
      _currentLanguage = language;
    });
    unawaited(_stopSpeech());
  }

  Future<void> _stopSpeech() async {
    if (!_isSpeaking) {
      return;
    }

    await _flutterTts.stop();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSpeaking = false;
    });
  }

  Future<void> _toggleSpeech() async {
    if (_currentLanguage != FamilyPromiseLanguage.korean) {
      return;
    }

    if (_isSpeaking) {
      await _flutterTts.stop();
      if (!mounted) {
        return;
      }

      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    await _configureKoreanVoice();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSpeaking = true;
    });

    await _flutterTts.speak(koreanFamilyPromiseSpeech[_currentIndex]);
  }

  Future<void> _loadHistory() async {
    final storedHistory =
        await _preferences.getStringList(_pledgeHistoryKey) ?? [];

    if (!mounted) {
      return;
    }

    setState(() {
      _history = storedHistory
          .map(int.tryParse)
          .whereType<int>()
          .where((index) => index >= 0)
          .toList();
    });
  }

  Future<void> _markCurrentAsUsed() async {
    final updatedHistory = [
      _currentIndex,
      ..._history.where((index) => index != _currentIndex),
    ].take(8).toList();

    await _preferences.setStringList(
      _pledgeHistoryKey,
      updatedHistory.map((index) => index.toString()).toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _history = updatedHistory;
    });
  }

  void _showHistoryItem(int index) {
    final items = familyPromise[_currentLanguage]!;
    if (index >= items.length) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    unawaited(_stopSpeech());
  }

  Color _colorByLanguage(FamilyPromiseLanguage language) {
    switch (language) {
      case FamilyPromiseLanguage.portuguese:
        return const Color(0xff2f6b4f);
      case FamilyPromiseLanguage.korean:
        return const Color(0xff306f8f);
      case FamilyPromiseLanguage.english:
        return const Color(0xff8c3543);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final items = familyPromise[_currentLanguage]!;
    final color = _colorByLanguage(_currentLanguage);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Text(
          strings.familyPromise,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final language in FamilyPromiseLanguage.values)
                        _PromiseLanguageButton(
                          label: _promiseLanguageLabel(language),
                          selected: _currentLanguage == language,
                          color: _colorByLanguage(language),
                          onPressed: () => _changeLanguage(language),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < items.length; index++)
                        ChoiceChip(
                          label: Text('${index + 1}'),
                          selected: _currentIndex == index,
                          selectedColor: color.withValues(alpha: 0.18),
                          onSelected: (_) {
                            setState(() {
                              _currentIndex = index;
                            });
                            unawaited(_stopSpeech());
                          },
                        ),
                    ],
                  ),
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final index in _history)
                          ActionChip(
                            avatar: const Icon(Icons.history, size: 18),
                            label: Text(
                              '${strings.promiseHistoryLabel} ${index + 1}',
                            ),
                            onPressed: () => _showHistoryItem(index),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 30,
                      ),
                      child: Column(
                        children: [
                          Text(
                            familyPromiseTitle(_currentLanguage),
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: kIsWeb ? 40 : null,
                              color: const Color(0xff1f2724),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_currentIndex + 1} / ${items.length}',
                            style: textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                onPressed:
                                    _currentIndex == 0 ? null : _previousItem,
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 16),
                              IconButton.filledTonal(
                                onPressed: _currentIndex == items.length - 1
                                    ? null
                                    : _nextItem,
                                icon: const Icon(Icons.arrow_forward),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _markCurrentAsUsed,
                            icon: const Icon(Icons.history),
                            label: Text(strings.markAsUsed),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (_currentLanguage ==
                              FamilyPromiseLanguage.korean) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _toggleSpeech,
                              icon: Icon(
                                _isSpeaking ? Icons.stop : Icons.play_arrow,
                              ),
                              label: Text(
                                _isSpeaking
                                    ? strings.stopReading
                                    : strings.readAloud,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          Text(
                            items[_currentIndex],
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: kIsWeb ? 34 : 21,
                              height: 1.38,
                              color: const Color(0xff293833),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _promiseLanguageLabel(FamilyPromiseLanguage language) {
  switch (language) {
    case FamilyPromiseLanguage.portuguese:
      return 'Português';
    case FamilyPromiseLanguage.korean:
      return 'Coreano';
    case FamilyPromiseLanguage.english:
      return 'English';
  }
}

class _PromiseLanguageButton extends StatelessWidget {
  const _PromiseLanguageButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.translate),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? color : Colors.white,
        foregroundColor: selected ? Colors.white : color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }
}
