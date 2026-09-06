import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:ffpmupt/models/payment_settings.dart';
import 'package:ffpmupt/models/song.dart';
import 'package:ffpmupt/services/song_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = SongImportService();

  test('imports the bundled XLSX template without audio', () {
    final bytes = File(
      'assets/modelo_importacao_musicas.xlsx',
    ).readAsBytesSync();
    final result = service.parse(
      fileName: 'modelo.xlsx',
      bytes: bytes,
      defaultLanguage: 'pt',
      startingSortOrder: 0,
    );

    expect(result.errors, isEmpty);
    expect(result.songs, hasLength(2));
    expect(result.songs.first.title, 'Unidade');
    expect(result.songs.first.lyrics, hasLength(6));
    expect(result.songs.first.chorusMode, ChorusMode.second);
    expect(result.songs.first.chords, [
      'D   A   Bm   G',
      'G   D   A',
      'G   D   A',
      'G   D   A',
      'Bm   G   D   A',
      'G   D   A',
    ]);
    expect(result.songs.last.chords, isEmpty);
    expect(result.songs.first.audioTracks, isEmpty);
  });

  test(
    'imports repeated PPTX title and chorus as alternating lyric blocks',
    () {
      final result = service.parse(
        fileName: 'Unidade.pptx',
        bytes: _pptxBytes(),
        defaultLanguage: 'pt',
        startingSortOrder: 7,
      );

      expect(result.errors, isEmpty);
      expect(result.songs, hasLength(1));
      expect(result.songs.single.title, 'Unidade');
      expect(result.songs.single.page, '8');
      expect(result.songs.single.lyrics, [
        'Primeira estrofe',
        'Refrão comum em todos os slides',
        'Segunda estrofe',
        'Refrão comum em todos os slides',
        'Terceira estrofe',
        'Refrão comum em todos os slides',
      ]);
      expect(result.songs.single.chorusMode, ChorusMode.second);
    },
  );

  test('payment settings preserve flexible methods and details', () {
    const settings = PaymentSettings(
      enabled: true,
      title: 'Ofertas',
      subtitle: 'Escolha um método',
      note: 'Obrigado',
      methods: [
        PaymentMethod(
          id: 'pix',
          type: PaymentMethodType.pix,
          label: 'PIX',
          description: 'Use a chave abaixo',
          details: [PaymentDetail(label: 'Chave', value: 'igreja@example.com')],
          paymentUrl: '',
          qrContent: 'payload-pix',
          enabled: true,
          sortOrder: 0,
        ),
      ],
    );

    final decoded = PaymentSettings.fromMap(settings.toMap());
    expect(decoded?.methods.single.type, PaymentMethodType.pix);
    expect(decoded?.methods.single.details.single.value, 'igreja@example.com');
  });
}

Uint8List _pptxBytes() {
  final archive = Archive();
  final verses = ['Primeira estrofe', 'Segunda estrofe', 'Terceira estrofe'];
  for (var index = 0; index < verses.length; index++) {
    final xml =
        '''
<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
       xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
  <p:cSld><p:spTree>
    ${_shape('Unidade', 0)}
    ${_shape('${index + 1}.${verses[index]}', 700)}
    ${_shape('Refrão comum em todos os slides', 4000)}
  </p:spTree></p:cSld>
</p:sld>
''';
    final bytes = utf8.encode(xml);
    archive.addFile(
      ArchiveFile('ppt/slides/slide${index + 1}.xml', bytes.length, bytes),
    );
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

String _shape(String text, int y) {
  return '''
<p:sp>
  <p:spPr><a:xfrm><a:off x="0" y="$y"/></a:xfrm></p:spPr>
  <p:txBody><a:p><a:r><a:t>$text</a:t></a:r></a:p></p:txBody>
</p:sp>
''';
}
