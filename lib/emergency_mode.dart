import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'audio_service.dart';

class EmergencyMode {
  final AudioService audio;
  final VoidCallback? onShakeDetected;

  EmergencyMode(this.audio, {this.onShakeDetected});

  bool _active = false;
  bool get isActive => _active;

  StreamSubscription<AccelerometerEvent>? _shakeSub;
  DateTime? _lastShake;

  void startShakeDetection() {
    if (kIsWeb) return;
    try {
      _shakeSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 50),
      ).listen((e) {
        final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
        if (mag > 25) {
          final now = DateTime.now();
          if (_lastShake == null ||
              now.difference(_lastShake!) > const Duration(seconds: 2)) {
            _lastShake = now;
            onShakeDetected?.call();
          }
        }
      });
    } catch (_) {}
  }

  Future<void> activate() async {
    _active = true;
    await audio.startRepel();
  }

  Future<void> deactivate() async {
    _active = false;
    await audio.stopRepel();
  }

  void dispose() {
    _shakeSub?.cancel();
  }
}