import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/services/country_repository.dart';
import 'package:ffpmupt/settings/admin_copy.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/settings/country_scope.dart';
import 'package:flutter/material.dart';

class CountryAdminScreen extends StatefulWidget {
  const CountryAdminScreen({
    super.key,
    required this.countryCode,
    required this.isSuperAdmin,
    this.repository,
  });

  final String countryCode;
  final bool isSuperAdmin;
  final CountryRepository? repository;

  @override
  State<CountryAdminScreen> createState() => _CountryAdminScreenState();
}

class _CountryAdminScreenState extends State<CountryAdminScreen> {
  late final CountryRepository _repository =
      widget.repository ?? CountryRepository();
  final _nameController = TextEditingController();
  final _timezoneController = TextEditingController();
  String _defaultLanguage = CountryModel.portugal.defaultLanguage;
  bool _enabled = CountryModel.portugal.enabled;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final country = await _repository.load(widget.countryCode);
    if (!mounted) {
      return;
    }

    if (country == null) {
      setState(() {
        _isLoading = false;
        _loadError = adminText(
          context,
          'Não foi possível carregar as configurações deste país.',
        );
      });
      return;
    }

    setState(() {
      _nameController.text = country.name;
      _timezoneController.text = country.timezone;
      _defaultLanguage = country.defaultLanguage;
      _enabled = country.enabled;
      _isLoading = false;
      _loadError = null;
    });
  }

  Future<void> _save(AppStrings strings) async {
    final name = _nameController.text.trim();
    final timezone = _timezoneController.text.trim();
    if (name.isEmpty || timezone.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final country = CountryModel(
      code: widget.countryCode,
      name: name,
      defaultLanguage: _defaultLanguage,
      timezone: timezone,
      enabled: _enabled,
    );
    final saved = await _repository.save(country);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
    if (saved) {
      await CountryScope.read(context).updateCountry(country);
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? strings.countrySaved : strings.countrySaveFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);

    return Scaffold(
      appBar: AppBar(title: Text(strings.countrySettings)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        FilledButton.tonalIcon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: Text(adminText(context, 'Tentar novamente')),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      TextFormField(
                        readOnly: true,
                        initialValue: widget.countryCode,
                        decoration: InputDecoration(
                          labelText: strings.countryCode,
                          prefixIcon: const Icon(Icons.flag_outlined),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: strings.countryName,
                          prefixIcon: const Icon(Icons.public),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _defaultLanguage,
                        decoration: InputDecoration(
                          labelText: strings.defaultLanguage,
                          prefixIcon: const Icon(Icons.language),
                          border: const OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'pt',
                            child: Text('Português'),
                          ),
                          DropdownMenuItem(value: 'ko', child: Text('한국어')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'es', child: Text('Español')),
                          DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                          DropdownMenuItem(
                            value: 'it',
                            child: Text('Italiano'),
                          ),
                          DropdownMenuItem(
                            value: 'fr',
                            child: Text('Français'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _defaultLanguage = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _timezoneController,
                        decoration: InputDecoration(
                          labelText: strings.timezone,
                          prefixIcon: const Icon(Icons.schedule),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.countryEnabled),
                        value: _enabled,
                        subtitle: Text(
                          adminText(
                            context,
                            widget.isSuperAdmin
                                ? 'Apenas o superadmin deve alterar a disponibilidade pública.'
                                : 'Apenas o superadmin pode ativar ou desativar países.',
                          ),
                        ),
                        onChanged: widget.isSuperAdmin
                            ? (value) => setState(() => _enabled = value)
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : () => _save(strings),
                          icon: _isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(strings.save),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
