import 'dart:async';

import 'package:ffpmupt/app_branding.dart';
import 'package:ffpmupt/firebase_options.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/access_request_country.dart';
import 'package:ffpmupt/screens/admin/admin_screen.dart';
import 'package:ffpmupt/screens/admin/admin_invite_screen.dart';
import 'package:ffpmupt/screens/country_selection_screen.dart';
import 'package:ffpmupt/screens/community_notices_screen.dart';
import 'package:ffpmupt/screens/access_request_screen.dart';
import 'package:ffpmupt/screens/family_promise_screen.dart';
import 'package:ffpmupt/screens/holy_grounds_screen.dart';
import 'package:ffpmupt/screens/list_of_songs_screen.dart';
import 'package:ffpmupt/screens/motto_screen.dart';
import 'package:ffpmupt/screens/offering_screen.dart';
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
import 'package:ffpmupt/services/song_repository.dart';
import 'package:ffpmupt/widgets/language_menu_button.dart';
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
          audioCache.cacheAll(
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
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff245c52),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xfff7f5ef),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Color(0xfff7f5ef),
              foregroundColor: Color(0xff193c37),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xffe8e1d5)),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          home: _homeForCountry(),
          routes: {
            '/request-access': (context) => AccessRequestScreen(
              countries: europeanAccessRequestCountries,
              initialCountryCode: _countryController.country?.code,
            ),
            if (_countryController.country case final country?)
              '/admin': (context) => AdminScreen(country: country),
            '/ofertas': (context) => PublicOfferingScreen(
              countryCode: _countryController.country?.code ?? '',
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

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final p0 = P0Strings.of(AppLanguageScope.watch(context).language);
    final country = CountryScope.watch(context).country!;

    return Scaffold(
      appBar: AppBar(
        title: Text('$appShortName · ${country.name}'),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            tooltip: strings.changeCountry,
            onPressed: () =>
                unawaited(CountryScope.read(context).showCountrySelection()),
            icon: const Icon(Icons.public),
          ),
          IconButton(
            tooltip: strings.adminArea,
            onPressed: () => Navigator.of(context).pushNamed('/admin'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeHeader(country: country),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            SundayModeScreen(country: country),
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(p0[P0Text.startSunday]),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _SectionHeader(title: p0[P0Text.sundayActions]),
                  const SizedBox(height: 12),
                  _SundayGuideGrid(
                    cards: [
                      _HomeActionCard(
                        step: '1',
                        icon: Icons.library_music,
                        title: strings.songs,
                        subtitle: strings.songsSubtitle,
                        color: const Color(0xff7a5428),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ListOfSongsScreen(countryCode: country.code),
                          ),
                        ),
                      ),
                      _HomeActionCard(
                        step: '2',
                        icon: Icons.church_rounded,
                        title: strings.familyPromise,
                        subtitle: strings.familyPromiseSubtitle,
                        color: const Color(0xff7d2f3a),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                FamilyPromiseScreen(country: country),
                          ),
                        ),
                      ),
                      _HomeActionCard(
                        step: '3',
                        icon: Icons.auto_stories,
                        title: strings.motto,
                        subtitle: strings.mottoSubtitle,
                        color: colorScheme.primary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                MottoScreen(countryCode: country.code),
                          ),
                        ),
                      ),
                      _HomeActionCard(
                        step: '4',
                        icon: Icons.volunteer_activism,
                        title: strings.offerings,
                        subtitle: strings.offeringsSubtitle,
                        color: const Color(0xff2f6b4f),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                OfferingScreen(countryCode: country.code),
                          ),
                        ),
                      ),
                      _HomeActionCard(
                        step: '5',
                        icon: Icons.ondemand_video,
                        title: strings.weeklyVideos,
                        subtitle: strings.weeklyVideosSubtitle,
                        color: const Color(0xff2f577d),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                VideosScreen(countryCode: country.code),
                          ),
                        ),
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
                        color: const Color(0xff8a4d2f),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CommunityNoticesScreen(
                              countryCode: country.code,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
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
                        color: const Color(0xff536b3f),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HolyGroundsScreen(),
                          ),
                        ),
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
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final width = columns == 2
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: width, height: 170, child: card))
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
  const _HomeHeader({required this.country});

  final CountryModel country;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.church_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.sundayService,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xff193c37),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _countryHomeSubtitle(
            AppLanguageScope.watch(context).language,
            country.name,
          ),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: const Color(0xff5f6d68)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 6),
            Text(
              country.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _OfflineAudioCacheIndicator(),
      ],
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

    return SizedBox(
      height: 42,
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
            mainAxisAlignment: MainAxisAlignment.center,
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
              if (!isReady && !isPartial) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (step != null) ...[
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        step!,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(icon, color: color, size: 32),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xff1f2724),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xff65716c),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
