import 'dart:async';
import 'dart:typed_data';

import 'package:ffpmupt/models/holy_ground.dart';
import 'package:ffpmupt/services/holy_ground_image_upload_service.dart';
import 'package:ffpmupt/services/holy_ground_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class HolyGroundsAdminScreen extends StatefulWidget {
  const HolyGroundsAdminScreen({
    super.key,
    required this.countryCode,
    required this.defaultLanguage,
  });

  final String countryCode;
  final String defaultLanguage;

  @override
  State<HolyGroundsAdminScreen> createState() => _HolyGroundsAdminScreenState();
}

class _HolyGroundsAdminScreenState extends State<HolyGroundsAdminScreen> {
  late final HolyGroundRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = HolyGroundRepository();
  }

  Future<void> _openEditor([HolyGround? ground]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HolyGroundEditorScreen(
          countryCode: widget.countryCode,
          defaultLanguage: widget.defaultLanguage,
          ground: ground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Holy Grounds'),
        actions: [
          IconButton(
            tooltip: 'Adicionar Holy Ground',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: StreamBuilder<List<HolyGround>>(
              stream: _repository.watchAdmin(widget.countryCode),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Não foi possível carregar os Holy Grounds.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final grounds = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${grounds.length} locais cadastrados',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _openEditor(),
                            icon: const Icon(Icons.add),
                            label: const Text('Novo local'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: grounds.isEmpty
                          ? const Center(
                              child: Text('Nenhum Holy Ground cadastrado.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: grounds.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final ground = grounds[index];
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.landscape_outlined,
                                      size: 32,
                                    ),
                                    title: Text(
                                      ground.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [
                                            ground.city,
                                            ground.languageCode.toUpperCase(),
                                          ]
                                          .where((value) => value.isNotEmpty)
                                          .join(' · '),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: ground.enabled,
                                          onChanged: (enabled) => unawaited(
                                            _repository.setEnabled(
                                              ground,
                                              enabled,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Editar',
                                          onPressed: () => _openEditor(ground),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _openEditor(ground),
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

class HolyGroundEditorScreen extends StatefulWidget {
  const HolyGroundEditorScreen({
    super.key,
    required this.countryCode,
    required this.defaultLanguage,
    this.ground,
  });

  final String countryCode;
  final String defaultLanguage;
  final HolyGround? ground;

  @override
  State<HolyGroundEditorScreen> createState() => _HolyGroundEditorScreenState();
}

class _HolyGroundEditorScreenState extends State<HolyGroundEditorScreen> {
  static const _maxImageBytes = 5 * 1024 * 1024;
  static const _allowedImageExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  final _formKey = GlobalKey<FormState>();
  final _repository = HolyGroundRepository();
  final _imageUploadService = HolyGroundImageUploadService();
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _imageUrl;
  late final TextEditingController _summary;
  late final TextEditingController _history;
  late final TextEditingController _visitInstructions;
  late final TextEditingController _contactName;
  late final TextEditingController _contactEmail;
  late final TextEditingController _languageCode;
  late final TextEditingController _sortOrder;
  late bool _enabled;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _saveStatus;

  @override
  void initState() {
    super.initState();
    final ground = widget.ground;
    _name = TextEditingController(text: ground?.name ?? '');
    _city = TextEditingController(text: ground?.city ?? '');
    _address = TextEditingController(text: ground?.address ?? '');
    _latitude = TextEditingController(text: ground?.latitude?.toString() ?? '');
    _longitude = TextEditingController(
      text: ground?.longitude?.toString() ?? '',
    );
    _imageUrl = TextEditingController(text: ground?.imageUrl ?? '');
    _summary = TextEditingController(text: ground?.summary ?? '');
    _history = TextEditingController(text: ground?.history ?? '');
    _visitInstructions = TextEditingController(
      text: ground?.visitInstructions ?? '',
    );
    _contactName = TextEditingController(text: ground?.contactName ?? '');
    _contactEmail = TextEditingController(text: ground?.contactEmail ?? '');
    _languageCode = TextEditingController(
      text: ground?.languageCode ?? widget.defaultLanguage,
    );
    _sortOrder = TextEditingController(
      text: (ground?.sortOrder ?? 0).toString(),
    );
    _enabled = ground?.enabled ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _city,
      _address,
      _latitude,
      _longitude,
      _imageUrl,
      _summary,
      _history,
      _visitInstructions,
      _contactName,
      _contactEmail,
      _languageCode,
      _sortOrder,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  }

  String? _coordinate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value.trim().replaceAll(',', '.')) == null
        ? 'Coordenada inválida'
        : null;
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
      _showMessage('Use uma imagem JPG, PNG ou WebP.');
      return;
    }
    if (file.size > _maxImageBytes) {
      _showMessage('A fotografia deve ter no máximo 5 MB.');
      return;
    }
    if (file.bytes == null || file.bytes!.isEmpty) {
      _showMessage('Não foi possível ler a fotografia selecionada.');
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final latitude = double.tryParse(
      _latitude.text.trim().replaceAll(',', '.'),
    );
    final longitude = double.tryParse(
      _longitude.text.trim().replaceAll(',', '.'),
    );
    if ((latitude == null) != (longitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha latitude e longitude juntas.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _saveStatus = _selectedImageBytes == null
          ? 'Guardando dados...'
          : 'Enviando fotografia...';
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
          _saveStatus = 'Guardando dados...';
        });
      }

      await _repository.save(
        HolyGround(
          id: widget.ground?.id ?? '',
          countryCode: widget.countryCode,
          name: _name.text.trim(),
          city: _city.text.trim(),
          address: _address.text.trim(),
          latitude: latitude,
          longitude: longitude,
          imageUrl: imageUrl,
          summary: _summary.text.trim(),
          history: _history.text.trim(),
          visitInstructions: _visitInstructions.text.trim(),
          contactName: _contactName.text.trim(),
          contactEmail: _contactEmail.text.trim(),
          languageCode: _languageCode.text.trim().toLowerCase(),
          enabled: _enabled,
          sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('Não foi possível guardar: $error');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.ground == null ? 'Novo Holy Ground' : 'Editar Holy Ground',
        ),
        actions: [
          IconButton(
            tooltip: 'Guardar',
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
                  Text(
                    'Identificação',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _name,
                    label: 'Nome',
                    validator: _required,
                  ),
                  _Field(
                    controller: _city,
                    label: 'Cidade',
                    validator: _required,
                  ),
                  _Field(
                    controller: _address,
                    label: 'Endereço completo',
                    validator: _required,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _latitude,
                          label: 'Latitude (opcional)',
                          validator: _coordinate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          controller: _longitude,
                          label: 'Longitude (opcional)',
                          validator: _coordinate,
                        ),
                      ),
                    ],
                  ),
                  _ImagePickerPanel(
                    selectedBytes: _selectedImageBytes,
                    currentUrl: _imageUrl.text.trim(),
                    fileName: _selectedImageName,
                    isEnabled: !_isSaving,
                    onPick: _pickImage,
                    onRemove:
                        _selectedImageBytes != null ||
                            _imageUrl.text.trim().isNotEmpty
                        ? _removeImage
                        : null,
                  ),
                  const Divider(height: 34),
                  Text(
                    'Conteúdo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    controller: _summary,
                    label: 'Resumo',
                    validator: _required,
                    minLines: 2,
                    maxLines: 5,
                  ),
                  _Field(
                    controller: _history,
                    label: 'História',
                    minLines: 4,
                    maxLines: 12,
                  ),
                  _Field(
                    controller: _visitInstructions,
                    label: 'Instruções de visita',
                    minLines: 3,
                    maxLines: 8,
                  ),
                  const Divider(height: 34),
                  Text(
                    'Contato e publicação',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _Field(controller: _contactName, label: 'Responsável'),
                  _Field(controller: _contactEmail, label: 'Email de contato'),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _languageCode,
                          label: 'Idioma',
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(controller: _sortOrder, label: 'Ordem'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Local visível no diretório'),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saveStatus ?? 'Guardar Holy Ground'),
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

class _ImagePickerPanel extends StatelessWidget {
  const _ImagePickerPanel({
    required this.selectedBytes,
    required this.currentUrl,
    required this.fileName,
    required this.isEnabled,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? selectedBytes;
  final String currentUrl;
  final String? fileName;
  final bool isEnabled;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final image = selectedBytes != null
        ? Image.memory(
            selectedBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _ImageFallback(),
          )
        : currentUrl.isNotEmpty
        ? Image.network(
            currentUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _ImageFallback(),
          )
        : const _ImageFallback();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Fotografia',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 16 / 7,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: image,
                ),
              ),
              if (fileName != null) ...[
                const SizedBox(height: 8),
                Text(fileName!, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: isEnabled ? onPick : null,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      selectedBytes == null && currentUrl.isEmpty
                          ? 'Selecionar fotografia'
                          : 'Trocar fotografia',
                    ),
                  ),
                  if (onRemove != null)
                    TextButton.icon(
                      onPressed: isEnabled ? onRemove : null,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remover'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'JPG, PNG ou WebP, até 5 MB.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.add_photo_alternate_outlined, size: 52),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
