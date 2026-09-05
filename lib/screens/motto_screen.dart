import 'package:ffpmupt/models/motto.dart';
import 'package:ffpmupt/services/motto_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/theme/app_theme.dart';
import 'package:ffpmupt/widgets/reading_mode_button.dart';
import 'package:flutter/material.dart';

class MottoScreen extends StatefulWidget {
  const MottoScreen({super.key, required this.countryCode});

  final String countryCode;

  @override
  State<MottoScreen> createState() => _MottoScreenState();
}

class _MottoScreenState extends State<MottoScreen> {
  late final MottoRepository _repository;
  bool _isPresentation = false;

  @override
  void initState() {
    super.initState();
    _repository = MottoRepository(countryCode: widget.countryCode);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<MottoSettings>(
      stream: _repository.watch(),
      initialData: MottoSettings.fallback(countryCode: widget.countryCode),
      builder: (context, snapshot) {
        final motto =
            snapshot.data ??
            MottoSettings.fallback(countryCode: widget.countryCode);
        return Scaffold(
          appBar: AppBar(
            title: Text(motto.isConfigured ? motto.title : strings.motto),
            actions: [
              ReadingModeButton(
                isPresentation: _isPresentation,
                onPressed: () =>
                    setState(() => _isPresentation = !_isPresentation),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _isPresentation
                        ? AppTypography.presentationWidth
                        : AppTypography.readingWidth,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      child: motto.isConfigured
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Icon(
                                  Icons.auto_stories,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 42,
                                ),
                                const SizedBox(height: 20),
                                LayoutBuilder(
                                  builder: (context, constraints) => Text(
                                    motto.body,
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: AppColors.ink,
                                      fontSize: AppTypography.readingTextSize(
                                        availableWidth: constraints.maxWidth,
                                        presentation: _isPresentation,
                                      ),
                                      height: _isPresentation ? 1.28 : 1.55,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: _isPresentation
                                        ? TextAlign.center
                                        : TextAlign.start,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              strings.mottoNotConfigured,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
