import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeofenceZone {
  final String id;
  final String name;
  final LatLng center;
  final double radiusMeters;

  const GeofenceZone({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'lat': center.latitude, 'lng': center.longitude,
    'radius': radiusMeters,
  };

  factory GeofenceZone.fromJson(Map<String, dynamic> j) => GeofenceZone(
    id: j['id'], name: j['name'],
    center: LatLng(j['lat'] as double, j['lng'] as double),
    radiusMeters: (j['radius'] as num).toDouble(),
  );

  bool contains(LatLng pos) {
    const R = 6371000.0;
    final dLat = _rad(pos.latitude  - center.latitude);
    final dLon = _rad(pos.longitude - center.longitude);
    final a = sin(dLat/2) * sin(dLat/2)
            + cos(_rad(center.latitude)) * cos(_rad(pos.latitude))
            * sin(dLon/2) * sin(dLon/2);
    final dist = R * 2 * atan2(sqrt(a), sqrt(1 - a));
    return dist <= radiusMeters;
  }

  static double _rad(double deg) => deg * pi / 180;
}

class GeofenceService {
  static const _prefsKey = 'geofence_zones_v1';

  final _zonesCtrl = StreamController<List<GeofenceZone>>.broadcast();
  List<GeofenceZone> _zones = [];

  List<GeofenceZone> get zones => List.unmodifiable(_zones);
  Stream<List<GeofenceZone>> get zonesStream => _zonesCtrl.stream;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    _zones = raw
        .map((s) => GeofenceZone.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    _zonesCtrl.add(_zones);
  }

  Future<void> add(GeofenceZone zone) async {
    _zones.add(zone);
    await _persist();
  }

  Future<void> remove(String id) async {
    _zones.removeWhere((z) => z.id == id);
    await _persist();
  }

  bool isInMuteZone(LatLng pos) => _zones.any((z) => z.contains(pos));

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _zones.map((z) => jsonEncode(z.toJson())).toList(),
    );
    _zonesCtrl.add(_zones);
  }

  void dispose() => _zonesCtrl.close();
}