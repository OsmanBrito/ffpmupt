import 'package:ffpmupt/settings/app_language.dart';

class HomeCopy {
  const HomeCopy({
    required this.thisWeek,
    required this.seeAll,
    required this.menu,
    required this.serviceModules,
    required this.currentCountry,
  });

  final String thisWeek;
  final String seeAll;
  final String menu;
  final String serviceModules;
  final String currentCountry;

  static HomeCopy of(AppLanguage language) => switch (language) {
    AppLanguage.portuguese || AppLanguage.brazilian => _portuguese,
    AppLanguage.spanish => _spanish,
    AppLanguage.german => _german,
    AppLanguage.italian => _italian,
    AppLanguage.french => _french,
    AppLanguage.korean => _korean,
    AppLanguage.english => _english,
  };
}

const _portuguese = HomeCopy(
  thisWeek: 'Esta semana',
  seeAll: 'Ver todos',
  menu: 'Menu',
  serviceModules: 'Roteiro do serviço',
  currentCountry: 'País atual',
);

const _english = HomeCopy(
  thisWeek: 'This week',
  seeAll: 'See all',
  menu: 'Menu',
  serviceModules: 'Service guide',
  currentCountry: 'Current country',
);

const _spanish = HomeCopy(
  thisWeek: 'Esta semana',
  seeAll: 'Ver todos',
  menu: 'Menú',
  serviceModules: 'Guía del servicio',
  currentCountry: 'País actual',
);

const _german = HomeCopy(
  thisWeek: 'Diese Woche',
  seeAll: 'Alle anzeigen',
  menu: 'Menü',
  serviceModules: 'Ablauf des Gottesdienstes',
  currentCountry: 'Aktuelles Land',
);

const _italian = HomeCopy(
  thisWeek: 'Questa settimana',
  seeAll: 'Vedi tutto',
  menu: 'Menu',
  serviceModules: 'Guida al servizio',
  currentCountry: 'Paese attuale',
);

const _french = HomeCopy(
  thisWeek: 'Cette semaine',
  seeAll: 'Tout voir',
  menu: 'Menu',
  serviceModules: 'Déroulement du service',
  currentCountry: 'Pays actuel',
);

const _korean = HomeCopy(
  thisWeek: '이번 주',
  seeAll: '모두 보기',
  menu: '메뉴',
  serviceModules: '예배 순서',
  currentCountry: '현재 국가',
);
