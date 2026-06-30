class OfferingAccount {
  const OfferingAccount({
    required this.beneficiaryName,
    this.offeringPageUrl = '',
    this.iban = '',
    this.bic = '',
    this.defaultAmount,
    this.defaultRemittance = 'Oferta Domingo',
    this.bankName = '',
    this.notes = '',
  });

  final String beneficiaryName;
  final String offeringPageUrl;
  final String iban;
  final String bic;
  final double? defaultAmount;
  final String defaultRemittance;
  final String bankName;
  final String notes;

  bool get isConfigured {
    return hasBankTransfer;
  }

  bool get hasOfferingPageUrl {
    return offeringPageUrl.trim().isNotEmpty &&
        !offeringPageUrl.contains('INSERIR');
  }

  bool get hasBankTransfer {
    return beneficiaryName.trim().isNotEmpty &&
        iban.trim().isNotEmpty &&
        !iban.contains('INSERIR');
  }

  String get normalizedIban {
    return iban.replaceAll(' ', '').toUpperCase();
  }

  String get epcQrPayload {
    final amountLine =
        defaultAmount == null ? '' : 'EUR${defaultAmount!.toStringAsFixed(2)}';

    return [
      'BCD',
      '002',
      '1',
      'SCT',
      bic.trim(),
      beneficiaryName.trim(),
      normalizedIban,
      amountLine,
      '',
      '',
      defaultRemittance.trim(),
      '',
    ].join('\n');
  }

  String get qrPayload {
    if (hasOfferingPageUrl) {
      return offeringPageUrl.trim();
    }

    return epcQrPayload;
  }

  String? get formattedAmount {
    if (defaultAmount == null) {
      return null;
    }

    return '${defaultAmount!.toStringAsFixed(2)} EUR';
  }
}

const offeringAccount = OfferingAccount(
  beneficiaryName: 'Federação da Família para a Paz Mundial e Unificação',
  offeringPageUrl: 'https://ffpmupt-402e1.web.app/#/ofertas',
  iban: 'PT50 0010 0000 3313 7060 0012 8',
  bankName: 'Banco BPI, S.A.',
  // Keep null when the person should choose the amount.
  defaultAmount: null,
  defaultRemittance: 'Oferta Domingo',
  notes: '',
);
