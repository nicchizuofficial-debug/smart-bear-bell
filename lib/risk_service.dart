import 'package:latlong2/latlong.dart';
import 'sighting_service.dart';

enum RiskLevel { low, medium, high }

class RiskFactor {
  final String labelKey;
  final String valueKey;
  final int score;   // 0–100 (このfactorの達成率)
  final int weight;  // 全体への最大寄与点数

  const RiskFactor({
    required this.labelKey,
    required this.valueKey,
    required this.score,
    required this.weight,
  });
}

class RiskResult {
  final int totalScore; // 0–100
  final RiskLevel level;
  final List<RiskFactor> factors;

  const RiskResult({
    required this.totalScore,
    required this.level,
    required this.factors,
  });

  String get levelKey => switch (level) {
        RiskLevel.low    => 'riskLow',
        RiskLevel.medium => 'riskMedium',
        RiskLevel.high   => 'riskHigh',
      };

  String get msgKey => switch (level) {
        RiskLevel.low    => 'riskLowMsg',
        RiskLevel.medium => 'riskMediumMsg',
        RiskLevel.high   => 'riskHighMsg',
      };
}

class RiskService {
  /// 時刻・季節・目撃情報 の3要素でリスクスコア(0–100)を算出
  static RiskResult calculate({
    DateTime? now,
    LatLng? userLocation,
    SightingService? sightings,
  }) {
    final t = now ?? DateTime.now();

    // ── 1. 時刻 (最大35点) ──
    final hour = t.hour;
    final int timeRaw;
    final String timeKey;
    if (hour >= 4 && hour < 7) {
      timeRaw = 35; timeKey = 'riskTimeDawn';      // 夜明け
    } else if (hour >= 17 && hour < 20) {
      timeRaw = 30; timeKey = 'riskTimeDusk';      // 夕暮れ
    } else if (hour < 4 || hour >= 20) {
      timeRaw = 18; timeKey = 'riskTimeNight';     // 深夜
    } else if (hour >= 10 && hour < 14) {
      timeRaw = 5;  timeKey = 'riskTimeMidday';    // 正午前後
    } else {
      timeRaw = 12; timeKey = 'riskTimeDay';       // 日中
    }

    // ── 2. 季節 (最大25点) ──
    final month = t.month;
    final int seasonRaw;
    final String seasonKey;
    if (month >= 3 && month <= 5) {
      seasonRaw = 25; seasonKey = 'riskSeasonSpring';  // 春：冬眠明け・空腹
    } else if (month >= 9 && month <= 11) {
      seasonRaw = 22; seasonKey = 'riskSeasonAutumn';  // 秋：冬眠前の爆食
    } else if (month >= 6 && month <= 8) {
      seasonRaw = 10; seasonKey = 'riskSeasonSummer';  // 夏：比較的安定
    } else {
      seasonRaw = 5;  seasonKey = 'riskSeasonWinter';  // 冬：冬眠中
    }

    // ── 3. 近くの目撃情報 (最大40点) ──
    int sightingRaw = 0;
    String sightingKey = 'riskNoSighting';

    if (userLocation != null && sightings != null) {
      const dist = Distance();
      double minKm = double.infinity;
      int minDays = 999;

      for (final s in sightings.all.where((s) => s.isThisMonth)) {
        final km = dist.as(LengthUnit.Kilometer, userLocation, s.latLng);
        if (km < minKm) { minKm = km; minDays = s.daysAgo; }
      }

      if (minKm <= 5 && minDays <= 7) {
        sightingRaw = 40; sightingKey = 'riskSightingVeryNear';
      } else if (minKm <= 10 && minDays <= 7) {
        sightingRaw = 30; sightingKey = 'riskSightingNear';
      } else if (minKm <= 5) {
        sightingRaw = 25; sightingKey = 'riskSightingNear';
      } else if (minKm <= 10) {
        sightingRaw = 15; sightingKey = 'riskSightingFar';
      } else if (minKm <= 20) {
        sightingRaw = 8;  sightingKey = 'riskSightingFar';
      }
    } else {
      // GPS未取得：目撃情報は中立(考慮しない)
      sightingKey = 'riskSightingUnknown';
    }

    // 合計（最大100）
    final total = (timeRaw + seasonRaw + sightingRaw).clamp(0, 100);
    final level = total >= 60 ? RiskLevel.high
                : total >= 30 ? RiskLevel.medium
                : RiskLevel.low;

    return RiskResult(
      totalScore: total,
      level: level,
      factors: [
        RiskFactor(
          labelKey: 'riskFactorTime',
          valueKey: timeKey,
          score: (timeRaw / 35 * 100).round(),
          weight: 35,
        ),
        RiskFactor(
          labelKey: 'riskFactorSeason',
          valueKey: seasonKey,
          score: (seasonRaw / 25 * 100).round(),
          weight: 25,
        ),
        RiskFactor(
          labelKey: 'riskFactorSighting',
          valueKey: sightingKey,
          score: userLocation != null ? (sightingRaw / 40 * 100).round() : -1,
          weight: 40,
        ),
      ],
    );
  }
}
