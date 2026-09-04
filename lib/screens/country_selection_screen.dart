import 'package:ffpmupt/app_branding.dart';
import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/onboarding_copy.dart';
import 'package:ffpmupt/widgets/language_menu_button.dart';
import 'package:flutter/material.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({
    super.key,
    required this.countries,
    required this.onSelected,
  });

  final List<CountryModel> countries;
  final ValueChanged<CountryModel> onSelected;

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language =
        AppLanguageScope.maybeWatch(context)?.language ?? AppLanguage.english;
    final copy = OnboardingCopy.of(language);
    final query = _query.trim().toLowerCase();
    final visibleCountries = widget.countries
        .where(
          (country) =>
              country.name.toLowerCase().contains(query) ||
              country.code.toLowerCase().contains(query),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        actions: [const LanguageMenuButton(), const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.public,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    copy.selectCountryTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.selectCountrySubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xff65716c),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.selectCountryDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xff65716c),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (widget.countries.isNotEmpty)
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: copy.searchCountries,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).deleteButtonTooltip,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: widget.countries.isEmpty
                        ? _EmptyCountryState(message: copy.noCountries)
                        : visibleCountries.isEmpty
                        ? _EmptyCountryState(message: copy.noCountriesMatch)
                        : ListView.separated(
                            itemCount: visibleCountries.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final country = visibleCountries[index];
                              final defaultLanguage = appLanguageLabel(
                                appLanguageFromCode(country.defaultLanguage),
                              );
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  leading: CircleAvatar(
                                    child: Text(country.code.toUpperCase()),
                                  ),
                                  title: Text(
                                    country.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${copy.defaultLanguage}: $defaultLanguage',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => widget.onSelected(country),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/request-access'),
                    icon: const Icon(Icons.mark_email_unread_outlined),
                    label: Text(copy.requestAdministratorAccess),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.adminAccess,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xff65716c),
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

class _EmptyCountryState extends StatelessWidget {
  const _EmptyCountryState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.public_off_outlined,
            size: 44,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
