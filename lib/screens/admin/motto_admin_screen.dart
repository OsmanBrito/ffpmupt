import 'package:ffpmupt/models/motto.dart';
import 'package:ffpmupt/services/motto_repository.dart';
import 'package:ffpmupt/settings/admin_copy.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/material.dart';

class MottoAdminScreen extends StatefulWidget {
  const MottoAdminScreen({super.key, required this.countryCode});

  final String countryCode;

  @override
  State<MottoAdminScreen> createState() => _MottoAdminScreenState();
}

class _MottoAdminScreenState extends State<MottoAdminScreen> {
  late final MottoRepository _repository;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = MottoRepository(countryCode: widget.countryCode);
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final motto = await _repository.loadForAdmin();
    if (!mounted) {
      return;
    }
    setState(() {
      _titleController.text = motto.title;
      _bodyController.text = motto.body;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminText(context, 'Preencha o título e texto do lema.'),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repository.save(MottoSettings(title: title, body: body));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(adminText(context, 'Lema guardado.'))),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${adminText(context, 'Não foi possível guardar o lema.')}: $error',
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
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.motto),
        actions: [
          IconButton(
            tooltip: strings.save,
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
                        adminText(context, 'Lema anual'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adminText(
                          context,
                          'Este lema aparece na página pública deste país.',
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: adminText(context, 'Título'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bodyController,
                        minLines: 6,
                        maxLines: 14,
                        decoration: InputDecoration(
                          labelText: adminText(context, 'Texto do lema'),
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                        ),
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
