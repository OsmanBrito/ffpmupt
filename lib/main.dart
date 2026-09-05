import 'dart:async';

import 'package:ffpmupt/app_branding.dart';
import 'package:ffpmupt/firebase_options.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/access_request_country.dart';
import 'package:ffpmupt/models/community_notice.dart';
import 'package:ffpmupt/navigation/app_routes.dart';
import 'package:ffpmupt/screens/admin/admin_screen.dart';
import 'package:ffpmupt/screens/admin/admin_invite_screen.dart';
import 'package:ffpmupt/screens/country_selection_screen.dart';
import 'package:ffpmupt/screens/community_notices_screen.dart';
import 'package:ffpmupt/screens/access_request_screen.dart';
import 'package:ffpmupt/screens/family_promise_screen.dart';
import 'package:ffpmupt/screens/holy_grounds_screen.dart';
import 'package:ffpmupt/screens/list_of_songs_screen.dart';
import 'package:ffpmupt/screens/motto_screen.dart';
import 'package:ffpmupt/screens/public_offering_screen.dart';
import 'package:ffpmupt/screens/sunday_mode_screen.dart';
import 'package:ffpmupt/screens/videos_screen.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/country_scope.dart';
import 'package:ffpmupt/settings/p0_strings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffpmupt/services/offline_audio_cache.dart';
import 'package:ffpmupt/services/community_notice_repository.dart';
import 'package:ffpmupt/services/song_repository.dart';
import 'package:ffpmupt/settings/home_copy.dart';
import 'package:ffpmupt/widgets/language_menu_button.dart';
import 'package:ffpmupt/theme/app_theme.dart';
import 'package:ffpmupt/widgets/app_brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      webPersistentTabManager: WebPersistentMultipleTabManager(),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLanguageController _languageController = AppLanguageController(
    loadStoredLanguage: true,
  );
  final CountryController _countryController = CountryController();
  StreamSubscription<SongCatalogState>? _offlineSyncSubscription;
  String? _syncedCountryCode;

  @override
  void initState() {
    super.initState();
    _countryController.addListener(_handleCountryChanged);
    unawaited(_countryController.initialize());
  }

  void _handleCountryChanged() {
    if (mounted) {
      setState(() {});
    }
    final country = _countryController.country;
    if (country == null) {
      _syncedCountryCode = null;
      unawaited(_offlineSyncSubscription?.cancel());
      _offlineSyncSubscription = null;
      return;
    }
    _languageController.useCountryLanguage(country.defaultLanguage);
    if (_syncedCountryCode == country.code) {
      return;
    }

    _syncedCountryCode = country.code;
    unawaited(_offlineSyncSubscription?.cancel());
    final audioCache = OfflineAudioCache();
    _offlineSyncSubscription = SongRepository(countryCode: country.code)
        .watchCatalog()
        .listen((state) {
          audioCache.setAvailable(
            state.songs.expand(
              (song) => song.audioTracks
                  .where((track) => track.enabled)
                  .map((track) => track.url),
            ),
          );
        });
  }

  @override
  void dispose() {
    _countryController.removeListener(_handleCountryChanged);
    _countryController.dispose();
    unawaited(_offlineSyncSubscription?.cancel());
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CountryScope(
      controller: _countryController,
      child: AppLanguageScope(
        controller: _languageController,
        child: MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: _homeForCountry(),
          routes: {
            AppRoutes.requestAccess: (context) => AccessRequestScreen(
              countries: europeanAccessRequestCountries,
              initialCountryCode: _countryController.country?.code,
            ),
            AppRoutes.admin: (context) => _CountryRouteScreen(
              builder: (country) => AdminScreen(country: country),
            ),
            AppRoutes.offerings: (context) => _CountryRouteScreen(
              builder: (country) =>
                  PublicOfferingScreen(countryCode: country.code),
            ),
            AppRoutes.songs: (context) => _CountryRouteScreen(
              builder: (country) =>
                  ListOfSongsScreen(countryCode: country.code),
            ),
            AppRoutes.familyPromise: (context) => _CountryRouteScreen(
              builder: (country) => FamilyPromiseScreen(country: country),
            ),
            AppRoutes.motto: (context) => _CountryRouteScreen(
              builder: (country) => MottoScreen(countryCode: country.code),
            ),
            AppRoutes.weeklyVideos: (context) => _CountryRouteScreen(
              builder: (country) => VideosScreen(countryCode: country.code),
            ),
            AppRoutes.notices: (context) => _CountryRouteScreen(
              builder: (country) =>
                  CommunityNoticesScreen(countryCode: country.code),
            ),
            AppRoutes.holyGrounds: (context) =>
                const _CountryRouteScreen(builder: _buildHolyGrounds),
            AppRoutes.sundayMode: (context) => _CountryRouteScreen(
              builder: (country) => SundayModeScreen(country: country),
            ),
          },
          onGenerateRoute: (settings) {
            final segments = Uri.parse(settings.name ?? '').pathSegments;
            if (segments.length == 2 && segments.first == 'invite') {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => AdminInviteScreen(inviteId: segments[1]),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _homeForCountry() {
    if (_countryController.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final country = _countryController.country;
    if (country == null) {
      return CountrySelectionScreen(
        countries: _countryController.countries,
        onSelected: (selected) =>
            unawaited(_countryController.selectCountry(selected)),
      );
    }
    return const Home();
  }
}

Widget _buildHolyGrounds(CountryModel _) => const HolyGroundsScreen();

class _CountryRouteScreen extends StatelessWidget {
  const _CountryRouteScreen({required this.builder});

  final Widget Function(CountryModel country) builder;

  @override
  Widget build(BuildContext context) {
    final controller = CountryScope.watch(context);
    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final country = controller.country;
    if (country == null) {
      return CountrySelectionScreen(
        countries: controller.countries,
        onSelected: (selected) => unawaited(controller.selectCountry(selected)),
      );
    }
    return builder(country);
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageScope.watch(context).language;
    final strings = AppStrings.of(language);
    final p0 = P0Strings.of(language);
    final homeCopy = HomeCopy.of(language);
    final country = CountryScope.watch(context).country!;
    final wideNavigation = MediaQuery.sizeOf(context).width >= 760;

    void openSundayMode() =>
        Navigator.of(context).pushNamed(AppRoutes.sundayMode);

    void changeCountry() =>
        unawaited(CountryScope.read(context).showCountrySelection());

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandLockup(compact: true),
        actions: [
          LanguageMenuButton(showLabel: wideNavigation),
          if (wideNavigation)
            TextButton.icon(
              onPressed: changeCountry,
              icon: const Icon(Icons.location_on_outlined, size: 19),
              label: Text(country.name),
            ),
          PopupMenuButton<_HomeMenuAction>(
            tooltip: homeCopy.menu,
            icon: const Icon(Icons.more_horiz),
            onSelected: (action) {
              switch (action) {
                case _HomeMenuAction.country:
                  changeCountry();
                case _HomeMenuAction.admin:
                  Navigator.of(context).pushNamed(AppRoutes.admin);
              }
            },
            itemBuilder: (context) => [
              if (!wideNavigation)
                PopupMenuItem(
                  value: _HomeMenuAction.country,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.public),
                    title: Text(strings.changeCountry),
                    subtitle: Text(country.name),
                  ),
                ),
              PopupMenuItem(
                value: _HomeMenuAction.admin,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(strings.adminArea),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wideNavigation ? 24 : 16,
                14,
                wideNavigation ? 24 : 16,
                32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeHeader(
                    country: country,
                    onPrepareService: openSundayMode,
                  ),
                  const SizedBox(height: 20),
                  _ThisWeekPanel(
                    countryCode: country.code,
                    copy: homeCopy,
                    noticeCopy: CommunityNoticeCopy.of(language),
                    onOpen: () =>
                        Navigator.of(context).pushNamed(AppRoutes.notices),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: homeCopy.serviceModules),
                  const SizedBox(height: 12),
                  _SundayGuideGrid(
                    cards: [
                      _HomeActionCard(
                        step: '1',
                        icon: Icons.library_music,
                        title: strings.songs,
                        subtitle: strings.songsSubtitle,
                        color: AppColors.gold,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.songs),
                      ),
                      _HomeActionCard(
                        step: '2',
                        icon: Icons.church_rounded,
                        title: strings.familyPromise,
                        subtitle: strings.familyPromiseSubtitle,
                        color: AppColors.berry,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.familyPromise),
                      ),
                      _HomeActionCard(
                        step: '3',
                        icon: Icons.auto_stories,
                        title: strings.motto,
                        subtitle: strings.mottoSubtitle,
                        color: AppColors.primary,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.motto),
                      ),
                      _HomeActionCard(
                        step: '4',
                        icon: Icons.volunteer_activism,
                        title: strings.offerings,
                        subtitle: strings.offeringsSubtitle,
                        color: AppColors.primaryStrong,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.offerings),
                      ),
                      _HomeActionCard(
                        step: '5',
                        icon: Icons.ondemand_video,
                        title: strings.weeklyVideos,
                        subtitle: strings.weeklyVideosSubtitle,
                        color: AppColors.blue,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.weeklyVideos),
                      ),
                      _HomeActionCard(
                        step: '6',
                        icon: Icons.campaign_outlined,
                        title: CommunityNoticeCopy.of(
                          AppLanguageScope.watch(context).language,
                        ).title,
                        subtitle: CommunityNoticeCopy.of(
                          AppLanguageScope.watch(context).language,
                        ).subtitle,
                        color: AppColors.terracotta,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.notices),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  _SectionHeader(title: p0[P0Text.resources]),
                  const SizedBox(height: 12),
                  _SundayGuideGrid(
                    cards: [
                      _HomeActionCard(
                        icon: Icons.landscape_outlined,
                        title: 'Holy Grounds',
                        subtitle: _holyGroundsSubtitle(
                          AppLanguageScope.watch(context).language,
                        ),
                        color: AppColors.olive,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.holyGrounds),
                      ),
                    ],
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

enum _HomeMenuAction { country, admin }

String _holyGroundsSubtitle(AppLanguage language) {
  return switch (language) {
    AppLanguage.english => 'Sacred places across Europe',
    AppLanguage.spanish => 'Lugares sagrados de Europa',
    AppLanguage.german => 'Heilige Orte in Europa',
    AppLanguage.italian => 'Luoghi sacri in Europa',
    AppLanguage.french => 'Lieux sacrés en Europe',
    AppLanguage.korean => '유럽의 성지',
    _ => 'Locais sagrados na Europa',
  };
}

class _SundayGuideGrid extends StatelessWidget {
  const _SundayGuideGrid({required this.cards});

  final List<_HomeActionCard> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 940
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: width, height: 126, child: card))
              .toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.country, required this.onPrepareService});

  final CountryModel country;
  final VoidCallback onPrepareService;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    final language = AppLanguageScope.watch(context).language;
    final p0 = P0Strings.of(language);
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.sundayService,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        Text(
          _countryHomeSubtitle(language, country.name),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CountryBadge(countryName: country.name),
            const _OfflineAudioCacheIndicator(),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mintSoft, AppColors.surface],
        ),
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBrandMark(size: 58),
                    const SizedBox(width: 16),
                    Expanded(child: intro),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onPrepareService,
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(p0[P0Text.prepare]),
                ),
              ],
            );
          }
          return Row(
            children: [
              const AppBrandMark(size: 66),
              const SizedBox(width: 20),
              Expanded(child: intro),
              const SizedBox(width: 20),
              FilledButton.icon(
                onPressed: onPrepareService,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(p0[P0Text.prepare]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CountryBadge extends StatelessWidget {
  const _CountryBadge({required this.countryName});

  final String countryName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 17),
            const SizedBox(width: 5),
            Text(
              countryName,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

String _countryHomeSubtitle(AppLanguage language, String countryName) {
  return switch (language) {
    AppLanguage.english =>
      'Texts and songs for the FFPMU community in $countryName',
    AppLanguage.spanish =>
      'Textos y canciones para la comunidad FFPMU de $countryName',
    AppLanguage.german =>
      'Texte und Lieder für die FFPMU-Gemeinschaft in $countryName',
    AppLanguage.italian =>
      'Testi e canti per la comunità FFPMU in $countryName',
    AppLanguage.french =>
      'Textes et chants pour la communauté FFPMU de $countryName',
    AppLanguage.korean => '$countryName FFPMU 공동체를 위한 말씀과 성가',
    _ => 'Textos e canções para a comunidade FFPMU de $countryName',
  };
}

class _OfflineAudioCacheIndicator extends StatelessWidget {
  const _OfflineAudioCacheIndicator();

  @override
  Widget build(BuildContext context) {
    final cache = OfflineAudioCache();
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final p0 = P0Strings.of(AppLanguageScope.watch(context).language);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 34),
      child: StreamBuilder<OfflineAudioCacheProgress>(
        stream: cache.progress,
        initialData: cache.currentProgress,
        builder: (context, snapshot) {
          final progress = snapshot.data ?? OfflineAudioCacheProgress.idle;
          final isReady = progress.status == OfflineAudioCacheStatus.ready;
          final isPartial = progress.status == OfflineAudioCacheStatus.partial;
          final color = isPartial
              ? Theme.of(context).colorScheme.error
              : const Color(0xff2f6b4f);
          if (progress.status == OfflineAudioCacheStatus.available) {
            return OutlinedButton.icon(
              onPressed: cache.downloadAvailable,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: Text('${p0[P0Text.downloadOffline]} (${progress.total})'),
            );
          }
          final label = switch (progress.status) {
            OfflineAudioCacheStatus.ready => strings.offlineAudioReady,
            OfflineAudioCacheStatus.partial => strings.offlineAudioPartial,
            _ => strings.offlineAudioPreparing,
          };
          final counter = progress.total > 0 && !isReady
              ? ' ${progress.completed}/${progress.total}'
              : '';
          final checkedAt = progress.updatedAt;
          final time = checkedAt == null
              ? ''
              : ' · ${checkedAt.hour.toString().padLeft(2, '0')}:${checkedAt.minute.toString().padLeft(2, '0')}';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isReady
                    ? Icons.offline_pin_outlined
                    : isPartial
                    ? Icons.cloud_off_outlined
                    : Icons.download_outlined,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$label$counter$time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isPartial)
                IconButton(
                  tooltip: p0[P0Text.retry],
                  onPressed: cache.retry,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String? step;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: color, size: 27),
                  ),
                  if (step != null)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          step!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThisWeekPanel extends StatelessWidget {
  const _ThisWeekPanel({
    required this.countryCode,
    required this.copy,
    required this.noticeCopy,
    required this.onOpen,
  });

  final String countryCode;
  final HomeCopy copy;
  final CommunityNoticeCopy noticeCopy;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityNotice>>(
      stream: CommunityNoticeRepository(countryCode: countryCode).watchPublic(),
      builder: (context, snapshot) {
        final notices = snapshot.data ?? const <CommunityNotice>[];
        if (notices.isEmpty) {
          return const SizedBox.shrink();
        }
        final featured = notices.take(2).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _SectionHeader(title: copy.thisWeek)),
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: Text(copy.seeAll),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 700
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    for (final notice in featured)
                      SizedBox(
                        width: itemWidth,
                        child: _FeaturedNoticeTile(
                          notice: notice,
                          category: noticeCopy.categoryLabel(notice.category),
                          onTap: onOpen,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _FeaturedNoticeTile extends StatelessWidget {
  const _FeaturedNoticeTile({
    required this.notice,
    required this.category,
    required this.onTap,
  });

  final CommunityNotice notice;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = notice.parsedDate;
    final details = [
      category,
      if (date != null) _shortNoticeDate(date),
      if (notice.location.isNotEmpty) notice.location,
    ].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  noticeCategoryIcon(notice.category),
                  color: AppColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notice.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (notice.pinned)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.push_pin_outlined, size: 17),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

String _shortNoticeDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}';
