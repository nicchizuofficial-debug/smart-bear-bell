import 'dart:async';

// デモ用スタブ：実機ではsensors_plus + just_audioに差し替える
class MotionBellService {
  bool _running = false;
  Timer? _timer;

  bool get isRunning => _running;

  Future<void> start() async {
    _running = true;
    // デモ：2秒ごとにコンソールへログ出力（実機では音を鳴らす）
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      // ignore: avoid_print
      print('[MotionBell] 🔔 鈴音再生中...');
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    _running = false;
  }
}
