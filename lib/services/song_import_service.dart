import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:ffpmupt/models/song.dart';
import 'package:xml/xml.dart';

class SongImportResult {
  const SongImportResult({
    required this.songs,
    required this.warnings,
    required this.errors,
  });

  final List<SongDocument> songs;
  final List<String> warnings;
  final List<String> errors;
}

class SongImportService {
  const SongImportService();

  SongImportResult parse({
    required String fileName,
    required Uint8List bytes,
    required String defaultLanguage,
    required int startingSortOrder,
  }) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'xlsx' => _parseXlsx(
        fileName: fileName,
        bytes: bytes,
        defaultLanguage: defaultLanguage,
        startingSortOrder: startingSortOrder,
      ),
      'pptx' => _parsePptx(
        fileName: fileName,
        bytes: bytes,
        defaultLanguage: defaultLanguage,
        sortOrder: startingSortOrder,
      ),
      _ => SongImportResult(
        songs: const [],
        warnings: const [],
        errors: ['Formato não suportado em $fileName. Use XLSX ou PPTX.'],
      ),
    };
  }

  SongImportResult _parseXlsx({
    required String fileName,
    required Uint8List bytes,
    required String defaultLanguage,
    required int startingSortOrder,
  }) {
    final warnings = <String>[];
    final errors = <String>[];
    final songs = <SongDocument>[];

    try {
      final rows = _readFirstWorksheet(bytes);
      if (rows.isEmpty) {
        return SongImportResult(
          songs: const [],
          warnings: const [],
          errors: ['A planilha $fileName está vazia.'],
        );
      }

      final headers = <String, int>{};
      for (var index = 0; index < rows.first.length; index++) {
        final header = _normalizeHeader(rows.first[index]);
        if (header.isNotEmpty) {
          headers[header] = index;
        }
      }
      if (!headers.containsKey('titulo')) {
        return SongImportResult(
          songs: const [],
          warnings: const [],
          errors: ['A planilha precisa da coluna "titulo".'],
        );
      }

      for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        final title = _valueFor(row, headers, 'titulo');
        if (title.isEmpty) {
          if (row.any((cell) => cell.isNotEmpty)) {
            warnings.add('Linha ${rowIndex + 1} ignorada: título vazio.');
          }
          continue;
        }

        final chorus = _valueFor(row, headers, 'refrao');
        final chorusChords = _valueFor(row, headers, 'cifra_refrao').isNotEmpty
            ? _valueFor(row, headers, 'cifra_refrao')
            : _valueFor(row, headers, 'acordes_refrao');
        final verses = <String>[];
        final verseChords = <String>[];
        for (var index = 1; index <= 20; index++) {
          final verse = _valueFor(row, headers, 'estrofe_$index').isNotEmpty
              ? _valueFor(row, headers, 'estrofe_$index')
              : _valueFor(row, headers, 'verso_$index');
          if (verse.isNotEmpty) {
            verses.add(verse);
            final chords = _valueFor(row, headers, 'cifra_$index');
            verseChords.add(
              chords.isNotEmpty
                  ? chords
                  : _valueFor(row, headers, 'acordes_$index'),
            );
          }
        }
        if (verses.isEmpty) {
          final lyrics = _valueFor(row, headers, 'letra');
          verses.addAll(
            lyrics
                .split(RegExp(r'\s*\|\|\|\s*'))
                .map((part) => part.trim())
                .where((part) => part.isNotEmpty),
          );
          final chordSheet = _valueFor(row, headers, 'cifras').isNotEmpty
              ? _valueFor(row, headers, 'cifras')
              : _valueFor(row, headers, 'acordes');
          final chordParts = chordSheet
              .split(RegExp(r'\s*\|\|\|\s*'))
              .map((part) => part.trim())
              .toList();
          for (var index = 0; index < verses.length; index++) {
            verseChords.add(index < chordParts.length ? chordParts[index] : '');
          }
        }
        if (verses.isEmpty && chorus.isEmpty) {
          errors.add('Linha ${rowIndex + 1} ($title): letra vazia.');
          continue;
        }

        final lyrics = <String>[];
        final chords = <String>[];
        if (verses.isEmpty) {
          lyrics.add(chorus);
          chords.add(chorusChords);
        } else {
          for (var index = 0; index < verses.length; index++) {
            lyrics.add(verses[index]);
            chords.add(index < verseChords.length ? verseChords[index] : '');
            if (chorus.isNotEmpty) {
              lyrics.add(chorus);
              chords.add(chorusChords);
            }
          }
        }
        while (chords.isNotEmpty && chords.last.isEmpty) {
          chords.removeLast();
        }
        final categoryValue = _valueFor(row, headers, 'categoria');
        final category = SongCategory.fromValue(categoryValue.toLowerCase());
        if (categoryValue.isNotEmpty && category == null) {
          warnings.add(
            'Linha ${rowIndex + 1} ($title): categoria "$categoryValue" trocada por holy.',
          );
        }
        final sortOrder = int.tryParse(_valueFor(row, headers, 'ordem'));

        songs.add(
          SongDocument(
            id: '',
            title: title,
            page: _valueFor(row, headers, 'pagina').isEmpty
                ? '${startingSortOrder + songs.length + 1}'
                : _valueFor(row, headers, 'pagina'),
            category: category ?? SongCategory.holy,
            languageCode:
                _valueFor(row, headers, 'idioma').toLowerCase().isEmpty
                ? defaultLanguage
                : _valueFor(row, headers, 'idioma').toLowerCase(),
            lyrics: lyrics,
            chords: chords,
            chorusMode: chorus.isEmpty ? ChorusMode.none : ChorusMode.second,
            enabled: _parseEnabled(_valueFor(row, headers, 'ativa')),
            sortOrder: sortOrder ?? startingSortOrder + songs.length,
            audioTracks: const [],
            videoLinks: const [],
          ),
        );
      }
    } on Object catch (error) {
      errors.add('Não foi possível ler $fileName: $error');
    }

    return SongImportResult(songs: songs, warnings: warnings, errors: errors);
  }

  SongImportResult _parsePptx({
    required String fileName,
    required Uint8List bytes,
    required String defaultLanguage,
    required int sortOrder,
  }) {
    final warnings = <String>[];
    final errors = <String>[];
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: true);
      final slideFiles =
          archive.files
              .where(
                (file) =>
                    file.isFile &&
                    RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(file.name),
              )
              .toList()
            ..sort((left, right) {
              return _slideNumber(
                left.name,
              ).compareTo(_slideNumber(right.name));
            });
      if (slideFiles.isEmpty) {
        return SongImportResult(
          songs: const [],
          warnings: const [],
          errors: ['$fileName não contém slides reconhecíveis.'],
        );
      }

      final slides = slideFiles.map(_parseSlideBlocks).toList();
      final frequency = <String, int>{};
      final sampleByText = <String, _SlideTextBlock>{};
      for (final slide in slides) {
        for (final block in slide) {
          final normalized = _normalizeText(block.text);
          if (normalized.isEmpty) {
            continue;
          }
          frequency[normalized] = (frequency[normalized] ?? 0) + 1;
          sampleByText.putIfAbsent(normalized, () => block);
        }
      }

      final repeated =
          frequency.entries
              .where((entry) => entry.value == slides.length)
              .map((entry) => sampleByText[entry.key]!)
              .toList()
            ..sort((left, right) => left.y.compareTo(right.y));
      final fallbackTitle = fileName.replaceFirst(
        RegExp(r'\.pptx$', caseSensitive: false),
        '',
      );
      final titleBlock = repeated.isEmpty ? null : repeated.first;
      final title = titleBlock?.text.trim().isNotEmpty == true
          ? titleBlock!.text.trim()
          : fallbackTitle;
      final chorusCandidates =
          repeated
              .where((block) => block != titleBlock && block.text.length > 15)
              .toList()
            ..sort((left, right) => right.y.compareTo(left.y));
      final chorusBlock = chorusCandidates.isEmpty
          ? null
          : chorusCandidates.first;
      final chorus = chorusBlock?.text.trim() ?? '';
      final lyrics = <String>[];

      for (var slideIndex = 0; slideIndex < slides.length; slideIndex++) {
        final content = slides[slideIndex]
            .where(
              (block) =>
                  _normalizeText(block.text) !=
                      _normalizeText(titleBlock?.text ?? '') &&
                  _normalizeText(block.text) !=
                      _normalizeText(chorusBlock?.text ?? '') &&
                  !RegExp(r'^\d+$').hasMatch(block.text.trim()),
            )
            .map((block) => block.text.trim())
            .where((text) => text.isNotEmpty)
            .join('\n')
            .replaceFirst(RegExp(r'^\s*\d+\s*[.)-]\s*'), '')
            .trim();
        if (content.isEmpty) {
          warnings.add('Slide ${slideIndex + 1} ignorado: letra vazia.');
          continue;
        }
        lyrics.add(content);
        if (chorus.isNotEmpty) {
          lyrics.add(chorus);
        }
      }

      if (lyrics.isEmpty) {
        return SongImportResult(
          songs: const [],
          warnings: warnings,
          errors: ['Não foi possível identificar a letra em $fileName.'],
        );
      }
      if (chorus.isEmpty) {
        warnings.add(
          '$fileName: nenhum refrão repetido foi identificado; cada slide virou uma estrofe.',
        );
      }

      return SongImportResult(
        songs: [
          SongDocument(
            id: '',
            title: title,
            page: '${sortOrder + 1}',
            category: SongCategory.holy,
            languageCode: defaultLanguage,
            lyrics: lyrics,
            chorusMode: chorus.isEmpty ? ChorusMode.none : ChorusMode.second,
            enabled: true,
            sortOrder: sortOrder,
            audioTracks: const [],
            videoLinks: const [],
          ),
        ],
        warnings: warnings,
        errors: errors,
      );
    } on Object catch (error) {
      return SongImportResult(
        songs: const [],
        warnings: warnings,
        errors: ['Não foi possível ler $fileName: $error'],
      );
    }
  }

  List<_SlideTextBlock> _parseSlideBlocks(ArchiveFile file) {
    final bytes = _archiveFileBytes(file);
    final document = XmlDocument.parse(utf8.decode(bytes));
    final blocks = <_SlideTextBlock>[];
    for (final shape in document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'sp',
    )) {
      final paragraphs = shape.descendants
          .whereType<XmlElement>()
          .where((element) => element.name.local == 'p')
          .map(
            (paragraph) => paragraph.descendants
                .whereType<XmlElement>()
                .where((element) => element.name.local == 't')
                .map((element) => element.innerText)
                .join(),
          )
          .where((text) => text.trim().isNotEmpty)
          .toList();
      if (paragraphs.isEmpty) {
        continue;
      }
      final offset = shape.descendants.whereType<XmlElement>().where(
        (element) => element.name.local == 'off',
      );
      final y = offset.isEmpty
          ? 0
          : int.tryParse(offset.first.getAttribute('y') ?? '') ?? 0;
      blocks.add(_SlideTextBlock(text: paragraphs.join('\n'), y: y));
    }
    blocks.sort((left, right) => left.y.compareTo(right.y));
    return blocks;
  }

  List<List<String>> _readFirstWorksheet(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final worksheet = archive.files.firstWhere(
      (file) =>
          file.isFile &&
          RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(file.name),
    );
    final sharedStringsFile = archive.files.where(
      (file) => file.name == 'xl/sharedStrings.xml',
    );
    final sharedStrings = sharedStringsFile.isEmpty
        ? const <String>[]
        : XmlDocument.parse(
                utf8.decode(_archiveFileBytes(sharedStringsFile.first)),
              ).descendants
              .whereType<XmlElement>()
              .where((element) => element.name.local == 'si')
              .map(
                (item) => item.descendants
                    .whereType<XmlElement>()
                    .where((element) => element.name.local == 't')
                    .map((element) => element.innerText)
                    .join(),
              )
              .toList();
    final document = XmlDocument.parse(
      utf8.decode(_archiveFileBytes(worksheet)),
    );
    final rows = <List<String>>[];
    for (final rowElement in document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'row',
    )) {
      final cells = <int, String>{};
      var maxColumn = -1;
      for (final cell in rowElement.children.whereType<XmlElement>().where(
        (element) => element.name.local == 'c',
      )) {
        final reference = cell.getAttribute('r') ?? '';
        final column = _columnIndex(reference);
        if (column < 0) {
          continue;
        }
        maxColumn = column > maxColumn ? column : maxColumn;
        final type = cell.getAttribute('t');
        final textElements = cell.descendants.whereType<XmlElement>().where(
          (element) => element.name.local == 't',
        );
        final valueElements = cell.children.whereType<XmlElement>().where(
          (element) => element.name.local == 'v',
        );
        final raw = textElements.isNotEmpty
            ? textElements.map((element) => element.innerText).join()
            : valueElements.isEmpty
            ? ''
            : valueElements.first.innerText;
        if (type == 's') {
          final index = int.tryParse(raw);
          cells[column] = index != null && index < sharedStrings.length
              ? sharedStrings[index]
              : '';
        } else {
          cells[column] = raw;
        }
      }
      rows.add([
        for (var column = 0; column <= maxColumn; column++)
          cells[column]?.trim() ?? '',
      ]);
    }
    return rows;
  }
}

