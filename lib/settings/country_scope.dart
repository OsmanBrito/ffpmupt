import 'package:ffpmupt/models/country.dart';
import 'package:ffpmupt/services/country_repository.dart';
import 'package:ffpmupt/settings/country_location.dart';
import 'package:ffpmupt/settings/local_store.dart';
import 'package:flutter/material.dart';

const _selectedCountryKey = 'selected_country_v1';

class CountryController extends ChangeNotifier {
  CountryController({CountryRepository? repository})
    : _repository = repository ?? CountryRepository();

  final CountryRepository _repository;
  List<CountryModel> _countries = const [];
  CountryModel? _country;
  bool _isLoading = true;

  List<CountryModel> get countries => _countries;
  CountryModel? get country => _country;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _countries = await _repository.loadEnabledCountries();
    final locationCode = countryCodeFromLocation();
    final storedCode = await LocalStore.getString(_selectedCountryKey);
    final preferredCode = locationCode ?? storedCode;
    if (preferredCode != null) {
      _country = _findCountry(preferredCode);
    }
    if (_country != null &&
        locationCode == null &&
        !shouldPreserveCountryLocation()) {
      setCountryLocation(_country!.code);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectCountry(CountryModel country) async {
    _country = country;
    if (!_countries.any((item) => item.code == country.code)) {
      _countries = [..._countries, country];
    }
    setCountryLocation(country.code);
    notifyListeners();
    await LocalStore.setString(_selectedCountryKey, country.code);
  }

  Future<void> showCountrySelection() async {
    _country = null;
    setCountryLocation(null);
    notifyListeners();
    await LocalStore.setString(_selectedCountryKey, '');
  }

  Future<void> updateCountry(CountryModel country) async {
    _countries = [
      for (final item in _countries)
        if (item.code == country.code) country else item,
    ];
    if (_country?.code == country.code) {
      _country = country;
    }
    notifyListeners();
  }

  CountryModel? _findCountry(String code) {
    for (final country in _countries) {
      if (country.code.toLowerCase() == code.toLowerCase()) {
        return country;
      }
    }
    return null;
  }
}

class CountryScope extends InheritedNotifier<CountryController> {
  const CountryScope({
    super.key,
    required CountryController controller,
    required super.child,
  }) : super(notifier: controller);

  static CountryController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CountryScope>();
    assert(scope != null, 'CountryScope not found in context');
    return scope!.notifier!;
  }

  static CountryController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<CountryScope>();
    final scope = element?.widget as CountryScope?;
    assert(scope != null, 'CountryScope not found in context');
    return scope!.notifier!;
  }
}
