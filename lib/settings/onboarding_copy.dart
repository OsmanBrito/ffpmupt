import 'package:ffpmupt/settings/app_language.dart';

/// Copy used before a country has been selected and during the access request
/// flow. Keeping this copy together prevents the entry experience from
/// silently switching between Portuguese and English.
class OnboardingCopy {
  const OnboardingCopy._(this._values);

  final Map<String, String> _values;

  String _text(String key) => _values[key] ?? _english[key] ?? key;

  String get selectCountryTitle => _text('selectCountryTitle');
  String get selectCountrySubtitle => _text('selectCountrySubtitle');
  String get selectCountryDescription => _text('selectCountryDescription');
  String get publicAccess => _text('publicAccess');
  String get adminAccess => _text('adminAccess');
  String get language => _text('language');
  String get searchCountries => _text('searchCountries');
  String get noCountries => _text('noCountries');
  String get noCountriesMatch => _text('noCountriesMatch');
  String get defaultLanguage => _text('defaultLanguage');
  String get requestAdministratorAccess => _text('requestAdministratorAccess');

  String get accessRequestTitle => _text('accessRequestTitle');
  String get accessRequestIntro => _text('accessRequestIntro');
  String requestEmail(String email) => '${_text('requestEmailPrefix')} $email';
  String get country => _text('country');
  String get fullName => _text('fullName');
  String get invitationEmail => _text('invitationEmail');
  String get role => _text('role');
  String get countryLeader => _text('countryLeader');
  String get countryLeaderHelp => _text('countryLeaderHelp');
  String get countryAdministrator => _text('countryAdministrator');
  String get countryAdministratorHelp => _text('countryAdministratorHelp');
  String get optionalMessage => _text('optionalMessage');
  String get chooseCountry => _text('chooseCountry');
  String get enterFullName => _text('enterFullName');
  String get validEmail => _text('validEmail');
  String get openEmailToSendRequest => _text('openEmailToSendRequest');
  String get emailDraftPrepared => _text('emailDraftPrepared');
  String get emailDraftInstruction => _text('emailDraftInstruction');
  String get manualCopyInstruction => _text('manualCopyInstruction');
  String get copyRequestText => _text('copyRequestText');
  String get requestCopied => _text('requestCopied');
  String get returnToApp => _text('returnToApp');
  String emailOpenError(String email) => '${_text('emailOpenError')} $email.';
  String get requestNextStep => _text('requestNextStep');

  static OnboardingCopy of(AppLanguage language) {
    return OnboardingCopy._(_copies[language] ?? _english);
  }
}

const _english = <String, String>{
  'selectCountryTitle': 'Choose your country',
  'selectCountrySubtitle': 'Select the community area you want to view.',
  'selectCountryDescription':
      'Public content is available without an account. Administrator access is requested separately.',
  'publicAccess': 'Public area',
  'adminAccess': 'Administrator access',
  'language': 'Language',
  'searchCountries': 'Search countries',
  'noCountries': 'No countries are available right now.',
  'noCountriesMatch': 'No countries match your search.',
  'defaultLanguage': 'Default language',
  'requestAdministratorAccess': 'Request administrator access',
  'accessRequestTitle': 'Request administrator access',
  'accessRequestIntro':
      'Enter your details. We will review your request and send an invitation by email.',
  'requestEmailPrefix': 'Request email:',
  'country': 'Country',
  'fullName': 'Full name',
  'invitationEmail': 'Email for the invitation',
  'role': 'Role',
  'countryLeader': 'Country leader',
  'countryLeaderHelp': 'Coordinates the country team and content priorities.',
  'countryAdministrator': 'Country administrator',
  'countryAdministratorHelp':
      'Maintains the country content and day-to-day updates.',
  'optionalMessage': 'Message (optional)',
  'chooseCountry': 'Choose a country.',
  'enterFullName': 'Enter your full name.',
  'validEmail': 'Enter a valid email address.',
  'openEmailToSendRequest': 'Open email to send request',
  'emailDraftPrepared': 'Email draft prepared',
  'emailDraftInstruction':
      'Your email application should now be open with the request ready to send. Please press Send. After reviewing it, we will send an invitation to the email you provided.',
  'manualCopyInstruction':
      'Copy the prepared request below and send it manually if you use webmail or do not have an email app configured:',
  'copyRequestText': 'Copy request text',
  'requestCopied': 'Request copied',
  'returnToApp': 'Return to the app',
  'emailOpenError':
      'We could not open your email application. Please send your request to',
  'requestNextStep':
      'This request does not grant access automatically. The coordinator will review it and send a separate invitation.',
};