class _SlideTextBlock {
  const _SlideTextBlock({required this.text, required this.y});

  final String text;
  final int y;
}

String _valueFor(List<String> row, Map<String, int> headers, String key) {
  final index = headers[key];
  if (index == null || index >= row.length) {
    return '';
  }
  return row[index].trim();
}

Uint8List _archiveFileBytes(ArchiveFile file) {
  final content = file.content;
  return content is Uint8List
      ? content
      : Uint8List.fromList(List<int>.from(content as List));
}

int _columnIndex(String cellReference) {
  final letters = RegExp(
    r'^[A-Z]+',
    caseSensitive: false,
  ).firstMatch(cellReference)?.group(0)?.toUpperCase();
  if (letters == null) {
    return -1;
  }
  var value = 0;
  for (final codeUnit in letters.codeUnits) {
    value = value * 26 + (codeUnit - 64);
  }
  return value - 1;
}

String _normalizeHeader(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _normalizeText(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}

int _slideNumber(String path) {
  return int.tryParse(
        RegExp(r'slide(\d+)\.xml$').firstMatch(path)?.group(1) ?? '',
      ) ??
      0;
}

bool _parseEnabled(String value) {
  if (value.trim().isEmpty) {
    return true;
  }
  return !{'false', '0', 'nao', 'não', 'no'}.contains(value.toLowerCase());
}
