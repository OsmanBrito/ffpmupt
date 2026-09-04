enum OfflineAudioCacheStatus {
  idle,
  available,
  checking,
  downloading,
  ready,
  partial,
}

class OfflineAudioCacheProgress {
  const OfflineAudioCacheProgress({
    required this.status,
    required this.completed,
    required this.total,
    required this.failed,
    this.updatedAt,
  });

  static const idle = OfflineAudioCacheProgress(
    status: OfflineAudioCacheStatus.idle,
    completed: 0,
    total: 0,
    failed: 0,
  );

  final OfflineAudioCacheStatus status;
  final int completed;
  final int total;
  final int failed;
  final DateTime? updatedAt;

  double? get fraction {
    if (total <= 0) {
      return null;
    }
    return completed.clamp(0, total) / total;
  }
}
