import 'package:shared_preferences/shared_preferences.dart';

enum BellSoundType { bear, iron, electronic }

extension BellSoundTypeAsset on BellSoundType {
  String get asset => switch (this) {
    BellSoundType.bear       => 'assets/audio/bell.wav',
    BellSoundType.iron       => 'assets/audio/iron_bell.wav',
    BellSoundType.electronic => 'assets/audio/electronic.wav',
  };
  String get l10nKey => switch (this) {
    BellSoundType.bear       => 'soundBear',
    BellSoundType.iron       => 'soundIron',
    BellSoundType.electronic => 'soundElectronic',
  };
}

class BellSettings {
  static const _kVolume = 'bell_volume';
  static const _kSound  = 'bell_sound_type';

  double _volume         = 0.7;
  BellSoundType _sound   = BellSoundType.bear;

  double        get volume    => _volume;
  BellSoundType get soundType => _sound;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _volume = p.getDouble(_kVolume) ?? 0.7;
    final idx = p.getInt(_kSound) ?? 0;
    _sound = BellSoundType.values[idx.clamp(0, BellSoundType.values.length - 1)];
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kVolume, _volume);
  }

  Future<void> setSoundType(BellSoundType t) async {
    _sound = t;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSound, t.index);
  }
}