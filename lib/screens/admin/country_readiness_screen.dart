import 'dart:async';

import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/country_readiness.dart';
import 'package:ffpmupt/services/country_readiness_repository.dart';
import 'package:ffpmupt/services/offline_audio_cache.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/p0_strings.dart';
import 'package:flutter/material.dart';

class CountryReadinessScreen extends StatefulWidget {
  const CountryReadinessScreen({super.key, required this.country});

  final CountryModel country;

  @override
  State<CountryReadinessScreen> createState() => _CountryReadinessScreenState();
}

class _CountryReadinessScreenState extends State<CountryReadinessScreen> {
  final _repository = CountryReadinessRepository();
  CountryReadiness? _readiness;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final readiness = await _repository.load(
        country: widget.country,
        hasAdminAccess: true,
      );
      if (mounted) {
        setState(() => _readiness = readiness);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = P0Strings.of(AppLanguageScope.watch(context).language);
    return Scaffold(
      appBar: AppBar(
        title: Text(text[P0Text.checklistTitle]),
        actions: [
          IconButton(
            tooltip: text[P0Text.refresh],
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null || _readiness == null
                ? _LoadError(text: text, onRetry: _load)
                : _ReadinessContent(
                    country: widget.country,
                    readiness: _readiness!,
                    text: text,
                    onRetryOffline: () {
                      OfflineAudioCache().retry();
                      unawaited(_load());
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _ReadinessContent extends StatelessWidget {
  const _ReadinessContent({
    required this.country,
    required this.readiness,
    required this.text,
    required this.onRetryOffline,
  });

  final CountryModel country;
  final CountryReadiness readiness;
  final P0Strings text;
  final VoidCallback onRetryOffline;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          country.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(text[P0Text.checklistSubtitle]),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: readiness.progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 14),
            Text('${readiness.completed}/${readiness.total}'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          readiness.isReady ? text[P0Text.ready] : text[P0Text.needsAttention],
          style: TextStyle(
            color: readiness.isReady
                ? const Color(0xff2f6b4f)
                : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        for (final check in readiness.checks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(
                  check.ready
                      ? Icons.check_circle_outline
                      : check.required
                      ? Icons.error_outline
                      : Icons.info_outline,
                  color: check.ready
                      ? const Color(0xff2f6b4f)
                      : check.required
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                  [
                    _areaLabel(check.area, text),
                    if (!check.required) '(${text[P0Text.optional]})',
                  ].join(' '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: check.detail.isEmpty ? null : Text(check.detail),
                trailing: check.area == ReadinessArea.offline && !check.ready
                    ? IconButton(
                        tooltip: text[P0Text.retry],
                        onPressed: onRetryOffline,
                        icon: const Icon(Icons.refresh),
                      )
                    : null,
              ),
            ),
          ),
        const SizedBox(height: 18),
        Text(
          text[P0Text.issues],
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (readiness.issues.isEmpty)
          Text(text[P0Text.noIssues])
        else
          for (final issue in readiness.issues)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text(_areaLabel(issue.area, text)),
              subtitle: Text(issue.subject),
            ),
      ],
    );
  }
}

String _areaLabel(ReadinessArea area, P0Strings text) {
  return switch (area) {
    ReadinessArea.country => text[P0Text.countryActive],
    ReadinessArea.admin => text[P0Text.adminAccess],
    ReadinessArea.songs => text[P0Text.songs],
    ReadinessArea.promise => text[P0Text.promise],
    ReadinessArea.payments => text[P0Text.payments],
    ReadinessArea.videos => text[P0Text.videos],
    ReadinessArea.holyGrounds => text[P0Text.holyGrounds],
    ReadinessArea.offline => text[P0Text.offline],
  };
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.text, required this.onRetry});

  final P0Strings text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(text[P0Text.loadFailed]),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(text[P0Text.tryAgain]),
          ),
        ],
      ),
    );
  }
}
