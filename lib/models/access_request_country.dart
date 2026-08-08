/// Countries that can be selected when a European leader requests access.
///
/// These are request options only. A country still needs to be created and
/// enabled in Firestore before its public app area becomes available.
class AccessRequestCountry {
  const AccessRequestCountry({required this.code, required this.name});

  final String code;
  final String name;
}

const europeanAccessRequestCountries = <AccessRequestCountry>[
  AccessRequestCountry(code: 'al', name: 'Albania'),
  AccessRequestCountry(code: 'ad', name: 'Andorra'),
  AccessRequestCountry(code: 'am', name: 'Armenia'),
  AccessRequestCountry(code: 'at', name: 'Austria'),
  AccessRequestCountry(code: 'az', name: 'Azerbaijan'),
  AccessRequestCountry(code: 'by', name: 'Belarus'),
  AccessRequestCountry(code: 'be', name: 'Belgium'),
  AccessRequestCountry(code: 'ba', name: 'Bosnia and Herzegovina'),
  AccessRequestCountry(code: 'bg', name: 'Bulgaria'),
  AccessRequestCountry(code: 'hr', name: 'Croatia'),
  AccessRequestCountry(code: 'cy', name: 'Cyprus'),
  AccessRequestCountry(code: 'cz', name: 'Czechia'),
  AccessRequestCountry(code: 'dk', name: 'Denmark'),
  AccessRequestCountry(code: 'ee', name: 'Estonia'),
  AccessRequestCountry(code: 'fi', name: 'Finland'),
  AccessRequestCountry(code: 'fr', name: 'France'),
  AccessRequestCountry(code: 'ge', name: 'Georgia'),
  AccessRequestCountry(code: 'de', name: 'Germany'),
  AccessRequestCountry(code: 'gr', name: 'Greece'),
  AccessRequestCountry(code: 'hu', name: 'Hungary'),
  AccessRequestCountry(code: 'is', name: 'Iceland'),
  AccessRequestCountry(code: 'ie', name: 'Ireland'),
  AccessRequestCountry(code: 'it', name: 'Italy'),
  AccessRequestCountry(code: 'xk', name: 'Kosovo'),
  AccessRequestCountry(code: 'lv', name: 'Latvia'),
  AccessRequestCountry(code: 'li', name: 'Liechtenstein'),
  AccessRequestCountry(code: 'lt', name: 'Lithuania'),
  AccessRequestCountry(code: 'lu', name: 'Luxembourg'),
  AccessRequestCountry(code: 'mt', name: 'Malta'),
  AccessRequestCountry(code: 'md', name: 'Moldova'),
  AccessRequestCountry(code: 'mc', name: 'Monaco'),
  AccessRequestCountry(code: 'me', name: 'Montenegro'),
  AccessRequestCountry(code: 'nl', name: 'Netherlands'),
  AccessRequestCountry(code: 'mk', name: 'North Macedonia'),
  AccessRequestCountry(code: 'no', name: 'Norway'),
  AccessRequestCountry(code: 'pl', name: 'Poland'),
  AccessRequestCountry(code: 'pt', name: 'Portugal'),
  AccessRequestCountry(code: 'ro', name: 'Romania'),
  AccessRequestCountry(code: 'ru', name: 'Russia'),
  AccessRequestCountry(code: 'sm', name: 'San Marino'),
  AccessRequestCountry(code: 'rs', name: 'Serbia'),
  AccessRequestCountry(code: 'sk', name: 'Slovakia'),
  AccessRequestCountry(code: 'si', name: 'Slovenia'),
  AccessRequestCountry(code: 'es', name: 'Spain'),
  AccessRequestCountry(code: 'se', name: 'Sweden'),
  AccessRequestCountry(code: 'ch', name: 'Switzerland'),
  AccessRequestCountry(code: 'tr', name: 'Türkiye'),
  AccessRequestCountry(code: 'ua', name: 'Ukraine'),
  AccessRequestCountry(code: 'gb', name: 'United Kingdom'),
  AccessRequestCountry(code: 'va', name: 'Vatican City'),
];