const _portuguese = <String, String>{
  'selectCountryTitle': 'Escolha o seu país',
  'selectCountrySubtitle': 'Selecione a comunidade que deseja consultar.',
  'selectCountryDescription':
      'O conteúdo público está disponível sem conta. O acesso administrativo é solicitado separadamente.',
  'publicAccess': 'Área pública',
  'adminAccess': 'Acesso administrativo',
  'language': 'Idioma',
  'searchCountries': 'Pesquisar países',
  'noCountries': 'Não há países disponíveis neste momento.',
  'noCountriesMatch': 'Nenhum país corresponde à pesquisa.',
  'defaultLanguage': 'Idioma padrão',
  'requestAdministratorAccess': 'Pedir acesso administrativo',
  'accessRequestTitle': 'Pedir acesso administrativo',
  'accessRequestIntro':
      'Indique os seus dados. Vamos analisar o pedido e enviar um convite por email.',
  'requestEmailPrefix': 'Email do pedido:',
  'country': 'País',
  'fullName': 'Nome completo',
  'invitationEmail': 'Email para receber o convite',
  'role': 'Função',
  'countryLeader': 'Líder do país',
  'countryLeaderHelp':
      'Coordena a equipa do país e as prioridades de conteúdo.',
  'countryAdministrator': 'Administrador do país',
  'countryAdministratorHelp':
      'Mantém o conteúdo do país e as atualizações do dia a dia.',
  'optionalMessage': 'Mensagem (opcional)',
  'chooseCountry': 'Escolha um país.',
  'enterFullName': 'Indique o seu nome completo.',
  'validEmail': 'Indique um email válido.',
  'openEmailToSendRequest': 'Abrir email para enviar o pedido',
  'emailDraftPrepared': 'Rascunho de email preparado',
  'emailDraftInstruction':
      'A aplicação de email deve ter aberto com o pedido preparado. Prima Enviar. Depois de analisarmos o pedido, enviaremos um convite para o email indicado.',
  'manualCopyInstruction':
      'Copie o pedido preparado abaixo e envie-o manualmente se utiliza webmail ou não tem uma aplicação de email configurada:',
  'copyRequestText': 'Copiar texto do pedido',
  'requestCopied': 'Pedido copiado',
  'returnToApp': 'Voltar à aplicação',
  'emailOpenError':
      'Não foi possível abrir a aplicação de email. Envie o pedido para',
  'requestNextStep':
      'Este pedido não dá acesso automaticamente. O coordenador irá analisá-lo e enviar um convite separado.',
};

