import 'package:ffpmupt/screens/family_promise_screen.dart';
import 'package:ffpmupt/screens/list_of_songs_screen.dart';
import 'package:ffpmupt/screens/motto_screen.dart';
import 'package:ffpmupt/screens/offering_screen.dart';
import 'package:ffpmupt/screens/public_offering_screen.dart';
import 'package:ffpmupt/screens/videos_screen.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLanguageController _languageController = AppLanguageController();

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      controller: _languageController,
      child: MaterialApp(
        title: 'FFPMU PT',
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const Home(),
        routes: {'/ofertas': (context) => const PublicOfferingScreen()},
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    return Scaffold(
      appBar: AppBar(title: const Text('FFPMU PT')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _SundayGuideGrid(
                      cards: [
                        _HomeActionCard(
                          step: '1',
                          icon: Icons.library_music,
                          title: strings.songs,
                          subtitle: strings.songsSubtitle,
                          color: const Color(0xff7a5428),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ListOfSongsScreen(),
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
                              builder: (context) => const FamilyPromiseScreen(),
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
                              builder: (context) => const MottoScreen(),
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
                              builder: (context) => const OfferingScreen(),
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
                              builder: (context) => const VideosScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _SundayGuideGrid extends StatelessWidget {
  const _SundayGuideGrid({required this.cards});

  final List<_HomeActionCard> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;

        return GridView.builder(
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.8 : 2.1,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

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
          strings.homeSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: const Color(0xff5f6d68)),
        ),
        const SizedBox(height: 16),
        Text(
          strings.appLanguage,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xff65716c),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const _AppLanguageSelector(),
      ],
    );
  }
}

class _AppLanguageSelector extends StatelessWidget {
  const _AppLanguageSelector();

  @override
  Widget build(BuildContext context) {
    final controller = AppLanguageScope.watch(context);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final language in AppLanguage.values)
          ChoiceChip(
            avatar: const Icon(Icons.language, size: 18),
            label: Text(appLanguageLabel(language)),
            selected: controller.language == language,
            onSelected: (_) => controller.setLanguage(language),
          ),
      ],
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String step;
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
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      step,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
