import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/holy_ground.dart';
import 'package:ffpmupt/services/country_repository.dart';
import 'package:ffpmupt/services/holy_ground_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/country_scope.dart';
import 'package:ffpmupt/settings/p0_strings.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HolyGroundsScreen extends StatefulWidget {
  const HolyGroundsScreen({super.key});

  @override
  State<HolyGroundsScreen> createState() => _HolyGroundsScreenState();
}

class _HolyGroundsScreenState extends State<HolyGroundsScreen> {
  final _repository = HolyGroundRepository();
  final _searchController = TextEditingController();
  List<CountryModel> _countries = const [];
  String _query = '';
  String? _countryFilter;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final countries = await CountryRepository().loadEnabledCountries();
    if (mounted) {
      setState(() => _countries = countries);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageScope.watch(context).language;
    final strings = _HolyGroundStrings.of(language);
    final p0 = P0Strings.of(language);
    final currentCountry = CountryScope.watch(context).country?.code;
    final countryNames = {
      for (final country in _countries) country.code: country.name,
    };

    return Scaffold(
      appBar: AppBar(title: Text(strings.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: StreamBuilder<List<HolyGround>>(
              stream: _repository.watchAll(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _DirectoryState(
                    icon: Icons.cloud_off_outlined,
                    title: strings.loadError,
                    description: p0[P0Text.loadFailed],
                    actionLabel: p0[P0Text.tryAgain],
                    onAction: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allGrounds = snapshot.data!;
                if (allGrounds.isEmpty) {
                  return _DirectoryState(
                    icon: Icons.landscape_outlined,
                    title: p0[P0Text.emptyHolyGroundsTitle],
                    description: p0[P0Text.emptyHolyGroundsDescription],
                  );
                }
                final normalizedQuery = _query.trim().toLowerCase();
                final grounds =
                    allGrounds
                        .where(
                          (ground) =>
                              (_countryFilter == null ||
                                  ground.countryCode == _countryFilter) &&
                              (normalizedQuery.isEmpty ||
                                  ground.name.toLowerCase().contains(
                                    normalizedQuery,
                                  ) ||
                                  ground.city.toLowerCase().contains(
                                    normalizedQuery,
                                  ) ||
                                  ground.summary.toLowerCase().contains(
                                    normalizedQuery,
                                  )),
                        )
                        .toList()
                      ..sort((left, right) {
                        if (currentCountry != null) {
                          final leftCurrent =
                              left.countryCode == currentCountry;
                          final rightCurrent =
                              right.countryCode == currentCountry;
                          if (leftCurrent != rightCurrent) {
                            return leftCurrent ? -1 : 1;
                          }
                        }
                        final country = left.countryCode.compareTo(
                          right.countryCode,
                        );
                        return country != 0
                            ? country
                            : left.sortOrder.compareTo(right.sortOrder);
                      });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final search = TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: InputDecoration(
                              labelText: strings.search,
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                            ),
                          );
                          final filter = DropdownButtonFormField<String?>(
                            initialValue: _countryFilter,
                            decoration: InputDecoration(
                              labelText: strings.country,
                              prefixIcon: const Icon(Icons.public),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(strings.allCountries),
                              ),
                              ..._countries.map(
                                (country) => DropdownMenuItem<String?>(
                                  value: country.code,
                                  child: Text(country.name),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _countryFilter = value),
                          );
                          if (constraints.maxWidth < 640) {
                            return Column(
                              children: [
                                search,
                                const SizedBox(height: 10),
                                filter,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(flex: 3, child: search),
                              const SizedBox(width: 10),
                              Expanded(flex: 2, child: filter),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
                      child: Text(
                        strings.resultCount(grounds.length),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: grounds.isEmpty
                          ? _DirectoryState(
                              icon: Icons.search_off_outlined,
                              title: strings.empty,
                              description:
                                  p0[P0Text.emptyHolyGroundsDescription],
                              actionLabel: p0[P0Text.retry],
                              onAction: () => setState(() {
                                _query = '';
                                _countryFilter = null;
                                _searchController.clear();
                              }),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: grounds.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final ground = grounds[index];
                                return _GroundCard(
                                  ground: ground,
                                  countryName:
                                      countryNames[ground.countryCode] ??
                                      ground.countryCode.toUpperCase(),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          HolyGroundDetailScreen(
                                            ground: ground,
                                            countryName:
                                                countryNames[ground
                                                    .countryCode] ??
                                                ground.countryCode
                                                    .toUpperCase(),
                                          ),
                                    ),
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
    );
  }
}

class _DirectoryState extends StatelessWidget {
  const _DirectoryState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(description, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HolyGroundDetailScreen extends StatelessWidget {
  const HolyGroundDetailScreen({
    super.key,
    required this.ground,
    required this.countryName,
  });

  final HolyGround ground;
  final String countryName;

  Future<void> _openMaps(BuildContext context) async {
    if (!await launchUrl(
      ground.googleMapsUri,
      mode: LaunchMode.externalApplication,
    )) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o mapa.')),
        );
      }
    }
  }

  Future<void> _openEmail() async {
    await launchUrl(Uri(scheme: 'mailto', path: ground.contactEmail));
  }

  @override
  Widget build(BuildContext context) {
    final strings = _HolyGroundStrings.of(
      AppLanguageScope.watch(context).language,
    );
    return Scaffold(
      appBar: AppBar(title: Text(ground.name)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                _GroundImage(url: ground.imageUrl, height: 360),
                const SizedBox(height: 22),
                Text(
                  ground.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    ground.city,
                    countryName,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (ground.summary.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    ground.summary,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openMaps(context),
                  icon: const Icon(Icons.directions_outlined),
                  label: Text(strings.openMaps),
                ),
                if (ground.address.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _DetailSection(
                    icon: Icons.location_on_outlined,
                    title: strings.address,
                    text: ground.address,
                  ),
                ],
                if (ground.history.isNotEmpty)
                  _DetailSection(
                    icon: Icons.history_edu_outlined,
                    title: strings.history,
                    text: ground.history,
                  ),
                if (ground.visitInstructions.isNotEmpty)
                  _DetailSection(
                    icon: Icons.info_outline,
                    title: strings.visit,
                    text: ground.visitInstructions,
                  ),
                if (ground.contactName.isNotEmpty ||
                    ground.contactEmail.isNotEmpty)
                  _DetailSection(
                    icon: Icons.contact_mail_outlined,
                    title: strings.contact,
                    text: [
                      ground.contactName,
                      ground.contactEmail,
                    ].where((value) => value.isNotEmpty).join('\n'),
                    action: ground.contactEmail.isEmpty
                        ? null
                        : IconButton(
                            tooltip: strings.sendEmail,
                            onPressed: _openEmail,
                            icon: const Icon(Icons.email_outlined),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroundCard extends StatelessWidget {
  const _GroundCard({
    required this.ground,
    required this.countryName,
    required this.onTap,
  });

  final HolyGround ground;
  final String countryName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 170,
                child: _GroundImage(url: ground.imageUrl, height: 112),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ground.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        ground.city,
                        countryName,
                      ].where((value) => value.isNotEmpty).join(' · '),
                    ),
                    if (ground.summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        ground.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroundImage extends StatelessWidget {
  const _GroundImage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: url.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.text,
    this.action,
  });

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(text),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _HolyGroundStrings {
  const _HolyGroundStrings({
    required this.title,
    required this.search,
    required this.country,
    required this.allCountries,
    required this.empty,
    required this.loadError,
    required this.openMaps,
    required this.address,
    required this.history,
    required this.visit,
    required this.contact,
    required this.sendEmail,
    required this.results,
  });

  final String title;
  final String search;
  final String country;
  final String allCountries;
  final String empty;
  final String loadError;
  final String openMaps;
  final String address;
  final String history;
  final String visit;
  final String contact;
  final String sendEmail;
  final String Function(int count) results;

  String resultCount(int count) => results(count);

  static _HolyGroundStrings of(AppLanguage language) {
    return switch (language) {
      AppLanguage.english => _en,
      AppLanguage.spanish => _es,
      AppLanguage.german => _de,
      AppLanguage.italian => _it,
      AppLanguage.french => _fr,
      AppLanguage.korean => _ko,
      _ => _pt,
    };
  }

  static final _pt = _HolyGroundStrings(
    title: 'Holy Grounds',
    search: 'Pesquisar nome ou cidade',
    country: 'País',
    allCountries: 'Todos os países',
    empty: 'Nenhum Holy Ground encontrado.',
    loadError: 'Não foi possível carregar os Holy Grounds.',
    openMaps: 'Abrir no Google Maps',
    address: 'Endereço',
    history: 'História',
    visit: 'Como visitar',
    contact: 'Contato',
    sendEmail: 'Enviar email',
    results: (count) => '$count locais',
  );
  static final _en = _pt.copyWith(
    search: 'Search by name or city',
    country: 'Country',
    allCountries: 'All countries',
    empty: 'No Holy Grounds found.',
    loadError: 'Could not load Holy Grounds.',
    openMaps: 'Open in Google Maps',
    address: 'Address',
    history: 'History',
    visit: 'How to visit',
    contact: 'Contact',
    sendEmail: 'Send email',
    results: (count) => '$count places',
  );
  static final _es = _en.copyWith(
    search: 'Buscar por nombre o ciudad',
    country: 'País',
    allCountries: 'Todos los países',
    empty: 'No se encontraron Holy Grounds.',
    openMaps: 'Abrir en Google Maps',
    address: 'Dirección',
    history: 'Historia',
    visit: 'Cómo visitar',
    contact: 'Contacto',
    sendEmail: 'Enviar email',
    results: (count) => '$count lugares',
  );
  static final _de = _en.copyWith(
    search: 'Nach Name oder Stadt suchen',
    country: 'Land',
    allCountries: 'Alle Länder',
    empty: 'Keine Holy Grounds gefunden.',
    openMaps: 'In Google Maps öffnen',
    address: 'Adresse',
    history: 'Geschichte',
    visit: 'Besuchshinweise',
    contact: 'Kontakt',
    sendEmail: 'E-Mail senden',
    results: (count) => '$count Orte',
  );
  static final _it = _en.copyWith(
    search: 'Cerca per nome o città',
    country: 'Paese',
    allCountries: 'Tutti i paesi',
    empty: 'Nessun Holy Ground trovato.',
    openMaps: 'Apri in Google Maps',
    address: 'Indirizzo',
    history: 'Storia',
    visit: 'Come visitare',
    contact: 'Contatto',
    sendEmail: 'Invia email',
    results: (count) => '$count luoghi',
  );
  static final _fr = _en.copyWith(
    search: 'Rechercher par nom ou ville',
    country: 'Pays',
    allCountries: 'Tous les pays',
    empty: 'Aucun Holy Ground trouvé.',
    openMaps: 'Ouvrir dans Google Maps',
    address: 'Adresse',
    history: 'Histoire',
    visit: 'Comment visiter',
    contact: 'Contact',
    sendEmail: 'Envoyer un e-mail',
    results: (count) => '$count lieux',
  );
  static final _ko = _en.copyWith(
    search: '이름 또는 도시 검색',
    country: '국가',
    allCountries: '모든 국가',
    empty: 'Holy Ground를 찾을 수 없습니다.',
    openMaps: 'Google 지도에서 열기',
    address: '주소',
    history: '역사',
    visit: '방문 안내',
    contact: '연락처',
    sendEmail: '이메일 보내기',
    results: (count) => '$count곳',
  );

  _HolyGroundStrings copyWith({
    String? title,
    String? search,
    String? country,
    String? allCountries,
    String? empty,
    String? loadError,
    String? openMaps,
    String? address,
    String? history,
    String? visit,
    String? contact,
    String? sendEmail,
    String Function(int count)? results,
  }) {
    return _HolyGroundStrings(
      title: title ?? this.title,
      search: search ?? this.search,
      country: country ?? this.country,
      allCountries: allCountries ?? this.allCountries,
      empty: empty ?? this.empty,
      loadError: loadError ?? this.loadError,
      openMaps: openMaps ?? this.openMaps,
      address: address ?? this.address,
      history: history ?? this.history,
      visit: visit ?? this.visit,
      contact: contact ?? this.contact,
      sendEmail: sendEmail ?? this.sendEmail,
      results: results ?? this.results,
    );
  }
}