const _spanish = <String, String>{
  'selectCountryTitle': 'Elige tu país',
  'selectCountrySubtitle': 'Selecciona la comunidad que quieres consultar.',
  'selectCountryDescription':
      'El contenido público está disponible sin cuenta. El acceso de administrador se solicita por separado.',
  'publicAccess': 'Área pública',
  'adminAccess': 'Acceso de administrador',
  'language': 'Idioma',
  'searchCountries': 'Buscar países',
  'noCountries': 'No hay países disponibles ahora.',
  'noCountriesMatch': 'Ningún país coincide con la búsqueda.',
  'defaultLanguage': 'Idioma predeterminado',
  'requestAdministratorAccess': 'Solicitar acceso de administrador',
  'accessRequestTitle': 'Solicitar acceso de administrador',
  'accessRequestIntro':
      'Indica tus datos. Revisaremos la solicitud y enviaremos una invitación por email.',
  'requestEmailPrefix': 'Email de la solicitud:',
  'country': 'País',
  'fullName': 'Nombre completo',
  'invitationEmail': 'Email para la invitación',
  'role': 'Función',
  'countryLeader': 'Líder del país',
  'countryLeaderHelp':
      'Coordina el equipo del país y las prioridades de contenido.',
  'countryAdministrator': 'Administrador del país',
  'countryAdministratorHelp':
      'Mantiene el contenido del país y las actualizaciones diarias.',
  'optionalMessage': 'Mensaje (opcional)',
  'chooseCountry': 'Elige un país.',
  'enterFullName': 'Indica tu nombre completo.',
  'validEmail': 'Indica un email válido.',
  'openEmailToSendRequest': 'Abrir email para enviar la solicitud',
  'emailDraftPrepared': 'Borrador de email preparado',
  'emailDraftInstruction':
      'Tu aplicación de email debería haberse abierto con la solicitud preparada. Pulsa Enviar. Después de revisarla, enviaremos una invitación al email indicado.',
  'emailOpenError':
      'No se pudo abrir la aplicación de email. Envía la solicitud a',
  'manualCopyInstruction':
      'Copia la solicitud preparada y envíala manualmente si usas webmail o no tienes una aplicación de email configurada:',
  'copyRequestText': 'Copiar texto de la solicitud',
  'requestCopied': 'Solicitud copiada',
  'returnToApp': 'Volver a la aplicación',
  'requestNextStep':
      'Esta solicitud no concede acceso automáticamente. El coordinador la revisará y enviará una invitación separada.',
};

const _german = <String, String>{
  'selectCountryTitle': 'Land auswählen',
  'selectCountrySubtitle': 'Wählen Sie den gewünschten Gemeinschaftsbereich.',
  'selectCountryDescription':
      'Öffentliche Inhalte sind ohne Konto verfügbar. Der Administratorzugang wird separat beantragt.',
  'publicAccess': 'Öffentlicher Bereich',
  'adminAccess': 'Administratorzugang',
  'language': 'Sprache',
  'searchCountries': 'Länder suchen',
  'noCountries': 'Derzeit sind keine Länder verfügbar.',
  'noCountriesMatch': 'Keine Länder entsprechen der Suche.',
  'defaultLanguage': 'Standardsprache',
  'requestAdministratorAccess': 'Administratorzugang anfordern',
  'accessRequestTitle': 'Administratorzugang anfordern',
  'accessRequestIntro':
      'Geben Sie Ihre Daten ein. Wir prüfen die Anfrage und senden eine Einladung per E-Mail.',
  'requestEmailPrefix': 'Anfrage-E-Mail:',
  'country': 'Land',
  'fullName': 'Vollständiger Name',
  'invitationEmail': 'E-Mail für die Einladung',
  'role': 'Rolle',
  'countryLeader': 'Länderleiter',
  'countryLeaderHelp': 'Koordiniert das Landesteam und die Inhaltsprioritäten.',
  'countryAdministrator': 'Länderadministrator',
  'countryAdministratorHelp':
      'Pflegt die Länderinhalte und täglichen Aktualisierungen.',
  'optionalMessage': 'Nachricht (optional)',
  'chooseCountry': 'Wählen Sie ein Land.',
  'enterFullName': 'Geben Sie Ihren vollständigen Namen ein.',
  'validEmail': 'Geben Sie eine gültige E-Mail-Adresse ein.',
  'openEmailToSendRequest': 'E-Mail zum Senden öffnen',
  'emailDraftPrepared': 'E-Mail-Entwurf vorbereitet',
  'emailDraftInstruction':
      'Ihre E-Mail-Anwendung sollte mit der vorbereiteten Anfrage geöffnet sein. Drücken Sie Senden. Nach der Prüfung senden wir eine Einladung an die angegebene E-Mail-Adresse.',
  'emailOpenError':
      'Die E-Mail-Anwendung konnte nicht geöffnet werden. Senden Sie die Anfrage an',
  'manualCopyInstruction':
      'Kopieren Sie die vorbereitete Anfrage und senden Sie sie manuell, wenn Sie Webmail verwenden:',
  'copyRequestText': 'Anfragetext kopieren',
  'requestCopied': 'Anfrage kopiert',
  'returnToApp': 'Zur Anwendung zurück',
  'requestNextStep':
      'Diese Anfrage gewährt keinen automatischen Zugriff. Der Koordinator prüft sie und sendet eine separate Einladung.',
};

