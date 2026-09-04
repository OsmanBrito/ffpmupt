import 'dart:async';

import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/sunday_mode.dart';
import 'package:ffpmupt/screens/community_notices_screen.dart';
import 'package:ffpmupt/screens/family_promise_screen.dart';
import 'package:ffpmupt/screens/list_of_songs_screen.dart';
import 'package:ffpmupt/screens/motto_screen.dart';
import 'package:ffpmupt/screens/offering_screen.dart';
import 'package:ffpmupt/screens/videos_screen.dart';
import 'package:ffpmupt/services/offline_audio_cache.dart';
import 'package:ffpmupt/services/sunday_mode_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/p0_strings.dart';
import 'package:ffpmupt/settings/presentation_mode.dart';
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
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _plan = results[0] as List<SundayPlanItem>;
      _reports = results[1] as List<SundaySessionReport>;
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
  }

  Future<void> _openModule(SundayModule module) async {
    if (_startedAt == null) {
      _startService();
    }
    final screen = switch (module) {
      SundayModule.songs => ListOfSongsScreen(countryCode: widget.country.code),
      SundayModule.familyPromise => FamilyPromiseScreen(
        country: widget.country,
      ),
      SundayModule.motto => MottoScreen(countryCode: widget.country.code),
      SundayModule.offerings => OfferingScreen(
        countryCode: widget.country.code,
      ),
      SundayModule.videos => VideosScreen(countryCode: widget.country.code),
      SundayModule.notices => CommunityNoticesScreen(
        countryCode: widget.country.code,
      ),
    };
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => screen));
    if (mounted) {
      setState(() => _completed.add(module));
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _ModeHeader(
                        countryName: widget.country.name,
                        title: _startedAt == null
                            ? text[P0Text.prepare]
                            : text[P0Text.activeService],
                        subtitle: text[P0Text.sundayModeSubtitle],
                        isActive: _startedAt != null,
                        onStart: _startedAt == null ? _startService : null,
                        startLabel: text[P0Text.startSunday],
                      ),
                      const SizedBox(height: 16),
                      _OfflinePreparationPanel(text: text),
                      const SizedBox(height: 22),
                      Text(
                        text[P0Text.configureSequence],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: _plan.length,
                        onReorder: _reorder,
                        itemBuilder: (context, index) {
                          final item = _plan[index];
                          final complete = _completed.contains(item.module);
                          return Padding(
                            key: ValueKey(item.module),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SundayStepTile(
                              index: index,
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
                                  ? (value) => _toggleIncluded(index, value)
                                  : null,
                              onCompleteChanged:
                                  item.enabled && _startedAt != null
                                  ? (value) => setState(() {
                                      if (value) {
                                        _completed.add(item.module);
                                      } else {
                                        _completed.remove(item.module);
                                      }
                                    })
                                  : null,
                              onOpen: item.enabled
                                  ? () => _openModule(item.module)
                                  : null,
                            ),
                          );
                        },
                      ),
                      if (_startedAt != null) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: enabledItems.isEmpty
                              ? 0
                              : _completed.length / enabledItems.length,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () => _finishService(text),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(text[P0Text.finish]),
                        ),
                      ],
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
            IconButton.filledTonal(
              tooltip: openLabel,
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 18),
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
