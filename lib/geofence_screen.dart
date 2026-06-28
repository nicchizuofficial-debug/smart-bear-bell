import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'geofence_service.dart';
import 'l10n.dart';

class GeofenceScreen extends StatefulWidget {
  final GeofenceService geofenceService;
  final L10n l10n;

  const GeofenceScreen({
    super.key,
    required this.geofenceService,
    required this.l10n,
  });

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  final _mapCtrl = MapController();
  LatLng? _pendingPoint;
  double _pendingRadius = 150;
  final _nameCtrl = TextEditingController();

  static const _defaultCenter = LatLng(35.6762, 139.6503); // 東京

  L10n get l => widget.l10n;

  @override
  Widget build(BuildContext context) {
    final zones = widget.geofenceService.zones;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(l.get('geofenceTitle'),
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFFFFD700)),
            onPressed: _goToMyLocation,
            tooltip: l.get('geofenceMyLocation'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── 地図 ──
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 14,
              onTap: (_, latLng) => _onMapTap(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'jp.nicchizu.smartbearbell',
              ),
              // 登録済みゾーン
              CircleLayer(
                circles: [
                  for (final z in zones)
                    CircleMarker(
                      point: z.center,
                      radius: z.radiusMeters,
                      useRadiusInMeter: true,
                      color: const Color(0x3300AAFF),
                      borderColor: const Color(0xFF0088FF),
                      borderStrokeWidth: 2,
                    ),
                  // プレビュー
                  if (_pendingPoint != null)
                    CircleMarker(
                      point: _pendingPoint!,
                      radius: _pendingRadius,
                      useRadiusInMeter: true,
                      color: const Color(0x44FFD700),
                      borderColor: const Color(0xFFFFD700),
                      borderStrokeWidth: 2,
                    ),
                ],
              ),
              // ゾーン名ラベル
              MarkerLayer(
                markers: [
                  for (final z in zones)
                    Marker(
                      point: z.center,
                      width: 120,
                      height: 32,
                      child: GestureDetector(
                        onLongPress: () => _confirmDelete(z),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xCC0D0D0D),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0088FF), width: 1),
                          ),
                          child: Text(z.name,
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  if (_pendingPoint != null)
                    Marker(
                      point: _pendingPoint!,
                      width: 32, height: 32,
                      child: const Icon(Icons.location_pin, color: Color(0xFFFFD700), size: 32),
                    ),
                ],
              ),
            ],
          ),

          // ── ヒントテキスト ──
          if (zones.isEmpty && _pendingPoint == null)
            Positioned(
              top: 12, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xCC1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(l.get('geofenceHint'),
                      style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
                ),
              ),
            ),

          // ── 登録済みリスト（下部パネル）──
          if (zones.isNotEmpty)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: const BoxDecoration(
                  color: Color(0xEE0D0D0D),
                  border: Border(top: BorderSide(color: Color(0xFF222222))),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: zones.length,
                  itemBuilder: (_, i) {
                    final z = zones[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.volume_off, color: Color(0xFF0088FF), size: 18),
                      title: Text(z.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text('${z.radiusMeters.round()} m',
                          style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFF664444), size: 20),
                        onPressed: () => _confirmDelete(z),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _pendingPoint = latLng;
      _nameCtrl.clear();
    });
    _showAddSheet(latLng);
  }

  void _showAddSheet(LatLng latLng) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.get('geofenceAddTitle'),
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l.get('geofenceName'),
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true, fillColor: const Color(0xFF0D0D0D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF333333))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF333333))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFFD700))),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(l.get('geofenceRadius'),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const Spacer(),
                  Text('${_pendingRadius.round()} m',
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _pendingRadius,
                min: 50, max: 500,
                divisions: 9,
                activeColor: const Color(0xFFFFD700),
                inactiveColor: const Color(0xFF333333),
                onChanged: (v) {
                  setModalState(() => _pendingRadius = v);
                  setState(() => _pendingRadius = v);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        setState(() => _pendingPoint = null);
                        Navigator.pop(ctx);
                      },
                      child: Text(l.get('cancel'),
                          style: const TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      onPressed: () async {
                        final name = _nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        await widget.geofenceService.add(GeofenceZone(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          center: latLng,
                          radiusMeters: _pendingRadius,
                        ));
                        if (!mounted) return;
                        setState(() => _pendingPoint = null);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(l.get('geofenceSave'),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(GeofenceZone zone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.get('geofenceDeleteTitle'),
            style: const TextStyle(color: Colors.white)),
        content: Text('"${zone.name}" ${l.get('geofenceDeleteMsg')}',
            style: TextStyle(color: Colors.grey[400])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.get('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await widget.geofenceService.remove(zone.id);
              if (!mounted) return;
              setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l.get('geofenceDelete'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      );
      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 16);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.get('geofenceLocationError')),
              backgroundColor: const Color(0xFF333333)),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}