const _italian = <String, String>{
  'selectCountryTitle': 'Scegli il tuo paese',
  'selectCountrySubtitle': 'Seleziona la comunità che vuoi consultare.',
  'selectCountryDescription':
      'I contenuti pubblici sono disponibili senza account. L’accesso amministrativo si richiede separatamente.',
  'publicAccess': 'Area pubblica',
  'adminAccess': 'Accesso amministratore',
  'language': 'Lingua',
  'searchCountries': 'Cerca paesi',
  'noCountries': 'Nessun paese disponibile al momento.',
  'noCountriesMatch': 'Nessun paese corrisponde alla ricerca.',
  'defaultLanguage': 'Lingua predefinita',
  'requestAdministratorAccess': 'Richiedi accesso amministratore',
  'accessRequestTitle': 'Richiedi accesso amministratore',
  'accessRequestIntro':
      'Inserisci i tuoi dati. Esamineremo la richiesta e invieremo un invito via email.',
  'requestEmailPrefix': 'Email della richiesta:',
  'country': 'Paese',
  'fullName': 'Nome completo',
  'invitationEmail': 'Email per l’invito',
  'role': 'Ruolo',
  'countryLeader': 'Responsabile del paese',
  'countryLeaderHelp':
      'Coordina il team del paese e le priorità dei contenuti.',
  'countryAdministrator': 'Amministratore del paese',
  'countryAdministratorHelp':
      'Mantiene i contenuti del paese e gli aggiornamenti quotidiani.',
  'optionalMessage': 'Messaggio (opzionale)',
  'chooseCountry': 'Scegli un paese.',
  'enterFullName': 'Inserisci il tuo nome completo.',
  'validEmail': 'Inserisci un indirizzo email valido.',
  'openEmailToSendRequest': 'Apri email per inviare la richiesta',
  'emailDraftPrepared': 'Bozza email preparata',
  'emailDraftInstruction':
      'La tua applicazione email dovrebbe essere aperta con la richiesta pronta. Premi Invia. Dopo la verifica invieremo un invito all’email indicata.',
  'emailOpenError':
      'Non è stato possibile aprire l’app email. Invia la richiesta a',
  'manualCopyInstruction':
      'Copia la richiesta e inviala manualmente se usi webmail o non hai un’app email configurata:',
  'copyRequestText': 'Copia testo richiesta',
  'requestCopied': 'Richiesta copiata',
  'returnToApp': 'Torna all’applicazione',
  'requestNextStep':
      'Questa richiesta non concede automaticamente l’accesso. Il coordinatore la esaminerà e invierà un invito separato.',
};

const _french = <String, String>{
  'selectCountryTitle': 'Choisissez votre pays',
  'selectCountrySubtitle': 'Sélectionnez la communauté à consulter.',
  'selectCountryDescription':
      'Le contenu public est disponible sans compte. L’accès administrateur se demande séparément.',
  'publicAccess': 'Espace public',
  'adminAccess': 'Accès administrateur',
  'language': 'Langue',
  'searchCountries': 'Rechercher un pays',
  'noCountries': 'Aucun pays disponible pour le moment.',
  'noCountriesMatch': 'Aucun pays ne correspond à la recherche.',
  'defaultLanguage': 'Langue par défaut',
  'requestAdministratorAccess': 'Demander un accès administrateur',
  'accessRequestTitle': 'Demander un accès administrateur',
  'accessRequestIntro':
      'Indiquez vos informations. Nous examinerons la demande et enverrons une invitation par email.',
  'requestEmailPrefix': 'Email de la demande :',
  'country': 'Pays',
  'fullName': 'Nom complet',
  'invitationEmail': 'Email pour l’invitation',
  'role': 'Rôle',
  'countryLeader': 'Responsable du pays',
  'countryLeaderHelp':
      'Coordonne l’équipe du pays et les priorités de contenu.',
  'countryAdministrator': 'Administrateur du pays',
  'countryAdministratorHelp':
      'Gère le contenu du pays et les mises à jour quotidiennes.',
  'optionalMessage': 'Message (facultatif)',
  'chooseCountry': 'Choisissez un pays.',
  'enterFullName': 'Indiquez votre nom complet.',
  'validEmail': 'Indiquez une adresse email valide.',
  'openEmailToSendRequest': 'Ouvrir l’email pour envoyer la demande',
  'emailDraftPrepared': 'Brouillon d’email préparé',
  'emailDraftInstruction':
      'Votre application email devrait être ouverte avec la demande prête à envoyer. Appuyez sur Envoyer. Après vérification, nous enverrons une invitation à l’adresse indiquée.',
  'emailOpenError':
      'Impossible d’ouvrir l’application email. Envoyez la demande à',
  'manualCopyInstruction':
      'Copiez la demande préparée et envoyez-la manuellement si vous utilisez le webmail:',
  'copyRequestText': 'Copier le texte de la demande',
  'requestCopied': 'Demande copiée',
  'returnToApp': 'Retour à l’application',
  'requestNextStep':
      'Cette demande ne donne pas automatiquement accès. Le coordinateur l’examinera et enverra une invitation séparée.',
};

