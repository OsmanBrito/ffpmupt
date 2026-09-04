enum SundayModule { songs, familyPromise, motto, offerings, videos, notices }

class SundayPlanItem {
  const SundayPlanItem({required this.module, required this.enabled});

  final SundayModule module;
  final bool enabled;

  SundayPlanItem copyWith({bool? enabled}) {
    return SundayPlanItem(module: module, enabled: enabled ?? this.enabled);
  }
}

class SundaySessionReport {
  const SundaySessionReport({
    required this.startedAt,
    required this.finishedAt,
    required this.completedModules,
    required this.totalModules,
    required this.withoutPaper,
    required this.withoutInterruptions,
    required this.rating,
    required this.notes,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final int completedModules;
  final int totalModules;
  final bool withoutPaper;
  final bool withoutInterruptions;
  final int rating;
  final String notes;

  Duration get duration => finishedAt.difference(startedAt);

  Map<String, Object?> toMap() {
    return {
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'completedModules': completedModules,
      'totalModules': totalModules,
      'withoutPaper': withoutPaper,
      'withoutInterruptions': withoutInterruptions,
      'rating': rating,
      'notes': notes,
    };
  }

  static SundaySessionReport? fromMap(Map<String, Object?> map) {
    final startedAt = DateTime.tryParse(map['startedAt'] as String? ?? '');
    final finishedAt = DateTime.tryParse(map['finishedAt'] as String? ?? '');
    final completedModules = map['completedModules'];
    final totalModules = map['totalModules'];
    final withoutPaper = map['withoutPaper'];
    final withoutInterruptions = map['withoutInterruptions'];
    final rating = map['rating'];
    final notes = map['notes'];
    if (startedAt == null ||
        finishedAt == null ||
        completedModules is! int ||
        totalModules is! int ||
        withoutPaper is! bool ||
        withoutInterruptions is! bool ||
        rating is! int ||
        notes is! String) {
      return null;
    }
    return SundaySessionReport(
      startedAt: startedAt,
      finishedAt: finishedAt,
      completedModules: completedModules,
      totalModules: totalModules,
      withoutPaper: withoutPaper,
      withoutInterruptions: withoutInterruptions,
      rating: rating,
      notes: notes,
    );
  }
}
