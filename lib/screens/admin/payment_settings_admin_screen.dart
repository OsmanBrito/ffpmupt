import 'package:ffpmupt/models/payment_settings.dart';
import 'package:ffpmupt/services/payment_settings_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/admin_copy.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/material.dart';

class PaymentSettingsAdminScreen extends StatefulWidget {
  const PaymentSettingsAdminScreen({super.key, required this.countryCode});

  final String countryCode;

  @override
  State<PaymentSettingsAdminScreen> createState() =>
      _PaymentSettingsAdminScreenState();
}

class _PaymentSettingsAdminScreenState
    extends State<PaymentSettingsAdminScreen> {
  late final PaymentSettingsRepository _repository;
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _noteController = TextEditingController();
  final List<_PaymentMethodDraft> _methods = [];
  bool _enabled = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = PaymentSettingsRepository(countryCode: widget.countryCode);
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _noteController.dispose();
    for (final method in _methods) {
      method.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await _repository.loadForAdmin();
    if (!mounted) {
      return;
    }
    setState(() {
      _titleController.text = settings.title;
      _subtitleController.text = settings.subtitle;
      _noteController.text = settings.note;
      _enabled = settings.enabled;
      _methods.addAll(settings.methods.map(_PaymentMethodDraft.fromMethod));
      _isLoading = false;
    });
  }

  void _addMethod() {
    setState(() => _methods.add(_PaymentMethodDraft.empty(_methods.length)));
  }

  void _removeMethod(int index) {
    final method = _methods.removeAt(index);
    method.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _methods.any((method) => method.label.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(context, 'Preencha o título de todos os métodos.'),
          ),
        ),
      );
      return;
    }
    final invalidActiveMethod = _methods
        .where((method) => method.enabled)
        .any(
          (method) =>
              !method.details.any(
                (detail) =>
                    detail.label.text.trim().isNotEmpty &&
                    detail.value.text.trim().isNotEmpty,
              ) &&
              method.paymentUrl.text.trim().isEmpty &&
              method.qrContent.text.trim().isEmpty,
        );
    if (_enabled &&
        (_methods.where((method) => method.enabled).isEmpty ||
            invalidActiveMethod)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(
              context,
              'Cada método ativo precisa de dados, link ou QR Code.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final settings = PaymentSettings(
        enabled: _enabled,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        note: _noteController.text.trim(),
        methods: [
          for (var index = 0; index < _methods.length; index++)
            _methods[index].toMethod(index),
        ],
      );
      await _repository.save(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminText(context, 'Dados de pagamento guardados.')),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível guardar: $error')),
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
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.offerings),
        actions: [
          IconButton(
            tooltip: adminText(context, 'Guardar'),
            onPressed: _isLoading || _isSaving ? null : _save,
            icon: const Icon(Icons.save_outlined),
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
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        adminText(context, 'Página de ofertas'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: adminText(context, 'Título'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _subtitleController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: adminText(context, 'Texto introdutório'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: adminText(
                            context,
                            'Nota final (opcional)',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          adminText(context, 'Página de pagamentos ativa'),
                        ),
                        value: _enabled,
                        onChanged: (value) => setState(() => _enabled = value),
                      ),
                      const Divider(height: 36),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              adminText(context, 'Métodos de pagamento'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: adminText(context, 'Adicionar método'),
                            onPressed: _addMethod,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_methods.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            adminText(
                              context,
                              'Adicione IBAN, PIX, MB Way, link de pagamento ou outro método.',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (var index = 0; index < _methods.length; index++)
                        _PaymentMethodEditor(
                          key: ValueKey(_methods[index]),
                          index: index,
                          draft: _methods[index],
                          onRemove: () => _removeMethod(index),
                        ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(strings.save),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodDraft {
  _PaymentMethodDraft({
    required this.id,
    required this.type,
    required this.label,
    required this.description,
    required this.paymentUrl,
    required this.qrContent,
    required this.details,
    required this.enabled,
  });

  factory _PaymentMethodDraft.empty(int index) {
    return _PaymentMethodDraft(
      id: 'method-${DateTime.now().microsecondsSinceEpoch}-$index',
      type: PaymentMethodType.bankTransfer,
      label: TextEditingController(),
      description: TextEditingController(),
      paymentUrl: TextEditingController(),
      qrContent: TextEditingController(),
      details: [_PaymentDetailDraft.empty()],
      enabled: true,
    );
  }

  factory _PaymentMethodDraft.fromMethod(PaymentMethod method) {
    return _PaymentMethodDraft(
      id: method.id,
      type: method.type,
      label: TextEditingController(text: method.label),
      description: TextEditingController(text: method.description),
      paymentUrl: TextEditingController(text: method.paymentUrl),
      qrContent: TextEditingController(text: method.qrContent),
      details: method.details.map(_PaymentDetailDraft.fromDetail).toList(),
      enabled: method.enabled,
    );
  }

  final String id;
  PaymentMethodType type;
  final TextEditingController label;
  final TextEditingController description;
  final TextEditingController paymentUrl;
  final TextEditingController qrContent;
  final List<_PaymentDetailDraft> details;
  bool enabled;

  PaymentMethod toMethod(int sortOrder) {
    return PaymentMethod(
      id: id,
      type: type,
      label: label.text.trim(),
      description: description.text.trim(),
      details: details
          .where(
            (detail) =>
                detail.label.text.trim().isNotEmpty &&
                detail.value.text.trim().isNotEmpty,
          )
          .map(
            (detail) => PaymentDetail(
              label: detail.label.text.trim(),
              value: detail.value.text.trim(),
            ),
          )
          .toList(),
      paymentUrl: paymentUrl.text.trim(),
      qrContent: qrContent.text.trim(),
      enabled: enabled,
      sortOrder: sortOrder,
    );
  }

  void dispose() {
    label.dispose();
    description.dispose();
    paymentUrl.dispose();
    qrContent.dispose();
    for (final detail in details) {
      detail.dispose();
    }
  }
}

class _PaymentDetailDraft {
  _PaymentDetailDraft({required this.label, required this.value});

  factory _PaymentDetailDraft.empty() {
    return _PaymentDetailDraft(
      label: TextEditingController(),
      value: TextEditingController(),
    );
  }

  factory _PaymentDetailDraft.fromDetail(PaymentDetail detail) {
    return _PaymentDetailDraft(
      label: TextEditingController(text: detail.label),
      value: TextEditingController(text: detail.value),
    );
  }

  final TextEditingController label;
  final TextEditingController value;

  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class _PaymentMethodEditor extends StatefulWidget {
  const _PaymentMethodEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  final int index;
  final _PaymentMethodDraft draft;
  final VoidCallback onRemove;

  @override
  State<_PaymentMethodEditor> createState() => _PaymentMethodEditorState();
}

class _PaymentMethodEditorState extends State<_PaymentMethodEditor> {
  void _addDetail() {
    setState(() => widget.draft.details.add(_PaymentDetailDraft.empty()));
  }

  void _removeDetail(int index) {
    final detail = widget.draft.details.removeAt(index);
    detail.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: widget.index == 0,
        leading: Icon(_methodIcon(widget.draft.type)),
        title: Text(
          widget.draft.label.text.trim().isEmpty
              ? adminText(context, 'Novo método')
              : widget.draft.label.text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: IconButton(
          tooltip: adminText(context, 'Remover método'),
          onPressed: widget.onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            child: Column(
              children: [
                DropdownButtonFormField<PaymentMethodType>(
                  initialValue: widget.draft.type,
                  decoration: InputDecoration(
                    labelText: adminText(context, 'Tipo'),
                    border: const OutlineInputBorder(),
                  ),
                  items: PaymentMethodType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_methodTypeLabel(context, type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => widget.draft.type = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.draft.label,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: adminText(context, 'Nome do método'),
                    hintText: adminText(
                      context,
                      'Ex.: Transferência bancária ou PIX',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.draft.description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: adminText(context, 'Instruções (opcional)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        adminText(context, 'Dados exibidos'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: adminText(context, 'Adicionar dado'),
                      onPressed: _addDetail,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (
                  var index = 0;
                  index < widget.draft.details.length;
                  index++
                )
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: widget.draft.details[index].label,
                            decoration: InputDecoration(
                              labelText: adminText(context, 'Rótulo'),
                              hintText: adminText(
                                context,
                                'IBAN, Chave PIX, Nome...',
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: widget.draft.details[index].value,
                            decoration: InputDecoration(
                              labelText: adminText(context, 'Valor'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: adminText(context, 'Remover dado'),
                          onPressed: () => _removeDetail(index),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: widget.draft.paymentUrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      'Link de pagamento (opcional)',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.draft.qrContent,
                  minLines: 3,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: adminText(
                      context,
                      'Conteúdo do QR Code (opcional)',
                    ),
                    helperText: adminText(
                      context,
                      'Cole o link ou payload completo fornecido pelo banco.',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(adminText(context, 'Método ativo')),
                  value: widget.draft.enabled,
                  onChanged: (value) {
                    setState(() => widget.draft.enabled = value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _methodTypeLabel(BuildContext context, PaymentMethodType type) {
  return switch (type) {
    PaymentMethodType.bankTransfer => adminText(
      context,
      'Transferência bancária',
    ),
    PaymentMethodType.pix => 'PIX',
    PaymentMethodType.mbWay => 'MB Way',
    PaymentMethodType.paymentLink => adminText(context, 'Link de pagamento'),
    PaymentMethodType.other => adminText(context, 'Outro'),
  };
}

IconData _methodIcon(PaymentMethodType type) {
  return switch (type) {
    PaymentMethodType.bankTransfer => Icons.account_balance_outlined,
    PaymentMethodType.pix => Icons.qr_code_2,
    PaymentMethodType.mbWay => Icons.phone_iphone,
    PaymentMethodType.paymentLink => Icons.link,
    PaymentMethodType.other => Icons.payments_outlined,
  };
}
