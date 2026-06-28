import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'sighting_service.dart';
import 'l10n.dart';

class SightingScreen extends StatefulWidget {
  final SightingService service;
  final L10n l10n;
  const SightingScreen({super.key, required this.service, required this.l10n});

  @override
  State<SightingScreen> createState() => _SightingScreenState();
}

class _SightingScreenState extends State<SightingScreen> {
  final _mapCtrl = MapController();
  BearSighting? _selected;
  // フィルター: 0=全期間 1=今月 2=今週
  int _filter = 0;

  L10n get l => widget.l10n;

  List<BearSighting> get _filtered {
    final all = widget.service.all;
    return switch (_filter) {
      1 => all.where((s) => s.isThisMonth).toList(),
      2 => all.where((s) => s.isThisWeek).toList(),
      _ => all,
    };
  }

  Color _markerColor(BearSighting s) {
    if (s.isThisWeek)  return Colors.red;
    if (s.isThisMonth) return Colors.orange;
    return Colors.grey;
  }

  Future<void> _goToMyLocation() async {
    if (kIsWeb) return;
    try {
      final pos = await Geolocator.getCurrentPosition();
      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 13);
    } catch (_) {}
  }

  void _showAddDialog(LatLng pos) {
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.get('sightingAddTitle'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l.get('sightingDescHint'),
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.get('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final s = BearSighting(
                id:         'u${DateTime.now().millisecondsSinceEpoch}',
                lat:        pos.latitude,
                lng:        pos.longitude,
                prefecture: '',
                city:       l.get('sightingUserReport'),
                date:       DateTime.now(),
                source:     'user',
                desc:       descCtrl.text.isEmpty ? l.get('sightingNoDesc') : descCtrl.text,
              );
              await widget.service.addUserSighting(s);
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(l.get('sightingReport'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sightings = _filtered;
    final filterLabels = [l.get('sightingAll'), l.get('sightingMonth'), l.get('sightingWeek')];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        foregroundColor: Colors.white,
        title: Text(l.get('sightingTitle'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${sightings.length}${l.get('sightingCount')}',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // フィルターチップ
        Container(
          color: const Color(0xFF141414),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(children: [
            for (int i = 0; i < filterLabels.length; i++) ...[
              GestureDetector(
                onTap: () => setState(() { _filter = i; _selected = null; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _filter == i ? const Color(0xFFFFD700) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(filterLabels[i],
                      style: TextStyle(
                        color: _filter == i ? Colors.black : Colors.white,
                        fontSize: 13,
                        fontWeight: _filter == i ? FontWeight.bold : FontWeight.normal,
                      )),
                ),
              ),
              if (i < filterLabels.length - 1) const SizedBox(width: 8),
            ],
            const Spacer(),
            // 凡例
            _LegendDot(color: Colors.red,    label: l.get('sightingWeek')),
            const SizedBox(width: 10),
            _LegendDot(color: Colors.orange, label: l.get('sightingMonth')),
            const SizedBox(width: 10),
            _LegendDot(color: Colors.grey,   label: l.get('sightingOld')),
          ]),
        ),

        // 地図
        Expanded(
          child: Stack(children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: const LatLng(37.5, 137.5),
                initialZoom: 5.5,
                onTap: (_, pos) {
                  if (_selected != null) {
                    setState(() => _selected = null);
                  } else {
                    _showAddDialog(pos);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'jp.nicchizu.smartbearbell',
                ),
                MarkerLayer(
                  markers: sightings.map((s) {
                    final isSelected = _selected?.id == s.id;
                    return Marker(
                      point: s.latLng,
                      width: isSelected ? 44 : 32,
                      height: isSelected ? 44 : 32,
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _markerColor(s),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isSelected ? 3 : 1.5),
                            boxShadow: isSelected
                                ? [BoxShadow(color: _markerColor(s).withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 3)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              s.source == 'user' ? '👤' : '🐻',
                              style: TextStyle(fontSize: isSelected ? 18 : 13),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // 現在地ボタン
            Positioned(
              right: 16,
              bottom: _selected != null ? 200 : 80,
              child: FloatingActionButton.small(
                heroTag: 'location',
                backgroundColor: const Color(0xFF1A1A1A),
                onPressed: _goToMyLocation,
                child: const Icon(Icons.my_location, color: Color(0xFFFFD700)),
              ),
            ),

            // 目撃報告ボタン
            Positioned(
              right: 16,
              bottom: _selected != null ? 260 : 140,
              child: FloatingActionButton.small(
                heroTag: 'report',
                backgroundColor: const Color(0xFF1A1A1A),
                onPressed: () => _showAddDialog(_mapCtrl.camera.center),
                tooltip: l.get('sightingReport'),
                child: const Icon(Icons.add_location_alt, color: Colors.orange),
              ),
            ),

            // 選択パネル
            if (_selected != null)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _SightingDetailPanel(
                  sighting: _selected!,
                  l10n: l,
                  onClose: () => setState(() => _selected = null),
                  onDelete: _selected!.source == 'user'
                      ? () async {
                          await widget.service.removeUserSighting(_selected!.id);
                          setState(() => _selected = null);
                        }
                      : null,
                ),
              ),

            // ヒント
            if (_selected == null)
              Positioned(
                top: 12, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(l.get('sightingHint'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    ],
  );
}

class _SightingDetailPanel extends StatelessWidget {
  final BearSighting sighting;
  final L10n l10n;
  final VoidCallback onClose;
  final VoidCallback? onDelete;
  const _SightingDetailPanel({
    required this.sighting,
    required this.l10n,
    required this.onClose,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = l10n;
    final s = sighting;
    final daysStr = s.daysAgo == 0 ? l.get('sightingToday') : '${s.daysAgo}${l.get('sightingDaysAgo')}';
    final sourceLabel = s.source == 'official' ? l.get('sightingOfficial') : l.get('sightingUser');
    final sourceColor = s.source == 'official' ? Colors.blue : Colors.orange;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sourceColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sourceColor, width: 1),
            ),
            child: Text(sourceLabel, style: TextStyle(color: sourceColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: s.isThisWeek
                  ? Colors.red.withValues(alpha: 0.2)
                  : s.isThisMonth
                      ? Colors.orange.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(daysStr,
                style: TextStyle(
                  color: s.isThisWeek ? Colors.red : s.isThisMonth ? Colors.orange : Colors.grey,
                  fontSize: 12,
                )),
          ),
          const Spacer(),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          s.prefecture.isNotEmpty ? '${s.prefecture} ${s.city}' : s.city,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${s.date.year}/${s.date.month.toString().padLeft(2,'0')}/${s.date.day.toString().padLeft(2,'0')}',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Text(s.desc, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14, height: 1.6)),
      ]),
    );
  }
}
