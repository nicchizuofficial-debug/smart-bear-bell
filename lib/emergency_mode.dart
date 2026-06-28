import 'dart:async';

// デモ用スタブ：実機ではtorch_light + just_audio + volume_controllerに差し替える
class EmergencyMode {
  bool _active = false;
  Timer? _strobeLog;

  bool get isActive => _active;

  void startShakeDetection() {
    // 実機：accelerometerEventStream() で強い振りを検知
  }

  Future<void> activate() async {
    _active = true;
    _strobeLog = Timer.periodic(const Duration(milliseconds: 300), (_) {
      // ignore: avoid_print
      print('[Emergency] 🚨 LEDストロボ + 撃退音再生中!');
    });
  }

  Future<void> deactivate() async {
    _strobeLog?.cancel();
    _active = false;
  }

  void dispose() {
    _strobeLog?.cancel();
  }
}
