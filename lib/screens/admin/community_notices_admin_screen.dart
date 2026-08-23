import 'dart:async';

import 'package:ffpmupt/models/community_notice.dart';
import 'package:ffpmupt/screens/community_notices_screen.dart';
import 'package:ffpmupt/services/community_notice_repository.dart';
import 'package:ffpmupt/settings/admin_copy.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:flutter/material.dart';

class CommunityNoticesAdminScreen extends StatefulWidget {
  const CommunityNoticesAdminScreen({
    super.key,
    required this.countryCode,
    required this.defaultLanguage,
  });

  final String countryCode;
  final String defaultLanguage;

  @override
  State<CommunityNoticesAdminScreen> createState() =>
      _CommunityNoticesAdminScreenState();
}

class _CommunityNoticesAdminScreenState
    extends State<CommunityNoticesAdminScreen> {
  late final CommunityNoticeRepository _repository;
  final Set<String> _updatingIds = {};

  @override
  void initState() {
    super.initState();
    _repository = CommunityNoticeRepository(countryCode: widget.countryCode);
  }

  Future<void> _openEditor([CommunityNotice? notice]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityNoticeEditorScreen(
          repository: _repository,
          countryCode: widget.countryCode,
          defaultLanguage: widget.defaultLanguage,
          notice: notice,
        ),
      ),
    );
  }

  Future<void> _setEnabled(CommunityNotice notice, bool enabled) async {
    setState(() => _updatingIds.add(notice.id));
    try {
      await _repository.setEnabled(notice, enabled);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminText(context, 'Não foi possível alterar a publicação.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingIds.remove(notice.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = CommunityNoticeCopy.of(
      AppLanguageScope.watch(context).language,
    );
    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: StreamBuilder<List<CommunityNotice>>(
              stream: _repository.watchAdmin(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(copy.loadFailed));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notices = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${notices.length} · ${copy.title}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _openEditor(),
                            icon: const Icon(Icons.add),
                            label: Text(adminText(context, 'Novo aviso')),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: notices.isEmpty
                          ? Center(child: Text(copy.empty))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: notices.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final notice = notices[index];
                                final updating = _updatingIds.contains(
                                  notice.id,
                                );
                                return Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    leading: Icon(
                                      noticeCategoryIcon(notice.category),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notice.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        if (notice.pinned)
                                          const Icon(
                                            Icons.push_pin_outlined,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      [
                                        copy.categoryLabel(notice.category),
                                        if (notice.date.isNotEmpty) notice.date,
                                        adminText(
                                          context,
                                          notice.enabled
                                              ? 'Publicado'
                                              : 'Oculto',
                                        ),
                                      ].join(' · '),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (updating)
                                          const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox.square(
                                              dimension: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        else
                                          Switch(
                                            value: notice.enabled,
                                            onChanged: (enabled) => unawaited(
                                              _setEnabled(notice, enabled),
                                            ),
                                          ),
                                        IconButton(
                                          tooltip: adminText(context, 'Editar'),
                                          onPressed: () => _openEditor(notice),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _openEditor(notice),
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

class CommunityNoticeEditorScreen extends StatefulWidget {
  const CommunityNoticeEditorScreen({
    super.key,
    required this.repository,
    required this.countryCode,
    required this.defaultLanguage,
    this.notice,
  });

  final CommunityNoticeRepository repository;
  final String countryCode;
  final String defaultLanguage;
  final CommunityNotice? notice;

  @override
  State<CommunityNoticeEditorScreen> createState() =>
      _CommunityNoticeEditorScreenState();
}

class _CommunityNoticeEditorScreenState
    extends State<CommunityNoticeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _date;
  late final TextEditingController _location;
  late final TextEditingController _linkUrl;
  late final TextEditingController _languageCode;
  late final TextEditingController _sortOrder;
  late NoticeCategory _category;
  late bool _enabled;
  late bool _pinned;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final notice = widget.notice;
    _title = TextEditingController(text: notice?.title ?? '');
    _body = TextEditingController(text: notice?.body ?? '');
    _date = TextEditingController(text: notice?.date ?? '');
    _location = TextEditingController(text: notice?.location ?? '');
    _linkUrl = TextEditingController(text: notice?.linkUrl ?? '');
    _languageCode = TextEditingController(
      text: notice?.languageCode ?? widget.defaultLanguage,
    );
    _sortOrder = TextEditingController(
      text: (notice?.sortOrder ?? 0).toString(),
    );
    _category = notice?.category ?? NoticeCategory.general;
    _enabled = notice?.enabled ?? true;
    _pinned = notice?.pinned ?? false;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _body,
      _date,
      _location,
      _linkUrl,
      _languageCode,
      _sortOrder,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? adminText(context, 'Campo obrigatório')
        : null;
  }

  String? _httpsUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? null
        : adminText(context, 'Use uma ligação HTTPS válida');
  }

  Future<void> _chooseDate() async {
    final initial = DateTime.tryParse(_date.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }
    _date.text =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.repository.save(
        CommunityNotice(
          id: widget.notice?.id ?? widget.repository.newId(),
          countryCode: widget.countryCode,
          title: _title.text.trim(),
          body: _body.text.trim(),
          category: _category,
          date: _date.text.trim(),
          location: _location.text.trim(),
          linkUrl: _linkUrl.text.trim(),
          languageCode: _languageCode.text.trim().toLowerCase(),
          enabled: _enabled,
          pinned: _pinned,
          sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${adminText(context, 'Não foi possível guardar')}: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = CommunityNoticeCopy.of(
      AppLanguageScope.watch(context).language,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminText(
            context,
            widget.notice == null ? 'Novo aviso' : 'Editar aviso',
          ),
        ),
        actions: [
          IconButton(
            tooltip: adminText(context, 'Guardar'),
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _title,
                    validator: _required,
                    maxLength: 160,
                    decoration: InputDecoration(
                      labelText: adminText(context, 'Título'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<NoticeCategory>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: adminText(context, 'Categoria'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final category in NoticeCategory.values)
                        DropdownMenuItem(
                          value: category,
                          child: Text(copy.categoryLabel(category)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _body,
                    validator: _required,
                    minLines: 6,
                    maxLines: 18,
                    maxLength: 10000,
                    decoration: InputDecoration(
                      labelText: adminText(context, 'Informação'),
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _date,
                    readOnly: true,
                    onTap: _chooseDate,
                    decoration: InputDecoration(
                      labelText: adminText(context, 'Data (opcional)'),
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_date.text.isNotEmpty)
                            IconButton(
                              tooltip: adminText(context, 'Limpar data'),
                              onPressed: () => setState(_date.clear),
                              icon: const Icon(Icons.clear),
                            ),
                          IconButton(
                            tooltip: adminText(context, 'Escolher data'),
                            onPressed: _chooseDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _location,
                    decoration: InputDecoration(
                      labelText: adminText(context, 'Local (opcional)'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _linkUrl,
                    validator: _httpsUrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: adminText(context, 'Ligação HTTPS (opcional)'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _languageCode,
                          decoration: InputDecoration(
                            labelText: adminText(context, 'Idioma'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sortOrder,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: adminText(context, 'Ordem'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(adminText(context, 'Fixar no topo')),
                    value: _pinned,
                    onChanged: (value) => setState(() => _pinned = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(adminText(context, 'Publicado')),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(adminText(context, 'Guardar')),
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
