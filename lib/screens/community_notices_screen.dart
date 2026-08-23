import 'package:ffpmupt/models/community_notice.dart';
import 'package:ffpmupt/services/community_notice_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityNoticesScreen extends StatefulWidget {
  const CommunityNoticesScreen({super.key, required this.countryCode});

  final String countryCode;

  @override
  State<CommunityNoticesScreen> createState() => _CommunityNoticesScreenState();
}

class _CommunityNoticesScreenState extends State<CommunityNoticesScreen> {
  late final CommunityNoticeRepository _repository;
  NoticeCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _repository = CommunityNoticeRepository(countryCode: widget.countryCode);
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageScope.watch(context).language;
    final copy = CommunityNoticeCopy.of(language);
    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: StreamBuilder<List<CommunityNotice>>(
              stream: _repository.watchPublic(),
              builder: (context, snapshot) {
                final notices = snapshot.data ?? const <CommunityNotice>[];
                final visible = _selectedCategory == null
                    ? notices
                    : notices
                          .where(
                            (notice) => notice.category == _selectedCategory,
                          )
                          .toList();
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              copy.subtitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xff5f6d68)),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text(copy.all),
                                    selected: _selectedCategory == null,
                                    onSelected: (_) => setState(
                                      () => _selectedCategory = null,
                                    ),
                                  ),
                                  for (final category
                                      in NoticeCategory.values) ...[
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      avatar: Icon(
                                        noticeCategoryIcon(category),
                                        size: 18,
                                      ),
                                      label: Text(copy.categoryLabel(category)),
                                      selected: _selectedCategory == category,
                                      onSelected: (_) => setState(
                                        () => _selectedCategory = category,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (snapshot.hasError && notices.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoticeEmptyState(
                          icon: Icons.cloud_off_outlined,
                          message: copy.loadFailed,
                        ),
                      )
                    else if (!snapshot.hasData)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (visible.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _NoticeEmptyState(
                          icon: Icons.campaign_outlined,
                          message: copy.empty,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                        sliver: SliverList.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _NoticeCard(notice: visible[index], copy: copy),
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

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.copy});

  final CommunityNotice notice;
  final CommunityNoticeCopy copy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = notice.parsedDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    noticeCategoryIcon(notice.category),
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              copy.categoryLabel(notice.category),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colorScheme.primary),
                            ),
                          ),
                          if (notice.pinned) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.push_pin_outlined,
                              size: 17,
                              color: colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notice.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (date != null || notice.location.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (date != null)
                    _NoticeMetadata(
                      icon: Icons.calendar_today_outlined,
                      label: _formatDate(date),
                    ),
                  if (notice.location.isNotEmpty)
                    _NoticeMetadata(
                      icon: Icons.location_on_outlined,
                      label: notice.location,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SelectableText(
              notice.body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: const Color(0xff293833),
              ),
            ),
            if (notice.linkUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    final uri = Uri.tryParse(notice.linkUrl);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(copy.openLink),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoticeMetadata extends StatelessWidget {
  const _NoticeMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xff5f6d68)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _NoticeEmptyState extends StatelessWidget {
  const _NoticeEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

IconData noticeCategoryIcon(NoticeCategory category) {
  return switch (category) {
    NoticeCategory.general => Icons.campaign_outlined,
    NoticeCategory.event => Icons.event_outlined,
    NoticeCategory.specialDay => Icons.celebration_outlined,
    NoticeCategory.workshop => Icons.handyman_outlined,
    NoticeCategory.weeklyHomework => Icons.assignment_outlined,
  };
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class CommunityNoticeCopy {
  const CommunityNoticeCopy({
    required this.title,
    required this.subtitle,
    required this.empty,
    required this.loadFailed,
    required this.all,
    required this.openLink,
    required this.categories,
  });

  final String title;
  final String subtitle;
  final String empty;
  final String loadFailed;
  final String all;
  final String openLink;
  final Map<NoticeCategory, String> categories;

  String categoryLabel(NoticeCategory category) => categories[category]!;

  static CommunityNoticeCopy of(AppLanguage language) {
    return switch (language) {
      AppLanguage.english => _englishNoticeCopy,
      AppLanguage.spanish => _spanishNoticeCopy,
      AppLanguage.german => _germanNoticeCopy,
      AppLanguage.italian => _italianNoticeCopy,
      AppLanguage.french => _frenchNoticeCopy,
      AppLanguage.korean => _koreanNoticeCopy,
      AppLanguage.brazilian || AppLanguage.portuguese => _portugueseNoticeCopy,
    };
  }
}

const _portugueseNoticeCopy = CommunityNoticeCopy(
  title: 'Avisos e notícias',
  subtitle: 'Eventos, dias especiais, workshops e tarefa da semana.',
  empty: 'Ainda não há avisos publicados.',
  loadFailed: 'Não foi possível carregar os avisos.',
  all: 'Todos',
  openLink: 'Abrir ligação',
  categories: {
    NoticeCategory.general: 'Aviso',
    NoticeCategory.event: 'Evento',
    NoticeCategory.specialDay: 'Dia especial',
    NoticeCategory.workshop: 'Workshop',
    NoticeCategory.weeklyHomework: 'Tarefa da semana',
  },
);

const _englishNoticeCopy = CommunityNoticeCopy(
  title: 'Notices and news',
  subtitle: 'Events, special days, workshops, and this week’s homework.',
  empty: 'There are no published notices yet.',
  loadFailed: 'Could not load the notices.',
  all: 'All',
  openLink: 'Open link',
  categories: {
    NoticeCategory.general: 'Notice',
    NoticeCategory.event: 'Event',
    NoticeCategory.specialDay: 'Special day',
    NoticeCategory.workshop: 'Workshop',
    NoticeCategory.weeklyHomework: 'Weekly homework',
  },
);

const _spanishNoticeCopy = CommunityNoticeCopy(
  title: 'Avisos y noticias',
  subtitle: 'Eventos, días especiales, talleres y tarea de la semana.',
  empty: 'Todavía no hay avisos publicados.',
  loadFailed: 'No se pudieron cargar los avisos.',
  all: 'Todos',
  openLink: 'Abrir enlace',
  categories: {
    NoticeCategory.general: 'Aviso',
    NoticeCategory.event: 'Evento',
    NoticeCategory.specialDay: 'Día especial',
    NoticeCategory.workshop: 'Taller',
    NoticeCategory.weeklyHomework: 'Tarea semanal',
  },
);

const _germanNoticeCopy = CommunityNoticeCopy(
  title: 'Hinweise und Neuigkeiten',
  subtitle: 'Veranstaltungen, besondere Tage, Workshops und Wochenaufgaben.',
  empty: 'Noch keine Hinweise veröffentlicht.',
  loadFailed: 'Die Hinweise konnten nicht geladen werden.',
  all: 'Alle',
  openLink: 'Link öffnen',
  categories: {
    NoticeCategory.general: 'Hinweis',
    NoticeCategory.event: 'Veranstaltung',
    NoticeCategory.specialDay: 'Besonderer Tag',
    NoticeCategory.workshop: 'Workshop',
    NoticeCategory.weeklyHomework: 'Wochenaufgabe',
  },
);

const _italianNoticeCopy = CommunityNoticeCopy(
  title: 'Avvisi e notizie',
  subtitle: 'Eventi, giorni speciali, workshop e compito della settimana.',
  empty: 'Non ci sono ancora avvisi pubblicati.',
  loadFailed: 'Impossibile caricare gli avvisi.',
  all: 'Tutti',
  openLink: 'Apri link',
  categories: {
    NoticeCategory.general: 'Avviso',
    NoticeCategory.event: 'Evento',
    NoticeCategory.specialDay: 'Giorno speciale',
    NoticeCategory.workshop: 'Workshop',
    NoticeCategory.weeklyHomework: 'Compito settimanale',
  },
);

const _frenchNoticeCopy = CommunityNoticeCopy(
  title: 'Annonces et actualités',
  subtitle: 'Événements, journées spéciales, ateliers et devoir de la semaine.',
  empty: 'Aucune annonce publiée pour le moment.',
  loadFailed: 'Impossible de charger les annonces.',
  all: 'Toutes',
  openLink: 'Ouvrir le lien',
  categories: {
    NoticeCategory.general: 'Annonce',
    NoticeCategory.event: 'Événement',
    NoticeCategory.specialDay: 'Journée spéciale',
    NoticeCategory.workshop: 'Atelier',
    NoticeCategory.weeklyHomework: 'Devoir hebdomadaire',
  },
);

const _koreanNoticeCopy = CommunityNoticeCopy(
  title: '공지 및 소식',
  subtitle: '행사, 특별한 날, 워크숍 및 이번 주 과제입니다.',
  empty: '아직 게시된 공지가 없습니다.',
  loadFailed: '공지를 불러올 수 없습니다.',
  all: '전체',
  openLink: '링크 열기',
  categories: {
    NoticeCategory.general: '공지',
    NoticeCategory.event: '행사',
    NoticeCategory.specialDay: '특별한 날',
    NoticeCategory.workshop: '워크숍',
    NoticeCategory.weeklyHomework: '주간 과제',
  },
);
