enum ReadinessArea {
  country,
  admin,
  songs,
  promise,
  payments,
  videos,
  holyGrounds,
  offline,
}

class ReadinessCheck {
  const ReadinessCheck({
    required this.area,
    required this.ready,
    required this.detail,
  });

  final ReadinessArea area;
  final bool ready;
  final String detail;
}

class ContentIssue {
  const ContentIssue({required this.area, required this.subject});

  final ReadinessArea area;
  final String subject;
}

class CountryReadiness {
  const CountryReadiness({required this.checks, required this.issues});

  final List<ReadinessCheck> checks;
  final List<ContentIssue> issues;

  int get completed => checks.where((check) => check.ready).length;
  int get total => checks.length;
  double get progress => total == 0 ? 0 : completed / total;
  bool get isReady => checks.isNotEmpty && completed == total && issues.isEmpty;
}