const _korean = <String, String>{
  'selectCountryTitle': '국가를 선택하세요',
  'selectCountrySubtitle': '확인할 커뮤니티를 선택하세요.',
  'selectCountryDescription': '공개 콘텐츠는 계정 없이 이용할 수 있습니다. 관리자 권한은 별도로 요청합니다.',
  'publicAccess': '공개 영역',
  'adminAccess': '관리자 권한',
  'language': '언어',
  'searchCountries': '국가 검색',
  'noCountries': '현재 이용 가능한 국가가 없습니다.',
  'noCountriesMatch': '검색 결과가 없습니다.',
  'defaultLanguage': '기본 언어',
  'requestAdministratorAccess': '관리자 권한 요청',
  'accessRequestTitle': '관리자 권한 요청',
  'accessRequestIntro': '정보를 입력해 주세요. 요청을 검토한 후 이메일로 초대장을 보내드립니다.',
  'requestEmailPrefix': '요청 이메일:',
  'country': '국가',
  'fullName': '이름',
  'invitationEmail': '초대장을 받을 이메일',
  'role': '역할',
  'countryLeader': '국가 리더',
  'countryLeaderHelp': '국가 팀과 콘텐츠 우선순위를 조정합니다.',
  'countryAdministrator': '국가 관리자',
  'countryAdministratorHelp': '국가 콘텐츠와 일상적인 업데이트를 관리합니다.',
  'optionalMessage': '메시지 (선택사항)',
  'chooseCountry': '국가를 선택하세요.',
  'enterFullName': '이름을 입력하세요.',
  'validEmail': '유효한 이메일 주소를 입력하세요.',
  'openEmailToSendRequest': '이메일을 열어 요청 보내기',
  'emailDraftPrepared': '이메일 초안이 준비되었습니다',
  'emailDraftInstruction':
      '이메일 앱에 요청 내용이 준비되어 있어야 합니다. 보내기를 누르세요. 검토 후 입력한 이메일로 초대장을 보내드립니다.',
  'emailOpenError': '이메일 앱을 열 수 없습니다. 다음 주소로 요청을 보내세요:',
  'manualCopyInstruction': '웹메일을 사용하거나 이메일 앱이 설정되어 있지 않다면 아래 요청을 복사해 직접 보내세요:',
  'copyRequestText': '요청 내용 복사',
  'requestCopied': '요청 내용이 복사되었습니다',
  'returnToApp': '앱으로 돌아가기',
  'requestNextStep': '이 요청만으로는 자동으로 권한이 부여되지 않습니다. 코디네이터가 검토한 후 별도의 초대장을 보냅니다.',
};

const _copies = <AppLanguage, Map<String, String>>{
  AppLanguage.english: _english,
  AppLanguage.portuguese: _portuguese,
  AppLanguage.brazilian: _portuguese,
  AppLanguage.spanish: _spanish,
  AppLanguage.german: _german,
  AppLanguage.italian: _italian,
  AppLanguage.french: _french,
  AppLanguage.korean: _korean,
};
