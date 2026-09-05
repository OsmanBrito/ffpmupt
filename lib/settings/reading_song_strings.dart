import 'package:ffpmupt/settings/app_language.dart';

enum ReadingSongText {
  readingMode,
  presentationMode,
  searchSong,
  favorites,
  recent,
  filters,
  sortBy,
  catalogueOrder,
  alphabeticalOrder,
  pageOrder,
  audio,
  favorite,
  removeFavorite,
  previous,
  next,
  smallerText,
  largerText,
}

class ReadingSongStrings {
  const ReadingSongStrings._(this._values);

  final Map<ReadingSongText, String> _values;

  String operator [](ReadingSongText key) =>
      _values[key] ?? _english[key] ?? key.name;

  static ReadingSongStrings of(AppLanguage language) {
    return ReadingSongStrings._(switch (language) {
      AppLanguage.portuguese || AppLanguage.brazilian => _portuguese,
      AppLanguage.spanish => _spanish,
      AppLanguage.german => _german,
      AppLanguage.italian => _italian,
      AppLanguage.french => _french,
      AppLanguage.korean => _korean,
      AppLanguage.english => _english,
    });
  }
}

const _portuguese = <ReadingSongText, String>{
  ReadingSongText.readingMode: 'Modo de leitura',
  ReadingSongText.presentationMode: 'Modo de apresentação',
  ReadingSongText.searchSong: 'Título, número da página ou letra',
  ReadingSongText.favorites: 'Favoritas',
  ReadingSongText.recent: 'Recentes',
  ReadingSongText.filters: 'Filtrar',
  ReadingSongText.sortBy: 'Ordenar',
  ReadingSongText.catalogueOrder: 'Ordem do catálogo',
  ReadingSongText.alphabeticalOrder: 'Título A–Z',
  ReadingSongText.pageOrder: 'Número da página',
  ReadingSongText.audio: 'Áudio',
  ReadingSongText.favorite: 'Adicionar às favoritas',
  ReadingSongText.removeFavorite: 'Remover das favoritas',
  ReadingSongText.previous: 'Anterior',
  ReadingSongText.next: 'Seguinte',
  ReadingSongText.smallerText: 'Texto menor',
  ReadingSongText.largerText: 'Texto maior',
};

const _english = <ReadingSongText, String>{
  ReadingSongText.readingMode: 'Reading mode',
  ReadingSongText.presentationMode: 'Presentation mode',
  ReadingSongText.searchSong: 'Title, page number, or lyrics',
  ReadingSongText.favorites: 'Favorites',
  ReadingSongText.recent: 'Recent',
  ReadingSongText.filters: 'Filter',
  ReadingSongText.sortBy: 'Sort',
  ReadingSongText.catalogueOrder: 'Catalogue order',
  ReadingSongText.alphabeticalOrder: 'Title A–Z',
  ReadingSongText.pageOrder: 'Page number',
  ReadingSongText.audio: 'Audio',
  ReadingSongText.favorite: 'Add to favorites',
  ReadingSongText.removeFavorite: 'Remove from favorites',
  ReadingSongText.previous: 'Previous',
  ReadingSongText.next: 'Next',
  ReadingSongText.smallerText: 'Smaller text',
  ReadingSongText.largerText: 'Larger text',
};

const _spanish = <ReadingSongText, String>{
  ReadingSongText.readingMode: 'Modo lectura',
  ReadingSongText.presentationMode: 'Modo presentación',
  ReadingSongText.searchSong: 'Título, número de página o letra',
  ReadingSongText.favorites: 'Favoritas',
  ReadingSongText.recent: 'Recientes',
  ReadingSongText.filters: 'Filtrar',
  ReadingSongText.sortBy: 'Ordenar',
  ReadingSongText.catalogueOrder: 'Orden del catálogo',
  ReadingSongText.alphabeticalOrder: 'Título A–Z',
  ReadingSongText.pageOrder: 'Número de página',
  ReadingSongText.audio: 'Audio',
  ReadingSongText.favorite: 'Añadir a favoritas',
  ReadingSongText.removeFavorite: 'Quitar de favoritas',
  ReadingSongText.previous: 'Anterior',
  ReadingSongText.next: 'Siguiente',
  ReadingSongText.smallerText: 'Texto más pequeño',
  ReadingSongText.largerText: 'Texto más grande',
};

