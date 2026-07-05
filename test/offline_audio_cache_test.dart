import 'package:ffpmupt/services/offline_audio_cache_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('offline audio progress reports a bounded fraction', () {
    const progress = OfflineAudioCacheProgress(
      status: OfflineAudioCacheStatus.downloading,
      completed: 8,
      total: 32,
      failed: 0,
    );

    expect(progress.fraction, 0.25);
  });

  test('offline audio progress handles empty and excessive totals', () {
    expect(OfflineAudioCacheProgress.idle.fraction, isNull);

    const complete = OfflineAudioCacheProgress(
      status: OfflineAudioCacheStatus.ready,
      completed: 40,
      total: 32,
      failed: 0,
    );
    expect(complete.fraction, 1);
  });
}
