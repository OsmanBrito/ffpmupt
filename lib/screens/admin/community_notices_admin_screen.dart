import 'dart:async';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:ffpmupt/models/community_notice.dart';
import 'package:ffpmupt/screens/community_notices_screen.dart';
import 'package:ffpmupt/services/community_notice_image_upload_service.dart';
import 'package:ffpmupt/services/community_notice_repository.dart';
import 'package:ffpmupt/settings/admin_copy.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:file_picker/file_picker.dart';
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
  static const _maxImageBytes = CommunityNoticeImageUploadService.maxImageBytes;
  static const _allowedImageExtensions =
      CommunityNoticeImageUploadService.allowedExtensions;

  final _formKey = GlobalKey<FormState>();
  final _imageUploadService = CommunityNoticeImageUploadService();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _date;
  late final TextEditingController _location;
  late final TextEditingController _linkUrl;
  late final TextEditingController _imageUrl;
  late final TextEditingController _languageCode;
  late final TextEditingController _sortOrder;
  late NoticeCategory _category;
  late bool _enabled;
  late bool _pinned;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _saveStatus;

  @override
  void initState() {
    super.initState();
    final notice = widget.notice;
    _title = TextEditingController(text: notice?.title ?? '');
    _body = TextEditingController(text: notice?.body ?? '');
    _date = TextEditingController(text: notice?.date ?? '');
    _location = TextEditingController(text: notice?.location ?? '');
    _linkUrl = TextEditingController(text: notice?.linkUrl ?? '');
    _imageUrl = TextEditingController(text: notice?.imageUrl ?? '');
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
      _imageUrl,
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

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final file = result.files.single;
    final extension = (file.extension ?? '').toLowerCase();
    if (!_allowedImageExtensions.contains(extension)) {
      _showMessage(adminText(context, 'Use uma imagem JPG, PNG ou WebP.'));
      return;
    }
    if (file.size > _maxImageBytes) {
      _showMessage(adminText(context, 'A imagem deve ter no máximo 5 MB.'));
      return;
    }
    if (file.bytes == null || file.bytes!.isEmpty) {
      _showMessage(
        adminText(context, 'Não foi possível ler a imagem selecionada.'),
      );
      return;
    }

    setState(() {
      _selectedImageBytes = file.bytes;
      _selectedImageName = file.name;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _imageUrl.clear();
    });
  }

  Future<void> _cropImage() async {
    final imageBytes = _selectedImageBytes;
    final imageName = _selectedImageName;
    if (imageBytes == null || imageName == null) {
      return;
    }

    final croppedBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (context) => NoticeImageCropScreen(imageBytes: imageBytes),
      ),
    );
    if (croppedBytes == null || !mounted) {
      return;
    }
    if (croppedBytes.length > _maxImageBytes) {
      _showMessage(
        adminText(
          context,
          'A imagem cortada ultrapassou 5 MB. Tente um corte menor.',
        ),
      );
      return;
    }

    setState(() {
      _selectedImageBytes = croppedBytes;
      _selectedImageName = _croppedImageName(imageName, croppedBytes);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    setState(() {
      _isSaving = true;
      _saveStatus = _selectedImageBytes != null
          ? adminText(context, 'Enviando imagem...')
          : adminText(context, 'Guardando dados...');
    });
    try {
      var imageUrl = _imageUrl.text.trim();
      final imageBytes = _selectedImageBytes;
      final imageName = _selectedImageName;
      if (imageBytes != null && imageName != null) {
        imageUrl = await _imageUploadService.upload(
          bytes: imageBytes,
          fileName: imageName,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _imageUrl.text = imageUrl;
          _selectedImageBytes = null;
          _selectedImageName = null;
          _saveStatus = adminText(context, 'Guardando dados...');
        });
      }

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
          imageUrl: imageUrl,
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
        _showMessage(
          '${adminText(context, 'Não foi possível guardar')}: $error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveStatus = null;
        });
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
                  _NoticeImagePickerPanel(
                    selectedBytes: _selectedImageBytes,
                    currentUrl: _imageUrl.text.trim(),
                    fileName: _selectedImageName,
                    isEnabled: !_isSaving,
                    onPick: _pickImage,
                    onCrop: _selectedImageBytes != null ? _cropImage : null,
                    onRemove:
                        _selectedImageBytes != null ||
                            _imageUrl.text.trim().isNotEmpty
                        ? _removeImage
                        : null,
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
                    label: Text(_saveStatus ?? adminText(context, 'Guardar')),
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

class _NoticeImagePickerPanel extends StatelessWidget {
  const _NoticeImagePickerPanel({
    required this.selectedBytes,
    required this.currentUrl,
    required this.fileName,
    required this.isEnabled,
    required this.onPick,
    required this.onCrop,
    required this.onRemove,
  });

  final Uint8List? selectedBytes;
  final String currentUrl;
  final String? fileName;
  final bool isEnabled;
  final VoidCallback onPick;
  final VoidCallback? onCrop;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final image = selectedBytes != null
        ? Image.memory(
            selectedBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _NoticeImageFallback(),
          )
        : currentUrl.isNotEmpty
        ? Image.network(
            currentUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _NoticeImageFallback(),
          )
        : const _NoticeImageFallback();

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              adminText(context, 'Imagem do aviso (opcional)'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AspectRatio(aspectRatio: 16 / 9, child: image),
            ),
            if (fileName != null) ...[
              const SizedBox(height: 8),
              Text(fileName!, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isEnabled ? onPick : null,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(adminText(context, 'Selecionar imagem')),
                ),
                if (onCrop != null)
                  OutlinedButton.icon(
                    onPressed: isEnabled ? onCrop : null,
                    icon: const Icon(Icons.crop_outlined),
                    label: Text(adminText(context, 'Cortar imagem')),
                  ),
                if (onRemove != null)
                  TextButton.icon(
                    onPressed: isEnabled ? onRemove : null,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(adminText(context, 'Remover imagem')),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              adminText(context, 'JPG, PNG ou WebP · máximo 5 MB'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class NoticeImageCropScreen extends StatefulWidget {
  const NoticeImageCropScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<NoticeImageCropScreen> createState() => _NoticeImageCropScreenState();
}

class _NoticeImageCropScreenState extends State<NoticeImageCropScreen> {
  final _controller = CropController();
  bool _isReady = false;
  bool _isCropping = false;
  String? _error;

  void _applyCrop() {
    if (!_isReady || _isCropping) {
      return;
    }
    setState(() {
      _isCropping = true;
      _error = null;
    });
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) {
      return;
    }
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure():
        setState(() {
          _isCropping = false;
          _error = adminText(
            context,
            'Não foi possível cortar a imagem. Tente novamente.',
          );
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(adminText(context, 'Cortar imagem')),
        leading: IconButton(
          tooltip: adminText(context, 'Cancelar'),
          onPressed: _isCropping ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Text(
                adminText(
                  context,
                  'Arraste para reposicionar e use o gesto de pinça ou a roda do rato para ampliar.',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Crop(
                    image: widget.imageBytes,
                    controller: _controller,
                    aspectRatio: 16 / 9,
                    initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                      size: 1,
                      aspectRatio: 16 / 9,
                    ),
                    interactive: true,
                    fixCropRect: true,
                    maskColor: Colors.black.withValues(alpha: 0.7),
                    baseColor: Colors.black,
                    radius: 8,
                    filterQuality: FilterQuality.high,
                    progressIndicator: const Center(
                      child: CircularProgressIndicator(),
                    ),
                    onStatusChanged: (status) {
                      if (!mounted) {
                        return;
                      }
                      final ready = status == CropStatus.ready;
                      if (_isReady != ready) {
                        setState(() => _isReady = ready);
                      }
                    },
                    onCropped: _onCropped,
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCropping
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(adminText(context, 'Cancelar')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isReady && !_isCropping ? _applyCrop : null,
                      icon: _isCropping
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.crop_outlined),
                      label: Text(adminText(context, 'Aplicar corte')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _croppedImageName(String originalName, Uint8List bytes) {
  final baseName = originalName.contains('.')
      ? originalName.substring(0, originalName.lastIndexOf('.'))
      : originalName;
  final isJpeg =
      bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff;
  return '${baseName}_cortada.${isJpeg ? 'jpg' : 'png'}';
}

class _NoticeImageFallback extends StatelessWidget {
  const _NoticeImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
