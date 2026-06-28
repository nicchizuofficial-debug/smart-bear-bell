import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'bell_settings.dart';

class AudioService {
  final _bell  = AudioPlayer();
  final _repel = AudioPlayer();
  String _currentAsset = '';
  bool _ready = false;

  Future<void> init(BellSettings settings) async {
    try {
      final asset = settings.soundType.asset;
      if (!_ready || _currentAsset != asset) {
        await _bell.setAsset(asset);
        await _bell.setLoopMode(LoopMode.one);
        _currentAsset = asset;
      }
      if (!_ready) {
        await _repel.setAsset('assets/audio/repel.wav');
        await _repel.setLoopMode(LoopMode.one);
        _ready = true;
      }
      await _bell.setVolume(settings.volume);
    } catch (e) {
      debugPrint('[Audio] init error: $e');
    }
  }

  // 設定変更時に即時反映
  Future<void> applySettings(BellSettings settings) async {
    final asset = settings.soundType.asset;
    final wasPlaying = _bell.playing;
    try {
      if (_currentAsset != asset) {
        if (wasPlaying) await _bell.stop();
        await _bell.setAsset(asset);
        await _bell.setLoopMode(LoopMode.one);
        _currentAsset = asset;
        if (wasPlaying) {
          await _bell.seek(Duration.zero);
          await _bell.play();
        }
      }
      await _bell.setVolume(settings.volume);
    } catch (e) {
      debugPrint('[Audio] applySettings error: $e');
    }
  }

  Future<void> startBell() async {
    if (_bell.playing) return;
    await _bell.seek(Duration.zero);
    await _bell.play();
  }

  Future<void> stopBell() async {
    if (_bell.playing) await _bell.stop();
  }

  Future<void> startRepel() async {
    await _repel.seek(Duration.zero);
    await _repel.play();
  }

  Future<void> stopRepel() async {
    await _repel.stop();
  }

  // 設定画面からのプレビュー再生（1回だけ）
  Future<void> previewBell(BellSettings settings) async {
    try {
      final asset = settings.soundType.asset;
      await _bell.setAsset(asset);
      await _bell.setLoopMode(LoopMode.off);
      await _bell.setVolume(settings.volume);
      _currentAsset = asset;
      await _bell.seek(Duration.zero);
      await _bell.play();
      await _bell.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed);
      await _bell.setLoopMode(LoopMode.one);
    } catch (_) {}
  }

  void dispose() {
    _bell.dispose();
    _repel.dispose();
  }
}