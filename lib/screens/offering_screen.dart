import 'package:ffpmupt/content/offering.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:ffpmupt/widgets/offering_payment_panel.dart';
import 'package:flutter/material.dart';

class OfferingScreen extends StatelessWidget {
  const OfferingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = offeringAccount;
    final strings = AppStrings.of(AppLanguageScope.watch(context).language);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.offerings),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
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
                            strings.offerings,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xff193c37),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            strings.offeringTransfer,
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
                    account: account,
                    strings: strings,
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
