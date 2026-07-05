import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/models/operational_crm.dart';
import 'package:ffpmupt/screens/admin/country_admin_screen.dart';
import 'package:ffpmupt/services/country_repository.dart';
import 'package:ffpmupt/services/operational_crm_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OperationalCrmScreen extends StatefulWidget {
  const OperationalCrmScreen({super.key});

  @override
  State<OperationalCrmScreen> createState() => _OperationalCrmScreenState();
}

class _OperationalCrmScreenState extends State<OperationalCrmScreen> {
  final _repository = OperationalCrmRepository();
  final _countryRepository = CountryRepository();
  List<CountryOperationalSummary> _countries = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final countries = await _repository.loadCountries();
      if (mounted) {
        setState(() => _countries = countries);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createCountry() async {
    final country = await showDialog<CountryModel>(
      context: context,
      builder: (context) => const _CountryDialog(),
    );
    if (country == null) {
      return;
    }
    final saved = await _countryRepository.save(country);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved ? 'País criado.' : 'Não foi possível criar o país.',
        ),
      ),
    );
    if (saved) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _countries.where((country) => country.isReady).length;
    final churches = _countries.fold<int>(
      0,
      (total, country) => total + country.churchCount,
    );
    final admins = _countries.fold<int>(
      0,
      (total, country) => total + country.adminCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM operacional'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Adicionar país',
            onPressed: _createCountry,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'Visão geral',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _Metric(
                              label: 'Países',
                              value: '${_countries.length}',
                              icon: Icons.public,
                            ),
                            _Metric(
                              label: 'Prontos',
                              value: '$ready',
                              icon: Icons.verified_outlined,
                            ),
                            _Metric(
                              label: 'Igrejas',
                              value: '$churches',
                              icon: Icons.church_outlined,
                            ),
                            _Metric(
                              label: 'Admins',
                              value: '$admins',
                              icon: Icons.admin_panel_settings_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Países',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _createCountry,
                              icon: const Icon(Icons.add),
                              label: const Text('Novo país'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_countries.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Nenhum país encontrado.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        for (final summary in _countries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CountryCard(
                              summary: summary,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CountryOperationsScreen(
                                          summary: summary,
                                        ),
                                  ),
                                );
                                await _load();
                              },
                            ),
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

class CountryOperationsScreen extends StatelessWidget {
  const CountryOperationsScreen({super.key, required this.summary});

  final CountryOperationalSummary summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(summary.country.name),
        actions: [
          IconButton(
            tooltip: 'Configurações do país',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    CountryAdminScreen(countryCode: summary.country.code),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _CountryReadiness(summary: summary),
                const SizedBox(height: 30),
                _ChurchSection(country: summary.country),
                const SizedBox(height: 30),
                _AdminSection(countryCode: summary.country.code),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryReadiness extends StatelessWidget {
  const _CountryReadiness({required this.summary});

  final CountryOperationalSummary summary;

  @override
  Widget build(BuildContext context) {
    final checks = [
      ('País ativo', summary.country.enabled),
      ('Administrador associado', summary.adminCount > 0),
      ('Igreja local cadastrada', summary.churchCount > 0),
      (
        'Promessa nos idiomas necessários',
        summary.promiseLanguageCount >= summary.expectedPromiseLanguages,
      ),
      ('Catálogo remoto preparado', summary.songCount > 0),
      ('Pagamentos configurados', summary.hasPayments),
      ('Vídeos configurados', summary.hasWeeklyVideos),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Prontidão do país',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text('${summary.completedSteps}/${summary.totalSteps}'),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: summary.progress, minHeight: 8),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final check in checks)
              Chip(
                avatar: Icon(
                  check.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: check.$2
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                label: Text(check.$1),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChurchSection extends StatelessWidget {
  const _ChurchSection({required this.country});

  final CountryModel country;

  @override
  Widget build(BuildContext context) {
    final repository = OperationalCrmRepository();
    return StreamBuilder<List<LocalChurch>>(
      stream: repository.watchChurches(country.code),
      builder: (context, snapshot) {
        final churches = snapshot.data ?? const <LocalChurch>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Igrejas locais',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Adicionar igreja',
                  onPressed: () => _openChurchEditor(
                    context,
                    repository: repository,
                    country: country,
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (snapshot.hasError)
              const Text('Não foi possível carregar as igrejas.'),
            if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator()),
            if (snapshot.hasData && churches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Nenhuma igreja local cadastrada.'),
              ),
            for (final church in churches)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.church_outlined,
                    color: church.enabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  title: Text(
                    church.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      church.city,
                      church.contactName,
                    ].where((value) => value.isNotEmpty).join(' · '),
                  ),
                  trailing: IconButton(
                    tooltip: 'Editar igreja',
                    onPressed: () => _openChurchEditor(
                      context,
                      repository: repository,
                      country: country,
                      church: church,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  onTap: () => _openChurchEditor(
                    context,
                    repository: repository,
                    country: country,
                    church: church,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final repository = OperationalCrmRepository();
    return StreamBuilder<List<AdminProfile>>(
      stream: repository.watchAdmins(),
      builder: (context, snapshot) {
        final admins = (snapshot.data ?? const <AdminProfile>[])
            .where(
              (admin) =>
                  admin.role == 'admin' &&
                  admin.countryCodes.contains(countryCode),
            )
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Administradores',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Convidar administrador',
                  onPressed: () => _openInviteCreator(
                    context,
                    repository: repository,
                    countryCode: countryCode,
                  ),
                  icon: const Icon(Icons.person_add_alt_1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Envie um link. O administrador cria e confirma a própria conta.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (snapshot.hasError)
              const Text('Não foi possível carregar os administradores.'),
            if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator()),
            if (snapshot.hasData && admins.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text('Nenhum administrador associado.'),
              ),
            for (final admin in admins)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: admin.enabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  title: Text(
                    admin.displayName.isEmpty
                        ? admin.email.isEmpty
                              ? admin.uid
                              : admin.email
                        : admin.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle:
                      admin.displayName.isNotEmpty && admin.email.isNotEmpty
                      ? Text(admin.email)
                      : Text(admin.uid),
                  trailing: IconButton(
                    tooltip: 'Editar acesso',
                    onPressed: () => _openAdminEditor(
                      context,
                      repository: repository,
                      countryCode: countryCode,
                      profile: admin,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  onTap: () => _openAdminEditor(
                    context,
                    repository: repository,
                    countryCode: countryCode,
                    profile: admin,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            _PendingInvites(repository: repository, countryCode: countryCode),
          ],
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({required this.summary, required this.onTap});

  final CountryOperationalSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Text(summary.country.code.toUpperCase())),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.country.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          summary.isReady
                              ? 'Pronto'
                              : '${summary.completedSteps}/${summary.totalSteps}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: summary.progress,
                      minHeight: 7,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${summary.churchCount} igrejas · ${summary.adminCount} admins · ${summary.songCount} músicas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            const Text('Não foi possível carregar o CRM.'),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryDialog extends StatefulWidget {
  const _CountryDialog();

  @override
  State<_CountryDialog> createState() => _CountryDialogState();
}

class _CountryDialogState extends State<_CountryDialog> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _timezone = TextEditingController(text: 'Europe/Lisbon');
  String _language = 'pt';

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _timezone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo país'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _code,
                decoration: const InputDecoration(
                  labelText: 'Código do país',
                  hintText: 'Ex.: br, es, de',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: const InputDecoration(
                  labelText: 'Idioma principal',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pt', child: Text('Português')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ko', child: Text('한국어')),
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                  DropdownMenuItem(value: 'it', child: Text('Italiano')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _language = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timezone,
                decoration: const InputDecoration(
                  labelText: 'Fuso horário IANA',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final code = _code.text.trim().toLowerCase();
            if (!RegExp(r'^[a-z]{2,3}$').hasMatch(code) ||
                _name.text.trim().isEmpty ||
                _timezone.text.trim().isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              CountryModel(
                code: code,
                name: _name.text.trim(),
                defaultLanguage: _language,
                timezone: _timezone.text.trim(),
                enabled: true,
              ),
            );
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

Future<void> _openChurchEditor(
  BuildContext context, {
  required OperationalCrmRepository repository,
  required CountryModel country,
  LocalChurch? church,
}) async {
  final name = TextEditingController(text: church?.name ?? '');
  final city = TextEditingController(text: church?.city ?? '');
  final address = TextEditingController(text: church?.address ?? '');
  final timezone = TextEditingController(
    text: church?.timezone ?? country.timezone,
  );
  final contactName = TextEditingController(text: church?.contactName ?? '');
  final contactEmail = TextEditingController(text: church?.contactEmail ?? '');
  var enabled = church?.enabled ?? true;
  final result = await showDialog<LocalChurch>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(church == null ? 'Nova igreja' : 'Editar igreja'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(controller: name, label: 'Nome da igreja'),
                _DialogField(controller: city, label: 'Cidade'),
                _DialogField(controller: address, label: 'Endereço'),
                _DialogField(controller: timezone, label: 'Fuso horário'),
                _DialogField(controller: contactName, label: 'Responsável'),
                _DialogField(
                  controller: contactEmail,
                  label: 'Email do responsável',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Igreja ativa'),
                  value: enabled,
                  onChanged: (value) => setDialogState(() => enabled = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty || city.text.trim().isEmpty) {
                return;
              }
              Navigator.of(context).pop(
                LocalChurch(
                  id: church?.id ?? '',
                  name: name.text.trim(),
                  city: city.text.trim(),
                  address: address.text.trim(),
                  timezone: timezone.text.trim(),
                  contactName: contactName.text.trim(),
                  contactEmail: contactEmail.text.trim(),
                  enabled: enabled,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  city.dispose();
  address.dispose();
  timezone.dispose();
  contactName.dispose();
  contactEmail.dispose();
  if (result == null || !context.mounted) {
    return;
  }
  try {
    await repository.saveChurch(country.code, result);
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível guardar: $error')),
      );
    }
  }
}

Future<void> _openAdminEditor(
  BuildContext context, {
  required OperationalCrmRepository repository,
  required String countryCode,
  required AdminProfile profile,
}) async {
  final name = TextEditingController(text: profile.displayName);
  final email = TextEditingController(text: profile.email);
  var enabled = profile.enabled;
  final result = await showDialog<AdminProfile>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Editar administrador'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Administrador ativo'),
                  value: enabled,
                  onChanged: (value) => setDialogState(() => enabled = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop(
                profile.copyWith(
                  countryCodes: profile.countryCodes
                      .where((code) => code != countryCode)
                      .toList(),
                ),
              );
            },
            icon: const Icon(Icons.link_off),
            label: const Text('Remover deste país'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (email.text.trim().isEmpty) {
                return;
              }
              Navigator.of(context).pop(
                AdminProfile(
                  uid: profile.uid,
                  email: email.text.trim(),
                  displayName: name.text.trim(),
                  role: 'admin',
                  enabled: enabled,
                  countryCodes: profile.countryCodes,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  email.dispose();
  if (result == null || !context.mounted) {
    return;
  }
  try {
    await repository.saveCountryAdmin(result);
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível guardar: $error')),
      );
    }
  }
}

class _PendingInvites extends StatelessWidget {
  const _PendingInvites({required this.repository, required this.countryCode});

  final OperationalCrmRepository repository;
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminInvite>>(
      stream: repository.watchInvites(countryCode),
      builder: (context, snapshot) {
        final invites = (snapshot.data ?? const <AdminInvite>[])
            .where((invite) => invite.isPending)
            .toList();
        if (!snapshot.hasData || invites.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Convites pendentes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final invite in invites)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.outgoing_mail),
                  title: Text(invite.displayName),
                  subtitle: Text(invite.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Copiar link',
                        onPressed: () => _copyInviteLink(context, invite.id),
                        icon: const Icon(Icons.link),
                      ),
                      IconButton(
                        tooltip: 'Cancelar convite',
                        onPressed: () => repository.cancelInvite(invite.id),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<void> _openInviteCreator(
  BuildContext context, {
  required OperationalCrmRepository repository,
  required String countryCode,
}) async {
  final name = TextEditingController();
  final email = TextEditingController();
  final data = await showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Convidar administrador'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            final normalizedEmail = email.text.trim().toLowerCase();
            if (name.text.trim().isEmpty || !normalizedEmail.contains('@')) {
              return;
            }
            Navigator.of(context).pop((name.text.trim(), normalizedEmail));
          },
          icon: const Icon(Icons.link),
          label: const Text('Criar convite'),
        ),
      ],
    ),
  );
  name.dispose();
  email.dispose();
  if (data == null || !context.mounted) {
    return;
  }

  try {
    final invite = await repository.createAdminInvite(
      email: data.$2,
      displayName: data.$1,
      countryCode: countryCode,
      createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
    );
    if (!context.mounted) {
      return;
    }
    final link = _inviteLink(invite.id);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convite criado'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Envie este link para ${invite.email}:'),
              const SizedBox(height: 12),
              SelectableText(link),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Link copiado.')));
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar link'),
          ),
        ],
      ),
    );
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível criar o convite: $error')),
      );
    }
  }
}

Future<void> _copyInviteLink(BuildContext context, String inviteId) async {
  await Clipboard.setData(ClipboardData(text: _inviteLink(inviteId)));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copiado.')));
  }
}

String _inviteLink(String inviteId) {
  return '${Uri.base.origin}/#/invite/$inviteId';
}

class _DialogField extends StatelessWidget {
  const _DialogField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
