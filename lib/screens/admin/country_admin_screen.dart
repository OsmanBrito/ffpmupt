import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/services/country_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/material.dart';

class CountryAdminScreen extends StatefulWidget {
  const CountryAdminScreen({super.key});

  @override
  State<CountryAdminScreen> createState() => _CountryAdminScreenState();
}

class _CountryAdminScreenState extends State<CountryAdminScreen> {
  final _repository = CountryRepository();
  final _nameController = TextEditingController();
  final _timezoneController = TextEditingController();
  String _defaultLanguage = CountryModel.portugal.defaultLanguage;
  bool _enabled = CountryModel.portugal.enabled;
  bool _isLoading = true;
  bool _isSaving = false;

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
    final country = await _repository.load(CountryModel.portugal.code);
    if (!mounted) {
      return;
    }

    setState(() {
      _nameController.text = country.name;
      _timezoneController.text = country.timezone;
      _defaultLanguage = country.defaultLanguage;
      _enabled = country.enabled;
      _isLoading = false;
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

    final saved = await _repository.save(
      CountryModel(
        code: CountryModel.portugal.code,
        name: name,
        defaultLanguage: _defaultLanguage,
        timezone: timezone,
        enabled: _enabled,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });
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
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      TextFormField(
                        readOnly: true,
                        initialValue: CountryModel.portugal.code,
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
                        onChanged: (value) {
                          setState(() {
                            _enabled = value;
                          });
                        },
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
