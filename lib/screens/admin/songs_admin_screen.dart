import 'dart:async';

import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/services/song_repository.dart';
import 'package:flutter/material.dart';

class SongsAdminScreen extends StatefulWidget {
  const SongsAdminScreen({super.key});

  @override
  State<SongsAdminScreen> createState() => _SongsAdminScreenState();
}

class _SongsAdminScreenState extends State<SongsAdminScreen> {
  final _repository = SongRepository();
  final _searchController = TextEditingController();
  bool _isImporting = false;
  String _query = '';

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
      MaterialPageRoute(builder: (context) => SongEditorScreen(song: song)),
    );
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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              decoration: const InputDecoration(
                                labelText: 'Pesquisar música ou página',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
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
                            label: const Text('Importar catálogo'),
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

class SongEditorScreen extends StatefulWidget {
  const SongEditorScreen({super.key, this.song});

  final SongDocument? song;

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = SongRepository();
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
    final song = widget.song;
    _titleController = TextEditingController(text: song?.title ?? '');
    _pageController = TextEditingController(text: song?.page ?? '');
    _languageController = TextEditingController(
      text: song?.languageCode ?? 'pt',
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
