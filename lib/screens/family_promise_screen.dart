import 'dart:async';

import 'package:ffpmupt/content/family_promise.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/family_promise.dart';
import 'package:ffpmupt/services/family_promise_repository.dart';
import 'package:ffpmupt/services/pledge_speaker.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:ffpmupt/theme/app_theme.dart';
import 'package:ffpmupt/widgets/reading_mode_button.dart';
import 'package:flutter/material.dart';

class FamilyPromiseScreen extends StatefulWidget {
  const FamilyPromiseScreen({super.key, required this.country});

  final CountryModel country;

  @override
  State<FamilyPromiseScreen> createState() => _FamilyPromiseScreenState();
}

class _FamilyPromiseScreenState extends State<FamilyPromiseScreen> {
  final PledgeSpeaker _speaker = PledgeSpeaker();
  late final FamilyPromiseRepository _repository;
  StreamSubscription<List<FamilyPromiseDocument>>? _promiseSubscription;
  late List<FamilyPromiseDocument> _promises;
  late String _currentLanguageCode;
  int _currentIndex = 0;
  List<int> _history = [];
  bool _isSpeaking = false;
  bool _isPresentation = false;

  String get _historyKey => 'family_promise_history_${widget.country.code}_v1';

  FamilyPromiseDocument get _currentPromise {
    return _promises.firstWhere(
      (promise) => promise.languageCode == _currentLanguageCode,
      orElse: () => _promises.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _repository = FamilyPromiseRepository(
      countryCode: widget.country.code,
      defaultLanguage: widget.country.defaultLanguage,
    );
    _promises = _repository.bundledDefaults;
    _currentLanguageCode = _initialLanguage(_promises);
    _promiseSubscription = _repository.watchPublicPromises().listen(
      _handlePromises,
    );
    _configureSpeaker();
    unawaited(_loadHistory());
  }

  @override
  void dispose() {
    _promiseSubscription?.cancel();
    _speaker.dispose();
    super.dispose();
  }

  String _initialLanguage(List<FamilyPromiseDocument> promises) {
    final mainLanguage = widget.country.defaultLanguage;
    return promises.any((promise) => promise.languageCode == mainLanguage)
        ? mainLanguage
        : promises.first.languageCode;
  }

  void _handlePromises(List<FamilyPromiseDocument> promises) {
    if (!mounted || promises.isEmpty) {
      return;
    }
    setState(() {
      _promises = promises;
      if (!promises.any(
        (promise) => promise.languageCode == _currentLanguageCode,
      )) {
        _currentLanguageCode = _initialLanguage(promises);
      }
      _currentIndex = familyPromiseIndexForVerseCount(
        selectedIndex: _currentIndex,
        verseCount: _currentPromise.verses.length,
      );
    });
  }

  void _configureSpeaker() {
    _speaker.onFinished = () {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    };
    unawaited(_speaker.configure());
  }

  void _changeLanguage(String languageCode) {
    final nextPromise = _promises.firstWhere(
      (promise) => promise.languageCode == languageCode,
      orElse: () => _currentPromise,
    );
    setState(() {
      _currentLanguageCode = nextPromise.languageCode;
      _currentIndex = familyPromiseIndexForVerseCount(
        selectedIndex: _currentIndex,
        verseCount: nextPromise.verses.length,
      );
    });
    unawaited(_stopSpeech());
  }

  void _showItem(int index) {
    setState(() => _currentIndex = index);
    unawaited(_stopSpeech());
  }

  Future<void> _stopSpeech() async {
    if (!_isSpeaking) {
      return;
    }
    await _speaker.stop();
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _toggleSpeech() async {
    if (_currentLanguageCode != 'ko') {
      return;
    }
    if (_isSpeaking) {
      await _stopSpeech();
      return;
    }
    setState(() => _isSpeaking = true);
    final speechIndex = _currentIndex.clamp(
      0,
      koreanFamilyPromiseSpeech.length - 1,
    );
    await _speaker.speak(koreanFamilyPromiseSpeech[speechIndex]);
  }

  Future<void> _loadHistory() async {
    final stored = await LocalStore.getStringList(_historyKey) ?? [];
    if (mounted) {
      setState(() {
        _history = stored.map(int.tryParse).whereType<int>().toList();
      });
    }
  }

  Future<void> _markCurrentAsUsed() async {
    final updated = [
      _currentIndex,
      ..._history.where((index) => index != _currentIndex),
    ].take(8).toList();
    await LocalStore.setStringList(
      _historyKey,
      updated.map((index) => index.toString()).toList(),
    );
    if (mounted) {
      setState(() => _history = updated);
    }
  }

  Future<void> _resetHistory() async {
    await LocalStore.setStringList(_historyKey, []);
    if (mounted) {
      setState(() => _history = []);
    }
  }

  Color _colorFor(String languageCode) {
    return switch (languageCode) {
      'ko' => const Color(0xff306f8f),
      'en' => const Color(0xff8c3543),
      _ => const Color(0xff2f6b4f),
    };
  }

  String _languageLabel(String languageCode) {
    return appLanguageLabel(appLanguageFromCode(languageCode));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final promise = _currentPromise;
    final items = promise.verses;
    final color = _colorFor(promise.languageCode);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(promise.title),
        actions: [
          ReadingModeButton(
            isPresentation: _isPresentation,
            onPressed: () => setState(() => _isPresentation = !_isPresentation),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _isPresentation
                    ? AppTypography.presentationWidth
                    : AppTypography.readingWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _promises)
                        ElevatedButton.icon(
                          onPressed: () => _changeLanguage(item.languageCode),
                          icon: const Icon(Icons.translate),
                          label: Text(_languageLabel(item.languageCode)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                promise.languageCode == item.languageCode
                                ? _colorFor(item.languageCode)
                                : Colors.white,
                            foregroundColor:
                                promise.languageCode == item.languageCode
                                ? Colors.white
                                : _colorFor(item.languageCode),
                          ),
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
                          onSelected: (_) => _showItem(index),
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
                          if (index < items.length)
                            ActionChip(
                              avatar: const Icon(Icons.history, size: 18),
                              label: Text(
                                '${strings.promiseHistoryLabel} ${index + 1}',
                              ),
                              onPressed: () => _showItem(index),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_currentIndex + 1} / ${items.length}',
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton.filledTonal(
                                tooltip: strings.previousLyric,
                                onPressed: _currentIndex == 0
                                    ? null
                                    : () => _showItem(_currentIndex - 1),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              const SizedBox(width: 16),
                              IconButton.filledTonal(
                                tooltip: strings.nextLyric,
                                onPressed: _currentIndex == items.length - 1
                                    ? null
                                    : () => _showItem(_currentIndex + 1),
                                icon: const Icon(Icons.arrow_forward),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _markCurrentAsUsed,
                                icon: const Icon(Icons.history),
                                label: Text(strings.markAsUsed),
                              ),
                              if (_history.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: _resetHistory,
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(strings.resetHistory),
                                ),
                              if (promise.languageCode == 'ko')
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
                          ),
                          const SizedBox(height: 28),
                          LayoutBuilder(
                            builder: (context, constraints) => Text(
                              items[_currentIndex],
                              textAlign: _isPresentation
                                  ? TextAlign.center
                                  : TextAlign.start,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: AppTypography.readingTextSize(
                                  availableWidth: constraints.maxWidth,
                                  presentation: _isPresentation,
                                ),
                                height: _isPresentation ? 1.28 : 1.55,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w500,
                              ),
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
