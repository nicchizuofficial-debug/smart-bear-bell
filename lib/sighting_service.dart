import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BearSighting {
  final String id;
  final double lat, lng;
  final String prefecture;
  final String city;
  final DateTime date;
  final String source; // 'official' | 'user'
  final String desc;

  const BearSighting({
    required this.id,
    required this.lat,
    required this.lng,
    required this.prefecture,
    required this.city,
    required this.date,
    required this.source,
    required this.desc,
  });

  LatLng get latLng => LatLng(lat, lng);

  int get daysAgo => DateTime.now().difference(date).inDays;
  bool get isThisWeek  => daysAgo <= 7;
  bool get isThisMonth => daysAgo <= 30;

  factory BearSighting.fromJson(Map<String, dynamic> j) => BearSighting(
        id:         j['id'] as String,
        lat:        (j['lat'] as num).toDouble(),
        lng:        (j['lng'] as num).toDouble(),
        prefecture: j['prefecture'] as String,
        city:       j['city'] as String,
        date:       DateTime.parse(j['date'] as String),
        source:     j['source'] as String,
        desc:       j['desc'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id':         id,
        'lat':        lat,
        'lng':        lng,
        'prefecture': prefecture,
        'city':       city,
        'date':       date.toIso8601String().substring(0, 10),
        'source':     source,
        'desc':       desc,
      };
}

class SightingService {
  static const _kUserKey = 'user_sightings';

  final List<BearSighting> _official = [];
  final List<BearSighting> _user     = [];

  List<BearSighting> get all => [..._official, ..._user]
    ..sort((a, b) => b.date.compareTo(a.date));

  /// 7日以内に半径 radiusKm 以内に目撃情報があるか
  bool hasRecentNearby(LatLng pos, {double radiusKm = 10}) {
    const dist = Distance();
    return all.any((s) =>
        s.isThisMonth &&
        dist.as(LengthUnit.Kilometer, pos, s.latLng) <= radiusKm);
  }

  int countNearby(LatLng pos, {double radiusKm = 10}) {
    const dist = Distance();
    return all.where((s) =>
        s.isThisMonth &&
        dist.as(LengthUnit.Kilometer, pos, s.latLng) <= radiusKm).length;
  }

  Future<void> load() async {
    // 公式データ（アセット）
    final raw = await rootBundle.loadString('assets/data/sightings.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    _official.clear();
    for (final item in (data['sightings'] as List)) {
      _official.add(BearSighting.fromJson(item as Map<String, dynamic>));
    }

    // ユーザー報告（SharedPreferences）
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kUserKey);
    if (saved != null) {
      _user.clear();
      for (final item in json.decode(saved) as List) {
        _user.add(BearSighting.fromJson(item as Map<String, dynamic>));
      }
    }
  }

  Future<void> addUserSighting(BearSighting s) async {
    _user.insert(0, s);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, json.encode(_user.map((e) => e.toJson()).toList()));
  }

  Future<void> removeUserSighting(String id) async {
    _user.removeWhere((s) => s.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, json.encode(_user.map((e) => e.toJson()).toList()));
  }
}
