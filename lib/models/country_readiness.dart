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
    this.required = true,
  });

  final ReadinessArea area;
  final bool ready;
  final String detail;
  final bool required;
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

  Iterable<ReadinessCheck> get requiredChecks =>
      checks.where((check) => check.required);

  int get completed => requiredChecks.where((check) => check.ready).length;
  int get total => requiredChecks.length;
  double get progress => total == 0 ? 0 : completed / total;
  bool get isReady {
    final requiredAreas = requiredChecks.map((check) => check.area).toSet();
    final hasBlockingIssues = issues.any(
      (issue) => requiredAreas.contains(issue.area),
    );
    return total > 0 && completed == total && !hasBlockingIssues;
  }
}
