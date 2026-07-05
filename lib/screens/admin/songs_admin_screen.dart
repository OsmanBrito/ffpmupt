import 'dart:async';

import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/services/song_import_service.dart';
import 'package:ffpmupt/services/song_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SongsAdminScreen extends StatefulWidget {
  const SongsAdminScreen({
    super.key,
    required this.countryCode,
    required this.defaultLanguage,
  });

  final String countryCode;
  final String defaultLanguage;

  @override
  State<SongsAdminScreen> createState() => _SongsAdminScreenState();
}

class _SongsAdminScreenState extends State<SongsAdminScreen> {
  late final SongRepository _repository;
  final _searchController = TextEditingController();
  bool _isImporting = false;
  bool _isReadingFiles = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repository = SongRepository(countryCode: widget.countryCode);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _importBundledSongs() async {
    setState(() => _isImporting = true);
    try {
      final imported = await _repository.importMissingBundledSongs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imported == 0
                  ? 'O catálogo já está atualizado.'
                  : '$imported músicas importadas.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível importar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _openEditor([SongDocument? song]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SongEditorScreen(
          song: song,
          countryCode: widget.countryCode,
          defaultLanguage: widget.defaultLanguage,
        ),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    try {
      final data = await rootBundle.load(
        'assets/modelo_importacao_musicas.xlsx',
      );
      await FilePicker.saveFile(
        dialogTitle: 'Guardar modelo de importação',
        fileName: 'modelo_importacao_musicas.xlsx',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível baixar o modelo: $error')),
        );
      }
    }
  }

  Future<void> _pickImportFiles(List<SongDocument> existingSongs) async {
    setState(() => _isReadingFiles = true);
    try {
      if (!await _repository.canRunInitialImport()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A importação inicial já foi concluída para este país.',
              ),
            ),
          );
        }
        return;
      }

      final selection = await FilePicker.pickFiles(
        dialogTitle: 'Selecionar músicas',
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'pptx'],
        allowMultiple: true,
        withData: true,
      );
      if (selection == null || selection.files.isEmpty || !mounted) {
        return;
      }

      final service = SongImportService();
      final songs = <SongDocument>[];
      final warnings = <String>[];
      final errors = <String>[];
      final firstSortOrder = existingSongs.isEmpty
          ? 0
          : existingSongs
                    .map((song) => song.sortOrder)
                    .reduce((left, right) => left > right ? left : right) +
                1;
      for (final file in selection.files) {
        final bytes = file.bytes;
        if (bytes == null) {
          errors.add('${file.name}: o navegador não forneceu os dados.');
          continue;
        }
        final result = service.parse(
          fileName: file.name,
          bytes: bytes,
          defaultLanguage: widget.defaultLanguage,
          startingSortOrder: firstSortOrder + songs.length,
        );
        songs.addAll(result.songs);
        warnings.addAll(result.warnings);
        errors.addAll(result.errors);
      }

      if (!mounted) {
        return;
      }
      if (songs.isEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nenhuma música reconhecida'),
            content: Text(errors.join('\n')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SongImportPreviewScreen(
            countryCode: widget.countryCode,
            songs: songs,
            warnings: warnings,
            errors: errors,
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (mounted) {
        final message = error.code == 'permission-denied'
            ? 'Sem permissão para verificar a importação. Publique as regras '
                  'mais recentes do Firestore e confirme que este país está '
                  'no campo countryCodes do administrador.'
            : 'Não foi possível verificar a importação: ${error.message ?? error.code}';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível importar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReadingFiles = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de músicas'),
        actions: [
          IconButton(
            tooltip: 'Nova música',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: StreamBuilder<List<SongDocument>>(
              stream: _repository.watchAdminSongs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Não foi possível carregar as músicas.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final normalizedQuery = _query.trim().toLowerCase();
                final songs = snapshot.data!
                    .where(
                      (song) =>
                          normalizedQuery.isEmpty ||
                          song.title.toLowerCase().contains(normalizedQuery) ||
                          song.page.toLowerCase().contains(normalizedQuery),
                    )
                    .toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: const InputDecoration(
                              labelText: 'Pesquisar música ou página',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _downloadTemplate,
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('Modelo XLSX'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: _isImporting
                                      ? null
                                      : _importBundledSongs,
                                  icon: _isImporting
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.cloud_upload_outlined),
                                  label: const Text('Catálogo padrão'),
                                ),
                                FilledButton.icon(
                                  onPressed: _isReadingFiles
                                      ? null
                                      : () => _pickImportFiles(snapshot.data!),
                                  icon: _isReadingFiles
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.upload_file),
                                  label: const Text('Importar XLSX/PPTX'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${songs.length} músicas',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                    Expanded(
                      child: songs.isEmpty
                          ? const Center(
                              child: Text('Nenhuma música encontrada.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              itemCount: songs.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final song = songs[index];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(song.page),
                                    ),
                                    title: Text(
                                      song.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${_categoryLabel(song.category)} · ${song.languageCode.toUpperCase()}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: song.enabled,
                                          onChanged: (enabled) => unawaited(
                                            _repository.setEnabled(
                                              song,
                                              enabled,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Editar',
                                          onPressed: () => _openEditor(song),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _openEditor(song),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova música',
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SongImportPreviewScreen extends StatefulWidget {
  const SongImportPreviewScreen({
    super.key,
    required this.countryCode,
    required this.songs,
    required this.warnings,
    required this.errors,
  });

  final String countryCode;
  final List<SongDocument> songs;
  final List<String> warnings;
  final List<String> errors;

  @override
  State<SongImportPreviewScreen> createState() =>
      _SongImportPreviewScreenState();
}

class _SongImportPreviewScreenState extends State<SongImportPreviewScreen> {
  late final SongRepository _repository;
  late final List<SongDocument> _songs;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = SongRepository(countryCode: widget.countryCode);
    _songs = List<SongDocument>.from(widget.songs);
  }

  Future<void> _editSong(int index) async {
    final song = _songs[index];
    final title = TextEditingController(text: song.title);
    final page = TextEditingController(text: song.page);
    final language = TextEditingController(text: song.languageCode);
    var category = song.category;
    final updated = await showDialog<SongDocument>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rever música'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: page,
                    decoration: const InputDecoration(
                      labelText: 'Página',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: language,
                    decoration: const InputDecoration(
                      labelText: 'Idioma',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SongCategory>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: SongCategory.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_categoryLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${song.lyrics.length} blocos de letra reconhecidos',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty || page.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  song.copyWith(
                    title: title.text.trim(),
                    page: page.text.trim(),
                    languageCode: language.text.trim().toLowerCase(),
                    category: category,
                  ),
                );
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    page.dispose();
    language.dispose();
    if (updated != null && mounted) {
      setState(() => _songs[index] = updated);
    }
  }

  Future<void> _import() async {
    setState(() => _isSaving = true);
    try {
      final imported = await _repository.importInitialSongs(_songs);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$imported músicas importadas.')));
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível importar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rever importação')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${_songs.length} músicas prontas para importar',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Confirme os dados antes de gravar. Áudios não fazem parte desta importação.',
                ),
                if (widget.warnings.isNotEmpty || widget.errors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xfffff7e6),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        [...widget.warnings, ...widget.errors].join('\n'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                for (var index = 0; index < _songs.length; index++)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(_songs[index].page)),
                      title: Text(
                        _songs[index].title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${_categoryLabel(_songs[index].category)} · ${_songs[index].languageCode.toUpperCase()} · ${_songs[index].lyrics.length} blocos',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Remover',
                            onPressed: () =>
                                setState(() => _songs.removeAt(index)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () => _editSong(index),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _songs.isEmpty || _isSaving ? null : _import,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Confirmar importação'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SongEditorScreen extends StatefulWidget {
  const SongEditorScreen({
    super.key,
    this.song,
    required this.countryCode,
    required this.defaultLanguage,
  });

  final SongDocument? song;
  final String countryCode;
  final String defaultLanguage;

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SongRepository _repository;
  late final TextEditingController _titleController;
  late final TextEditingController _pageController;
  late final TextEditingController _languageController;
  late final TextEditingController _sortOrderController;
  late final List<TextEditingController> _verseControllers;
  late final List<_AudioDraft> _audioDrafts;
  late SongCategory _category;
  late ChorusMode _chorusMode;
  late bool _enabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = SongRepository(countryCode: widget.countryCode);
    final song = widget.song;
    _titleController = TextEditingController(text: song?.title ?? '');
    _pageController = TextEditingController(text: song?.page ?? '');
    _languageController = TextEditingController(
      text: song?.languageCode ?? widget.defaultLanguage,
    );
    _sortOrderController = TextEditingController(
      text: (song?.sortOrder ?? 0).toString(),
    );
    _verseControllers = (song?.lyrics ?? const <String>[''])
        .map((verse) => TextEditingController(text: verse))
        .toList();
    _audioDrafts = (song?.audioTracks ?? const <SongAudioTrack>[])
        .map(_AudioDraft.fromTrack)
        .toList();
    _category = song?.category ?? SongCategory.holy;
    _chorusMode = song?.chorusMode ?? ChorusMode.none;
    _enabled = song?.enabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    _languageController.dispose();
    _sortOrderController.dispose();
    for (final controller in _verseControllers) {
      controller.dispose();
    }
    for (final draft in _audioDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addVerse() {
    setState(() => _verseControllers.add(TextEditingController()));
  }

  void _removeVerse(int index) {
    if (_verseControllers.length == 1) {
      return;
    }
    final controller = _verseControllers.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  void _addAudio() {
    setState(() => _audioDrafts.add(_AudioDraft.empty(_audioDrafts.length)));
  }

  void _removeAudio(int index) {
    final draft = _audioDrafts.removeAt(index);
    draft.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final audioTracks = <SongAudioTrack>[];
      for (var index = 0; index < _audioDrafts.length; index++) {
        audioTracks.add(_audioDrafts[index].toTrack(index));
      }
      final song = SongDocument(
        id: widget.song?.id ?? '',
        title: _titleController.text.trim(),
        page: _pageController.text.trim(),
        category: _category,
        languageCode: _languageController.text.trim().toLowerCase(),
        lyrics: _verseControllers
            .map((controller) => controller.text.trim())
            .where((verse) => verse.isNotEmpty)
            .toList(),
        chorusMode: _chorusMode,
        enabled: _enabled,
        sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
        audioTracks: audioTracks,
        videoLinks: widget.song?.videoLinks ?? const [],
      );
      await _repository.saveSong(song);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível guardar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song == null ? 'Nova música' : 'Editar música'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
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
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Informação',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 500,
                        child: TextFormField(
                          controller: _titleController,
                          validator: _required,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _pageController,
                          validator: _required,
                          decoration: const InputDecoration(
                            labelText: 'Página',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: TextFormField(
                          controller: _languageController,
                          validator: _required,
                          decoration: const InputDecoration(
                            labelText: 'Idioma',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextFormField(
                          controller: _sortOrderController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ordem',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: DropdownButtonFormField<SongCategory>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items: SongCategory.values
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(_categoryLabel(category)),
                                ),
                              )
                              .toList(),
                          onChanged: (category) {
                            if (category != null) {
                              setState(() => _category = category);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Música ativa'),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                  const Divider(height: 36),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Versos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Adicionar verso',
                        onPressed: _addVerse,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < _verseControllers.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _verseControllers[index],
                        validator: index == 0 ? _required : null,
                        minLines: 3,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Verso ${index + 1}',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: 'Remover verso',
                            onPressed: _verseControllers.length == 1
                                ? null
                                : () => _removeVerse(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Refrão',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ChorusMode>(
                    segments: const [
                      ButtonSegment(
                        value: ChorusMode.none,
                        label: Text('Nenhum'),
                      ),
                      ButtonSegment(
                        value: ChorusMode.first,
                        label: Text('Versos ímpares'),
                      ),
                      ButtonSegment(
                        value: ChorusMode.second,
                        label: Text('Versos pares'),
                      ),
                    ],
                    selected: {_chorusMode},
                    onSelectionChanged: (selection) =>
                        setState(() => _chorusMode = selection.first),
                  ),
                  const Divider(height: 36),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Áudios',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Adicionar áudio',
                        onPressed: _addAudio,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var index = 0; index < _audioDrafts.length; index++)
                    _AudioEditor(
                      key: ValueKey(_audioDrafts[index]),
                      index: index,
                      draft: _audioDrafts[index],
                      onRemove: () => _removeAudio(index),
                    ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Guardar música'),
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

class _AudioDraft {
  _AudioDraft({
    required this.id,
    required this.label,
    required this.url,
    required this.storagePath,
    required this.starts,
    required this.changes,
    required this.enabled,
  });

  factory _AudioDraft.empty(int index) {
    return _AudioDraft(
      id: 'audio-${index + 1}',
      label: TextEditingController(text: 'Principal'),
      url: TextEditingController(),
      storagePath: null,
      starts: TextEditingController(),
      changes: TextEditingController(),
      enabled: true,
    );
  }

  factory _AudioDraft.fromTrack(SongAudioTrack track) {
    return _AudioDraft(
      id: track.id,
      label: TextEditingController(text: track.label),
      url: TextEditingController(text: track.url),
      storagePath: track.storagePath,
      starts: TextEditingController(text: track.verseStartSeconds.join(', ')),
      changes: TextEditingController(text: track.verseChangeSeconds.join(', ')),
      enabled: track.enabled,
    );
  }

  final String id;
  final TextEditingController label;
  final TextEditingController url;
  final String? storagePath;
  final TextEditingController starts;
  final TextEditingController changes;
  bool enabled;

  SongAudioTrack toTrack(int index) {
    return SongAudioTrack(
      id: id,
      label: label.text.trim(),
      url: url.text.trim(),
      storagePath: storagePath,
      verseStartSeconds: _parseSeconds(starts.text),
      verseChangeSeconds: _parseSeconds(changes.text),
      enabled: enabled,
      sortOrder: index,
    );
  }

  void dispose() {
    label.dispose();
    url.dispose();
    starts.dispose();
    changes.dispose();
  }
}

class _AudioEditor extends StatefulWidget {
  const _AudioEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  final int index;
  final _AudioDraft draft;
  final VoidCallback onRemove;

  @override
  State<_AudioEditor> createState() => _AudioEditorState();
}

class _AudioEditorState extends State<_AudioEditor> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Áudio ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Remover áudio',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.draft.label,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.draft.url,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Campo obrigatório'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Caminho local ou URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.draft.starts,
                    decoration: const InputDecoration(
                      labelText: 'Inícios dos versos (segundos)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: widget.draft.changes,
                    decoration: const InputDecoration(
                      labelText: 'Mudanças de verso (segundos)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Áudio ativo'),
              value: widget.draft.enabled,
              onChanged: (value) {
                setState(() => widget.draft.enabled = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

List<int> _parseSeconds(String value) {
  return value
      .split(',')
      .map((part) => int.tryParse(part.trim()))
      .whereType<int>()
      .toList();
}

String _categoryLabel(SongCategory category) {
  return switch (category) {
    SongCategory.holy => 'Cânticos Sagrados',
    SongCategory.fellowship => 'Convívio',
    SongCategory.english => 'Inglês',
    SongCategory.worship => 'Adoração',
    SongCategory.international => 'Internacional',
  };
}
