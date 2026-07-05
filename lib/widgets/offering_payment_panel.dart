import 'package:ffpmupt/models/payment_settings.dart';
import 'package:ffpmupt/services/payment_settings_repository.dart';
import 'package:ffpmupt/settings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OfferingPaymentPanel extends StatelessWidget {
  const OfferingPaymentPanel({
    super.key,
    required this.countryCode,
    required this.strings,
    this.showNote = true,
    this.compact = false,
  });

  final String countryCode;
  final AppStrings strings;
  final bool showNote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PaymentSettings>(
      stream: PaymentSettingsRepository(countryCode: countryCode).watch(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        if (settings == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!settings.enabled || settings.enabledMethods.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                settings.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < settings.enabledMethods.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == settings.enabledMethods.length - 1 ? 0 : 12,
                ),
                child: _PaymentMethodCard(
                  method: settings.enabledMethods[index],
                  strings: strings,
                  compact: compact,
                ),
              ),
            if (showNote && settings.note.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    settings.note,
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
      },
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.strings,
    required this.compact,
  });

  final PaymentMethod method;
  final AppStrings strings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasQr = method.qrContent.trim().isNotEmpty;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_methodIcon(method.type)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                method.label,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        if (method.description.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(method.description),
        ],
        const SizedBox(height: 18),
        for (final detail in method.details)
          _DetailRow(label: detail.label, value: detail.value),
        if (method.paymentUrl.trim().isNotEmpty)
          _DetailRow(label: 'Link', value: method.paymentUrl),
      ],
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSideBySide = hasQr && constraints.maxWidth >= 640;
            if (!showSideBySide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  if (hasQr) ...[
                    const SizedBox(height: 18),
                    _PaymentQr(
                      data: method.qrContent,
                      strings: strings,
                      size: compact ? 180 : 230,
                    ),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: compact ? 208 : 258,
                  child: _PaymentQr(
                    data: method.qrContent,
                    strings: strings,
                    size: compact ? 180 : 230,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentQr extends StatelessWidget {
  const _PaymentQr({
    required this.data,
    required this.strings,
    required this.size,
  });

  final String data;
  final AppStrings strings;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          strings.paymentQr,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffe8e1d5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
          ),
          IconButton(
            tooltip: 'Copiar $label',
            onPressed: () => _copy(context),
            icon: const Icon(Icons.copy_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

IconData _methodIcon(PaymentMethodType type) {
  return switch (type) {
    PaymentMethodType.bankTransfer => Icons.account_balance_outlined,
    PaymentMethodType.pix => Icons.qr_code_2,
    PaymentMethodType.mbWay => Icons.phone_iphone,
    PaymentMethodType.paymentLink => Icons.link,
    PaymentMethodType.other => Icons.payments_outlined,
  };
}
