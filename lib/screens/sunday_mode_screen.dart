import 'dart:async';

import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/sunday_mode.dart';
import 'package:ffpmupt/navigation/app_routes.dart';
import 'package:ffpmupt/screens/community_notices_screen.dart';
import 'package:ffpmupt/services/offline_audio_cache.dart';
import 'package:ffpmupt/services/sunday_mode_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/p0_strings.dart';
import 'package:ffpmupt/settings/presentation_mode.dart';
import 'package:ffpmupt/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SundayModeScreen extends StatefulWidget {
  const SundayModeScreen({super.key, required this.country});

  final CountryModel country;

  @override
  State<SundayModeScreen> createState() => _SundayModeScreenState();
}

class _SundayModeScreenState extends State<SundayModeScreen> {
  late final SundayModeRepository _repository;
  List<SundayPlanItem> _plan = const [];
  List<SundaySessionReport> _reports = const [];
  final Set<SundayModule> _completed = {};
  DateTime? _startedAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = SundayModeRepository(countryCode: widget.country.code);
    unawaited(_load());
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repository.loadPlan(),
      _repository.loadReports(),
      _repository.loadActiveSession(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _plan = results[0] as List<SundayPlanItem>;
      _reports = results[1] as List<SundaySessionReport>;
      final activeSession = results[2] as SundaySessionState?;
      _startedAt = activeSession?.startedAt;
      _completed
        ..clear()
        ..addAll(activeSession?.completedModules ?? const {});
      _isLoading = false;
    });
  }

  Future<void> _savePlan() => _repository.savePlan(_plan);

  void _reorder(int oldIndex, int newIndex) {
    if (_startedAt != null) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _plan.removeAt(oldIndex);
      _plan.insert(newIndex, item);
    });
    unawaited(_savePlan());
  }

  void _toggleIncluded(int index, bool included) {
    setState(() => _plan[index] = _plan[index].copyWith(enabled: included));
    unawaited(_savePlan());
  }

  void _startService() {
    setState(() {
      _startedAt = DateTime.now();
      _completed.clear();
    });
    unawaited(_saveActiveSession());
  }

  Future<void> _saveActiveSession() async {
    final startedAt = _startedAt;
    if (startedAt == null) {
      return;
    }
    await _repository.saveActiveSession(
      SundaySessionState(
        startedAt: startedAt,
        completedModules: Set.of(_completed),
      ),
    );
  }

  void _setComplete(SundayModule module, bool complete) {
    setState(() {
      if (complete) {
        _completed.add(module);
      } else {
        _completed.remove(module);
      }
    });
    unawaited(_saveActiveSession());
  }

  Future<void> _openModule(SundayModule module) async {
    if (_startedAt == null) {
      _startService();
    }
    final route = switch (module) {
      SundayModule.songs => AppRoutes.songs,
      SundayModule.familyPromise => AppRoutes.familyPromise,
      SundayModule.motto => AppRoutes.motto,
      SundayModule.offerings => AppRoutes.offerings,
      SundayModule.videos => AppRoutes.weeklyVideos,
      SundayModule.notices => AppRoutes.notices,
    };
    await Navigator.of(context).pushNamed(route);
    if (mounted) {
      setState(() => _completed.add(module));
      unawaited(_saveActiveSession());
    }
  }

  Future<void> _finishService(P0Strings text) async {
    final startedAt = _startedAt;
    if (startedAt == null) {
      return;
    }
    var withoutPaper = true;
    var withoutInterruptions = true;
    var rating = 5;
    final notes = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(text[P0Text.feedbackTitle]),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(text[P0Text.withoutPaperQuestion]),
                    value: withoutPaper,
                    onChanged: (value) =>
                        setDialogState(() => withoutPaper = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(text[P0Text.uninterruptedQuestion]),
                    value: withoutInterruptions,
                    onChanged: (value) =>
                        setDialogState(() => withoutInterruptions = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text(text[P0Text.ratingLabel])),
                      for (var value = 1; value <= 5; value++)
                        IconButton(
                          tooltip: '$value/5',
                          onPressed: () => setDialogState(() => rating = value),
                          icon: Icon(
                            value <= rating ? Icons.star : Icons.star_border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: text[P0Text.notesLabel],
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(text[P0Text.cancel]),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(text[P0Text.save]),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      notes.dispose();
      return;
    }

    final enabledCount = _plan.where((item) => item.enabled).length;
    final report = SundaySessionReport(
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      completedModules: _completed.length,
      totalModules: enabledCount,
      withoutPaper: withoutPaper,
      withoutInterruptions: withoutInterruptions,
      rating: rating,
      notes: notes.text.trim(),
    );
    notes.dispose();
    final reports = await _repository.addReport(report);
    await _repository.clearActiveSession();
    if (mounted) {
      setState(() {
        _reports = reports;
        _startedAt = null;
        _completed.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageScope.watch(context).language;
    final text = P0Strings.of(language);
    final strings = AppStrings.of(language);
    final enabledItems = _plan.where((item) => item.enabled).toList();
    final active = _startedAt != null;
    final visibleItems = active ? enabledItems : _plan;
    final progress = enabledItems.isEmpty
        ? 0.0
        : (_completed.length / enabledItems.length).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(text[P0Text.sundayMode]),
        actions: [
          if (PresentationMode.isSupported)
            IconButton(
              tooltip: text[P0Text.fullscreen],
              onPressed: PresentationMode.toggle,
              icon: const Icon(Icons.fullscreen),
            ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: active
          ? _ActiveServiceBar(
              completed: _completed.length,
              total: enabledItems.length,
              progress: progress,
              finishLabel: text[P0Text.finish],
              progressLabel: _progressLabel(
                language,
                _completed.length,
                enabledItems.length,
              ),
              onFinish: () => _finishService(text),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, active ? 32 : 20),
                    children: [
                      _ModeHeader(
                        countryName: widget.country.name,
                        title: _startedAt == null
                            ? text[P0Text.prepare]
                            : text[P0Text.activeService],
                        subtitle: text[P0Text.sundayModeSubtitle],
                        isActive: _startedAt != null,
                        onStart: _startedAt == null ? _startService : null,
                        startLabel: _startServiceLabel(
                          language,
                          enabledItems.length,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _OfflinePreparationPanel(text: text),
                      const SizedBox(height: 22),
                      Text(
                        active
                            ? _activeSequenceLabel(language)
                            : text[P0Text.configureSequence],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: visibleItems.length,
                        onReorder: _reorder,
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          final planIndex = _plan.indexOf(item);
                          final complete = _completed.contains(item.module);
                          return Padding(
                            key: ValueKey(item.module),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SundayStepTile(
                              index: planIndex,
                              sequence: index + 1,
                              icon: _moduleIcon(item.module),
                              label: _moduleLabel(
                                item.module,
                                strings,
                                language,
                              ),
                              included: item.enabled,
                              complete: complete,
                              isActive: _startedAt != null,
                              openLabel: text[P0Text.open],
                              onIncludedChanged: _startedAt == null
                                  ? (value) => _toggleIncluded(planIndex, value)
                                  : null,
                              onCompleteChanged:
                                  item.enabled && _startedAt != null
                                  ? (value) => _setComplete(item.module, value)
                                  : null,
                              onOpen: item.enabled
                                  ? () => _openModule(item.module)
                                  : null,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      _ValidationSummary(reports: _reports, text: text),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

IconData _moduleIcon(SundayModule module) {
  return switch (module) {
    SundayModule.songs => Icons.library_music_outlined,
    SundayModule.familyPromise => Icons.church_outlined,
    SundayModule.motto => Icons.auto_stories_outlined,
    SundayModule.offerings => Icons.volunteer_activism_outlined,
    SundayModule.videos => Icons.ondemand_video_outlined,
    SundayModule.notices => Icons.campaign_outlined,
  };
}

String _moduleLabel(
  SundayModule module,
  AppStrings strings,
  AppLanguage language,
) {
  return switch (module) {
    SundayModule.songs => strings.songs,
    SundayModule.familyPromise => strings.familyPromise,
    SundayModule.motto => strings.motto,
    SundayModule.offerings => strings.offerings,
    SundayModule.videos => strings.weeklyVideos,
    SundayModule.notices => CommunityNoticeCopy.of(language).title,
  };
}

class _ModeHeader extends StatelessWidget {
  const _ModeHeader({
    required this.countryName,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.onStart,
    required this.startLabel,
  });

  final String countryName;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback? onStart;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = Row(
          children: [
            Icon(
              isActive ? Icons.play_circle_outline : Icons.event_available,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('$countryName · $subtitle'),
                ],
              ),
            ),
          ],
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: constraints.maxWidth < 650
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      if (onStart != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(startLabel),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: heading),
                      if (onStart != null) ...[
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(startLabel),
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _SundayStepTile extends StatelessWidget {
  const _SundayStepTile({
    required this.index,
    required this.sequence,
    required this.icon,
    required this.label,
    required this.included,
    required this.complete,
    required this.isActive,
    required this.openLabel,
    required this.onIncludedChanged,
    required this.onCompleteChanged,
    required this.onOpen,
  });

  final int index;
  final int sequence;
  final IconData icon;
  final String label;
  final bool included;
  final bool complete;
  final bool isActive;
  final String openLabel;
  final ValueChanged<bool>? onIncludedChanged;
  final ValueChanged<bool>? onCompleteChanged;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: included
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        leading: isActive
            ? Checkbox(
                value: complete,
                onChanged: onCompleteChanged == null
                    ? null
                    : (value) => onCompleteChanged!(value ?? false),
              )
            : Switch(value: included, onChanged: onIncludedChanged),
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$sequence',
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MediaQuery.sizeOf(context).width >= 620)
              FilledButton.tonalIcon(
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward, size: 18),
                iconAlignment: IconAlignment.end,
                label: Text(openLabel),
              )
            else
              IconButton.filledTonal(
                tooltip: openLabel,
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward, size: 18),
              ),
            if (!isActive)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.drag_handle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveServiceBar extends StatelessWidget {
  const _ActiveServiceBar({
    required this.completed,
    required this.total,
    required this.progress,
    required this.progressLabel,
    required this.finishLabel,
    required this.onFinish,
  });

  final int completed;
  final int total;
  final double progress;
  final String progressLabel;
  final String finishLabel;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: AppColors.forest.withValues(alpha: 0.16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final status = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        progressLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                  final button = FilledButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(finishLabel),
                  );
                  if (constraints.maxWidth < 560) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [status, const SizedBox(height: 10), button],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: status),
                      const SizedBox(width: 20),
                      button,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _startServiceLabel(AppLanguage language, int count) =>
    switch (language) {
      AppLanguage.portuguese ||
      AppLanguage.brazilian => 'Começar serviço com $count módulos',
      AppLanguage.spanish => 'Comenzar servicio con $count módulos',
      AppLanguage.german => 'Gottesdienst mit $count Modulen starten',
      AppLanguage.italian => 'Inizia il servizio con $count moduli',
      AppLanguage.french => 'Commencer le service avec $count modules',
      AppLanguage.korean => '$count개 순서로 예배 시작',
      AppLanguage.english => 'Start service with $count modules',
    };

String _progressLabel(AppLanguage language, int completed, int total) =>
    switch (language) {
      AppLanguage.portuguese ||
      AppLanguage.brazilian => '$completed de $total concluídos',
      AppLanguage.spanish => '$completed de $total completados',
      AppLanguage.german => '$completed von $total abgeschlossen',
      AppLanguage.italian => '$completed di $total completati',
      AppLanguage.french => '$completed sur $total terminés',
      AppLanguage.korean => '$total개 중 $completed개 완료',
      AppLanguage.english => '$completed of $total completed',
    };

String _activeSequenceLabel(AppLanguage language) => switch (language) {
  AppLanguage.portuguese ||
  AppLanguage.brazilian => 'Siga o roteiro e marque cada módulo concluído.',
  AppLanguage.spanish => 'Siga la guía y marque cada módulo completado.',
  AppLanguage.german =>
    'Folgen Sie dem Ablauf und markieren Sie jeden Schritt.',
  AppLanguage.italian => 'Segui la guida e segna ogni modulo completato.',
  AppLanguage.french =>
    'Suivez le déroulement et marquez chaque module terminé.',
  AppLanguage.korean => '순서에 따라 완료된 항목을 표시하세요.',
  AppLanguage.english => 'Follow the guide and mark each completed module.',
};

class _OfflinePreparationPanel extends StatelessWidget {
  const _OfflinePreparationPanel({required this.text});

  final P0Strings text;

  @override
  Widget build(BuildContext context) {
    final cache = OfflineAudioCache();
    return StreamBuilder<OfflineAudioCacheProgress>(
      stream: cache.progress,
      initialData: cache.currentProgress,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? OfflineAudioCacheProgress.idle;
        final ready = progress.status == OfflineAudioCacheStatus.ready;
        final partial = progress.status == OfflineAudioCacheStatus.partial;
        final available = progress.status == OfflineAudioCacheStatus.available;
        final label = ready
            ? text[P0Text.offlineReady]
            : partial
            ? text[P0Text.offlinePartial]
            : available
            ? text[P0Text.offlineAvailable]
            : text[P0Text.offlinePreparing];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: partial
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  ready
                      ? Icons.offline_pin_outlined
                      : partial
                      ? Icons.cloud_off_outlined
                      : available
                      ? Icons.download_for_offline_outlined
                      : Icons.downloading_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text[P0Text.offlineTitle],
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(label),
                      Text(
                        text[P0Text.internetVideo],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (available)
                  IconButton.filledTonal(
                    tooltip: text[P0Text.downloadOffline],
                    onPressed: cache.downloadAvailable,
                    icon: const Icon(Icons.download_outlined),
                  )
                else if (partial)
                  IconButton.filledTonal(
                    tooltip: text[P0Text.retry],
                    onPressed: cache.retry,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ValidationSummary extends StatelessWidget {
  const _ValidationSummary({required this.reports, required this.text});

  final List<SundaySessionReport> reports;
  final P0Strings text;

  @override
  Widget build(BuildContext context) {
    final validated = reports.take(3).toList();
    final noPaper = validated.where((report) => report.withoutPaper).length;
    final uninterrupted = validated
        .where((report) => report.withoutInterruptions)
        .length;
    final average = validated.isEmpty
        ? 0.0
        : validated.fold<int>(0, (sum, report) => sum + report.rating) /
              validated.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text[P0Text.validationTitle],
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(text[P0Text.validationSubtitle]),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (validated.length / 3).clamp(0, 1),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text('${validated.length}/3 ${text[P0Text.reportsProgress]}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Metric(
              label: text[P0Text.noPaperMetric],
              value: '$noPaper/${validated.length}',
            ),
            _Metric(
              label: text[P0Text.noInterruptionsMetric],
              value: '$uninterrupted/${validated.length}',
            ),
            _Metric(
              label: text[P0Text.averageRating],
              value: validated.isEmpty
                  ? '—'
                  : '${average.toStringAsFixed(1)}/5',
            ),
          ],
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
