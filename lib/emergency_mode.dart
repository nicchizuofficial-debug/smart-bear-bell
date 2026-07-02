import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'audio_service.dart';

class EmergencyMode {
  final AudioService audio;
  final VoidCallback? onShakeDetected;

  EmergencyMode(this.audio, {this.onShakeDetected});

  bool _active = false;
  bool get isActive => _active;

  StreamSubscription<AccelerometerEvent>? _shakeSub;
  Timer? _strobeTimer;
  bool _torchOn = false;
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
    _startStrobe();
  }

  Future<void> deactivate() async {
    _active = false;
    await audio.stopRepel();
    await _stopStrobe();
  }

  void _startStrobe() {
    if (kIsWeb) return;
    _strobeTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      try {
        _torchOn = !_torchOn;
        if (_torchOn) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
      } catch (_) {}
    });
  }

  Future<void> _stopStrobe() async {
    _strobeTimer?.cancel();
    _strobeTimer = null;
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
    _torchOn = false;
  }

  void dispose() {
    _shakeSub?.cancel();
    _strobeTimer?.cancel();
  }
}