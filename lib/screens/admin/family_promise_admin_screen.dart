import 'dart:async';

import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/family_promise.dart';
import 'package:ffpmupt/services/family_promise_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/admin_copy.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/p0_strings.dart';
import 'package:flutter/material.dart';

class FamilyPromiseAdminScreen extends StatefulWidget {
  const FamilyPromiseAdminScreen({super.key, required this.country});

  final CountryModel country;

  @override
  State<FamilyPromiseAdminScreen> createState() =>
      _FamilyPromiseAdminScreenState();
}

class _FamilyPromiseAdminScreenState extends State<FamilyPromiseAdminScreen> {
  late final FamilyPromiseRepository _repository;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _repository = FamilyPromiseRepository(
      countryCode: widget.country.code,
      defaultLanguage: widget.country.defaultLanguage,
    );
  }

  List<FamilyPromiseDocument> _mergePromises(
    List<FamilyPromiseDocument> saved,
  ) {
    final byLanguage = {
      for (final promise in _repository.bundledDefaults)
        promise.languageCode: promise,
      for (final promise in saved) promise.languageCode: promise,
    };
    final mainLanguage = widget.country.defaultLanguage;
    byLanguage.putIfAbsent(
      mainLanguage,
      () => FamilyPromiseDocument(
        languageCode: mainLanguage,
        title: 'Family Pledge',
        verses: const ['', '', '', '', '', '', '', ''],
        enabled: false,
        sortOrder: 0,
      ),
    );
    final promises = byLanguage.values.toList()
      ..sort((left, right) {
        if (left.languageCode == mainLanguage) return -1;
        if (right.languageCode == mainLanguage) return 1;
        return left.sortOrder.compareTo(right.sortOrder);
      });
    return promises;
  }

  Future<void> _importDefaults() async {
    setState(() => _isImporting = true);
    try {
      final count = await _repository.importMissingDefaults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count == 0
                  ? 'A Promessa padrão já está preparada.'
                  : '$count idiomas adicionados.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _edit(FamilyPromiseDocument promise) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FamilyPromiseEditorScreen(
          repository: _repository,
          promise: promise,
        ),
      ),
    );
  }

  bool _isConfigured(FamilyPromiseDocument promise) {
    return promise.verses.any((verse) => verse.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final p0 = P0Strings.of(AppLanguageScope.watch(context).language);
    return Scaffold(
      appBar: AppBar(title: Text(strings.familyPromise)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: StreamBuilder<List<FamilyPromiseDocument>>(
              stream: _repository.watchAdminPromises(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(p0[P0Text.loadFailed]));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final promises = _mergePromises(snapshot.data!);
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isImporting ? null : _importDefaults,
                        icon: _isImporting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_outlined),
                        label: Text(
                          '${p0[P0Text.prepare]} · ${strings.defaultLanguage}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final promise in promises) ...[
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          leading: const Icon(Icons.auto_stories_outlined),
                          title: Text(
                            _languageLabel(promise.languageCode),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            _isConfigured(promise)
                                ? promise.title
                                : adminText(context, 'Ainda não configurada'),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value:
                                    promise.enabled && _isConfigured(promise),
                                onChanged: !_isConfigured(promise)
                                    ? null
                                    : (enabled) => unawaited(
                                        _repository.setEnabled(
                                          promise,
                                          enabled,
                                        ),
                                      ),
                              ),
                              IconButton(
                                tooltip: adminText(context, 'Editar'),
                                onPressed: () => _edit(promise),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            ],
                          ),
                          onTap: () => _edit(promise),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class FamilyPromiseEditorScreen extends StatefulWidget {
  const FamilyPromiseEditorScreen({
    super.key,
    required this.repository,
    required this.promise,
  });

  final FamilyPromiseRepository repository;
  final FamilyPromiseDocument promise;

  @override
  State<FamilyPromiseEditorScreen> createState() =>
      _FamilyPromiseEditorScreenState();
}

class _FamilyPromiseEditorScreenState extends State<FamilyPromiseEditorScreen> {
  late final TextEditingController _titleController;
  late final List<TextEditingController> _verseControllers;
  late bool _enabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.promise.title);
    _verseControllers = List.generate(
      8,
      (index) => TextEditingController(
        text: index < widget.promise.verses.length
            ? widget.promise.verses[index]
            : '',
      ),
    );
    _enabled = widget.promise.enabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _verseControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final verses = _verseControllers
        .map((controller) => controller.text.trim())
        .toList();
    if (title.isEmpty || verses.any((verse) => verse.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(context, 'Preencha o título e os oito pontos.'),
          ),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.repository.save(
        widget.promise.copyWith(
          title: title,
          verses: verses,
          enabled: _enabled,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    return Scaffold(
      appBar: AppBar(
        title: Text(_languageLabel(widget.promise.languageCode)),
        actions: [
          IconButton(
            tooltip: adminText(context, 'Guardar'),
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: adminText(context, 'Título'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(adminText(context, 'Idioma visível')),
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _verseControllers.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _verseControllers[index],
                      minLines: 3,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText:
                            '${adminText(context, 'Ponto')} ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(strings.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _languageLabel(String languageCode) {
  return appLanguageLabel(appLanguageFromCode(languageCode));
}
