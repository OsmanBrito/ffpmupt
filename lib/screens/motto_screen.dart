import 'package:ffpmupt/models/motto.dart';
import 'package:ffpmupt/services/motto_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MottoScreen extends StatefulWidget {
  const MottoScreen({super.key, required this.countryCode});

  final String countryCode;

  @override
  State<MottoScreen> createState() => _MottoScreenState();
}

class _MottoScreenState extends State<MottoScreen> {
  late final MottoRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = MottoRepository(countryCode: widget.countryCode);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(strings.motto)),
      body: StreamBuilder<MottoSettings>(
        stream: _repository.watch(),
        initialData: MottoSettings.fallback(),
        builder: (context, snapshot) {
          final motto = snapshot.data ?? MottoSettings.fallback();
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories,
                            color: Theme.of(context).colorScheme.primary,
                            size: 42,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            motto.title,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: const Color(0xff193c37),
                              fontSize: kIsWeb ? 42 : null,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            motto.body,
                            style: textTheme.headlineSmall?.copyWith(
                              color: const Color(0xff293833),
                              fontSize: kIsWeb ? 34 : 22,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
