import 'package:ffpmupt/models/payment_settings.dart';
import 'package:ffpmupt/services/payment_settings_repository.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/widgets/offering_payment_panel.dart';
import 'package:flutter/material.dart';

class OfferingScreen extends StatelessWidget {
  const OfferingScreen({super.key, required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final textTheme = Theme.of(context).textTheme;

    if (countryCode.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.offerings)),
        body: Center(child: Text(strings.offeringsSubtitle)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.offerings)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: StreamBuilder<PaymentSettings>(
                stream: PaymentSettingsRepository(
                  countryCode: countryCode,
                ).watch(),
                builder: (context, snapshot) {
                  final settings = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                size: 44,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                settings?.title ?? strings.offerings,
                                textAlign: TextAlign.center,
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xff193c37),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                settings?.subtitle ?? strings.offeringTransfer,
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium?.copyWith(
                                  color: const Color(0xff5f6d68),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OfferingPaymentPanel(
                        countryCode: countryCode,
                        strings: strings,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
