import 'package:ffpmupt/content/offering.dart';
import 'package:ffpmupt/settings/app_language.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PublicOfferingScreen extends StatelessWidget {
  const PublicOfferingScreen({super.key});

  Future<void> _copyIban(BuildContext context, AppStrings strings) async {
    await Clipboard.setData(ClipboardData(text: offeringAccount.iban));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.ibanCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              constraints: const BoxConstraints(maxWidth: 720),
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
                            strings.publicOfferingSubtitle,
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xff5f6d68),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PaymentLine(
                            label: strings.name,
                            value: offeringAccount.beneficiaryName,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            strings.iban,
                            style: textTheme.labelLarge?.copyWith(
                              color: const Color(0xff65716c),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            offeringAccount.iban,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              color: const Color(0xff1f2724),
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _copyIban(context, strings),
                            icon: const Icon(Icons.copy),
                            label: Text(strings.copyIban),
                          ),
                          const SizedBox(height: 18),
                          _PaymentLine(
                            label: strings.bank,
                            value: offeringAccount.bankName,
                          ),
                          _PaymentLine(
                            label: strings.description,
                            value: offeringAccount.defaultRemittance,
                          ),
                        ],
                      ),
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

class _PaymentLine extends StatelessWidget {
  const _PaymentLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xff65716c),
                ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xff1f2724),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