const _german = <ReadingSongText, String>{
  ReadingSongText.readingMode: 'Lesemodus',
  ReadingSongText.presentationMode: 'Präsentationsmodus',
  ReadingSongText.searchSong: 'Titel, Seitennummer oder Text',
  ReadingSongText.favorites: 'Favoriten',
  ReadingSongText.recent: 'Zuletzt',
  ReadingSongText.filters: 'Filtern',
  ReadingSongText.sortBy: 'Sortieren',
  ReadingSongText.catalogueOrder: 'Katalogreihenfolge',
  ReadingSongText.alphabeticalOrder: 'Titel A–Z',
  ReadingSongText.pageOrder: 'Seitennummer',
  ReadingSongText.audio: 'Audio',
  ReadingSongText.favorite: 'Zu Favoriten hinzufügen',
  ReadingSongText.removeFavorite: 'Aus Favoriten entfernen',
  ReadingSongText.previous: 'Zurück',
  ReadingSongText.next: 'Weiter',
  ReadingSongText.smallerText: 'Text verkleinern',
  ReadingSongText.largerText: 'Text vergrößern',
};

const _italian = <ReadingSongText, String>{
  ReadingSongText.readingMode: 'Modalità lettura',
  ReadingSongText.presentationMode: 'Modalità presentazione',
  ReadingSongText.searchSong: 'Titolo, numero di pagina o testo',
  ReadingSongText.favorites: 'Preferite',
  ReadingSongText.recent: 'Recenti',
  ReadingSongText.filters: 'Filtra',
  ReadingSongText.sortBy: 'Ordina',
  ReadingSongText.catalogueOrder: 'Ordine del catalogo',
  ReadingSongText.alphabeticalOrder: 'Titolo A–Z',
  ReadingSongText.pageOrder: 'Numero di pagina',
  ReadingSongText.audio: 'Audio',
  ReadingSongText.favorite: 'Aggiungi ai preferiti',
  ReadingSongText.removeFavorite: 'Rimuovi dai preferiti',
  ReadingSongText.previous: 'Precedente',
  ReadingSongText.next: 'Successivo',
  ReadingSongText.smallerText: 'Testo più piccolo',
  ReadingSongText.largerText: 'Testo più grande',
};

const _french = <ReadingSongText, String>{
  ReadingSongText.readingMode: 'Mode lecture',
  ReadingSongText.presentationMode: 'Mode présentation',
  ReadingSongText.searchSong: 'Titre, numéro de page ou paroles',
  ReadingSongText.favorites: 'Favoris',
  ReadingSongText.recent: 'Récents',
  ReadingSongText.filters: 'Filtrer',
  ReadingSongText.sortBy: 'Trier',
  ReadingSongText.catalogueOrder: 'Ordre du catalogue',
  ReadingSongText.alphabeticalOrder: 'Titre A–Z',
  ReadingSongText.pageOrder: 'Numéro de page',
  ReadingSongText.audio: 'Audio',
  ReadingSongText.favorite: 'Ajouter aux favoris',
  ReadingSongText.removeFavorite: 'Retirer des favoris',
  ReadingSongText.previous: 'Précédent',
  ReadingSongText.next: 'Suivant',
  ReadingSongText.smallerText: 'Texte plus petit',
  ReadingSongText.largerText: 'Texte plus grand',
};

const _korean = <ReadingSongText, String>{
  ReadingSongText.readingMode: '읽기 모드',
  ReadingSongText.presentationMode: '발표 모드',
  ReadingSongText.searchSong: '제목, 페이지 번호 또는 가사',
  ReadingSongText.favorites: '즐겨찾기',
  ReadingSongText.recent: '최근',
  ReadingSongText.filters: '필터',
  ReadingSongText.sortBy: '정렬',
  ReadingSongText.catalogueOrder: '목록 순서',
  ReadingSongText.alphabeticalOrder: '제목순',
  ReadingSongText.pageOrder: '페이지순',
  ReadingSongText.audio: '오디오',
  ReadingSongText.favorite: '즐겨찾기에 추가',
  ReadingSongText.removeFavorite: '즐겨찾기에서 제거',
  ReadingSongText.previous: '이전',
  ReadingSongText.next: '다음',
  ReadingSongText.smallerText: '글자 작게',
  ReadingSongText.largerText: '글자 크게',
};
