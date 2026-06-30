import 'package:ffpmupt/content/offering.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OfferingPaymentPanel extends StatelessWidget {
  const OfferingPaymentPanel({
    super.key,
    required this.strings,
    this.account = offeringAccount,
    this.showNote = true,
    this.compact = false,
  });

  final OfferingAccount account;
  final AppStrings strings;
  final bool showNote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final qrSize = compact ? 190.0 : 260.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(compact ? 18 : 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 640;
                final qr = _OfferingQr(
                  account: account,
                  strings: strings,
                  size: qrSize,
                );
                final details = _OfferingDetails(
                  account: account,
                  strings: strings,
                );

                if (!isWide) {
                  return Column(
                    children: [
                      qr,
                      const SizedBox(height: 18),
                      details,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: qrSize + 34, child: qr),
                    const SizedBox(width: 22),
                    Expanded(child: details),
                  ],
                );
              },
            ),
          ),
        ),
        if (showNote) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                strings.offeringQrNote,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xff56635f),
                      height: 1.35,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OfferingQr extends StatelessWidget {
  const _OfferingQr({
    required this.account,
    required this.strings,
    required this.size,
  });

  final OfferingAccount account;
  final AppStrings strings;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          strings.paymentQr,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffe8e1d5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: QrImageView(
              data: account.qrPayload,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          strings.paymentQrInstruction,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xff56635f),
                height: 1.3,
              ),
        ),
      ],
    );
  }
}

class _OfferingDetails extends StatelessWidget {
  const _OfferingDetails({
    required this.account,
    required this.strings,
  });

  final OfferingAccount account;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.bankDetails,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 18),
        _DetailRow(label: strings.name, value: account.beneficiaryName),
        if (account.iban.trim().isNotEmpty) ...[
          _DetailRow(label: strings.iban, value: account.iban),
          if (account.bic.trim().isNotEmpty)
            _DetailRow(label: 'BIC/SWIFT', value: account.bic),
          if (account.bankName.trim().isNotEmpty)
            _DetailRow(label: strings.bank, value: account.bankName),
        ],
        _DetailRow(
          label: strings.description,
          value: account.defaultRemittance,
        ),
        if (account.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            account.notes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xff7a5428),
                  height: 1.35,
                ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
