enum PaymentMethodType {
  bankTransfer('bankTransfer'),
  pix('pix'),
  mbWay('mbWay'),
  paymentLink('paymentLink'),
  other('other');

  const PaymentMethodType(this.value);

  final String value;

  static PaymentMethodType fromValue(String? value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => PaymentMethodType.other,
    );
  }
}

class PaymentDetail {
  const PaymentDetail({required this.label, required this.value});

  final String label;
  final String value;

  Map<String, Object?> toMap() => {'label': label, 'value': value};

  static PaymentDetail? fromMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = Map<String, Object?>.from(value);
    final label = map['label'];
    final detailValue = map['value'];
    if (label is! String || detailValue is! String) {
      return null;
    }
    return PaymentDetail(label: label, value: detailValue);
  }
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.description,
    required this.details,
    required this.paymentUrl,
    required this.qrContent,
    required this.enabled,
    required this.sortOrder,
  });

  final String id;
  final PaymentMethodType type;
  final String label;
  final String description;
  final List<PaymentDetail> details;
  final String paymentUrl;
  final String qrContent;
  final bool enabled;
  final int sortOrder;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.value,
      'label': label,
      'description': description,
      'details': details.map((detail) => detail.toMap()).toList(),
      'paymentUrl': paymentUrl,
      'qrContent': qrContent,
      'enabled': enabled,
      'sortOrder': sortOrder,
    };
  }

  static PaymentMethod? fromMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = Map<String, Object?>.from(value);
    final id = map['id'];
    final label = map['label'];
    final description = map['description'];
    final detailsValue = map['details'];
    final paymentUrl = map['paymentUrl'];
    final qrContent = map['qrContent'];
    final enabled = map['enabled'];
    final sortOrder = map['sortOrder'];
    if (id is! String ||
        label is! String ||
        description is! String ||
        detailsValue is! List ||
        paymentUrl is! String ||
        qrContent is! String ||
        enabled is! bool ||
        sortOrder is! int) {
      return null;
    }

    final details = detailsValue.map(PaymentDetail.fromMap).toList();
    if (details.any((detail) => detail == null)) {
      return null;
    }

    return PaymentMethod(
      id: id,
      type: PaymentMethodType.fromValue(map['type'] as String?),
      label: label,
      description: description,
      details: details.cast<PaymentDetail>(),
      paymentUrl: paymentUrl,
      qrContent: qrContent,
      enabled: enabled,
      sortOrder: sortOrder,
    );
  }
}

class PaymentSettings {
  const PaymentSettings({
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.note,
    required this.methods,
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final String note;
  final List<PaymentMethod> methods;

  List<PaymentMethod> get enabledMethods {
    return methods.where((method) => method.enabled).toList()
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
  }

  Map<String, Object?> toMap() {
    return {
      'enabled': enabled,
      'title': title,
      'subtitle': subtitle,
      'note': note,
      'methods': methods.map((method) => method.toMap()).toList(),
    };
  }

  static PaymentSettings? fromMap(Map<String, Object?> map) {
    final enabled = map['enabled'];
    final title = map['title'];
    final subtitle = map['subtitle'];
    final note = map['note'];
    final methodsValue = map['methods'];
    if (enabled is! bool ||
        title is! String ||
        subtitle is! String ||
        note is! String ||
        methodsValue is! List) {
      return null;
    }

    final methods = methodsValue.map(PaymentMethod.fromMap).toList();
    if (methods.any((method) => method == null)) {
      return null;
    }

    return PaymentSettings(
      enabled: enabled,
      title: title,
      subtitle: subtitle,
      note: note,
      methods: methods.cast<PaymentMethod>(),
    );
  }
}
