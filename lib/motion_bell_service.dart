import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'audio_service.dart';
import 'bell_settings.dart';

class MotionBellService {
  final AudioService audio;
  MotionBellService(this.audio);

  bool _running = false;
  bool get isRunning => _running;

  StreamSubscription<AccelerometerEvent>? _sub;
  final _mags = <double>[];
  bool _bellOn = false;

  // 加速度の分散がこの閾値を超えたら「歩行中」と判定
  static const _walkThreshold = 0.8;
  static const _windowSize    = 25;

  Future<void> start(BellSettings settings) async {
    if (_running) return;
    _running = true;
    await audio.init(settings);

    if (kIsWeb) {
      await audio.startBell();
      return;
    }

    try {
      _sub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 80),
      ).listen(_onAccel, onError: (_) => _fallbackPlay());
    } catch (_) {
      _fallbackPlay();
    }
  }

  void _onAccel(AccelerometerEvent e) {
    // 重力を除いた加速度の大きさ（絶対値からg相当分を引く）
    final mag = (sqrt(e.x * e.x + e.y * e.y + e.z * e.z) - 9.8).abs();
    _mags.add(mag);
    if (_mags.length > _windowSize) _mags.removeAt(0);
    if (_mags.length < _windowSize) return;

    final mean = _mags.reduce((a, b) => a + b) / _mags.length;
    final variance = _mags.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / _mags.length;

    final walking = variance > _walkThreshold;
    if (walking && !_bellOn) {
      _bellOn = true;
      audio.startBell();
    } else if (!walking && _bellOn) {
      _bellOn = false;
      audio.stopBell();
    }
  }

  void _fallbackPlay() => audio.startBell();

  Future<void> stop() async {
    _running = false;
    _bellOn  = false;
    await _sub?.cancel();
    _sub = null;
    _mags.clear();
    await audio.stopBell();
  }

  // ジオフェンス内に入ったとき外部から即時ミュート
  Future<void> mute()   async => audio.stopBell();
  Future<void> unmute() async { if (_bellOn) audio.startBell(); }
}