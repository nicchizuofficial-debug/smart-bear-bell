import 'package:flutter/material.dart';
import 'audio_service.dart';
import 'bell_settings.dart';
import 'motion_bell_service.dart';
import 'emergency_mode.dart';
import 'geofence_service.dart';
import 'geofence_screen.dart';
import 'sos_service.dart';
import 'l10n.dart';
import 'settings_screen.dart';
import 'bear_bell_icon.dart';
import 'onboarding_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final AudioService _audio;
  late final MotionBellService _bell;
  late final EmergencyMode _emergency;
  final SosService _sos = SosService();
  final GeofenceService _geofence = GeofenceService();
  final BellSettings _bellSettings = BellSettings();

  bool _bellEnabled = false;
  bool _emergencyActive = false;
  AppLanguage _lang = AppLanguage.ja;
  String? _statusMessage;
  bool _showOnboarding = true;

  late AnimationController _emergencyPressCtrl;

  L10n get l => L10n(_lang);

  @override
  void initState() {
    super.initState();
    _audio = AudioService();
    _bell  = MotionBellService(_audio);
    _emergency = EmergencyMode(_audio, onShakeDetected: () {
      if (!_emergencyActive) {
        setState(() => _emergencyActive = true);
        _emergency.activate();
        _sendSos();
      }
    });
    _emergency.startShakeDetection();
    _geofence.load();
    _bellSettings.load();
    _emergencyPressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  void _toggleBell(bool value) async {
    setState(() => _bellEnabled = value);
    if (value) {
      await _bell.start(_bellSettings);
    } else {
      await _bell.stop();
    }
  }

  void _activateEmergency() async {
    setState(() => _emergencyActive = true);
    await _emergency.activate();
    _sendSos();
  }

  void _deactivateEmergency() async {
    await _emergency.deactivate();
    setState(() => _emergencyActive = false);
  }

  Future<void> _sendSos() async {
    if (_sos.contact == null) {
      _showStatus(l.get('sosNoContact'));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.get('sosDialogTitle'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          l.get('sosDialogBody') + '\n\n' + l.get('sosSendTo') + _sos.contact!.name + '（' + _sos.contact!.phone + '）',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.get('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.get('send'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _showStatus(l.get('sosSending'));
    final result = await _sos.sendSos(l.get('sosMessage'));
    switch (result) {
      case SosResult.sent:
        _showStatus(l.get('sosSent'));
      case SosResult.webDemo:
        _showStatus(l.get('sosSent') + l.get('sosWebDemoNote'));
      case SosResult.noContact:
        _showStatus(l.get('sosNoContact'));
      case SosResult.failed:
        _showStatus(l.get('sosFailed'));
    }
  }

  void _showStatus(String msg) {
    setState(() => _statusMessage = msg);
    Future.delayed(const Duration(seconds: 4),
        () { if (mounted) setState(() => _statusMessage = null); });
  }

  void _openGeofenceMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeofenceScreen(geofenceService: _geofence, l10n: l),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, __) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: OnboardingScreen(l10n: l, onDone: () => Navigator.pop(context)),
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          l10n: l,
          sosService: _sos,
          currentLang: _lang,
          onLanguageChanged: (lang) {
            setState(() => _lang = lang);
            Navigator.pop(context);
          },
          bellSettings: _bellSettings,
          audioService: _audio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        l10n: l,
        onDone: () => setState(() => _showOnboarding = false),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // ── 背景グラデーション ──
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    const Color(0xFF1A1200),
                    const Color(0xFF0A0A0A),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── ヘッダー ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Row(
                    children: [
                      const BearBellIcon(size: 38, color: Color(0xFFFFD700)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.get('appTitle'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            l.get('appSubtitle'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.map_outlined, color: Color(0xFF666666), size: 22),
                        onPressed: _openGeofenceMap,
                        tooltip: l.get('geofenceTitle'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Color(0xFF666666), size: 22),
                        onPressed: _showHelp,
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Color(0xFF666666), size: 22),
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                ),

                // ── ステータスバナー ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _statusMessage != null
                      ? Container(
                          key: ValueKey(_statusMessage),
                          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1500),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_statusMessage!,
                                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13)),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // ── メインエリア ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      children: [
                        // 予防モードカード
                        _BellCard(
                          enabled: _bellEnabled,
                          label: l.get('preventMode'),
                          statusText: _bellEnabled ? l.get('walkingActive') : l.get('off'),
                          onChanged: _toggleBell,
                        ),

                        const SizedBox(height: 16),

                        // 危険度インジケーター（静的デモ）
                        _RiskCard(l10n: l),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // ── 緊急撃退ボタン ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: _emergencyActive
                      ? _ActiveEmergencyButton(
                          label: l.get('emergencyActive'),
                          onTap: _deactivateEmergency,
                        )
                      : _EmergencyButton(
                          label: l.get('emergencyBtn'),
                          onLongPress: _activateEmergency,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bell.stop();
    _emergency.dispose();
    _audio.dispose();
    _geofence.dispose();
    _emergencyPressCtrl.dispose();
    super.dispose();
  }
}

// ── 予防モードカード ──
class _BellCard extends StatelessWidget {
  final bool enabled;
  final String label;
  final String statusText;
  final ValueChanged<bool> onChanged;

  const _BellCard({
    required this.enabled,
    required this.label,
    required this.statusText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF1A1500) : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? const Color(0xFFFFD700).withValues(alpha: 0.4)
              : const Color(0xFF2A2A2A),
          width: 1.5,
        ),
        boxShadow: enabled
            ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                blurRadius: 20, spreadRadius: 2)]
            : [],
      ),
      child: Row(
        children: [
          // アイコン
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFF2A2000) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: BearBellIcon(
                size: 30,
                color: enabled ? const Color(0xFFFFD700) : const Color(0xFF444444),
                ringing: enabled,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // テキスト
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(statusText,
                    style: TextStyle(
                      color: enabled ? const Color(0xFFFFD700) : Colors.grey[700],
                      fontSize: 12,
                    )),
              ],
            ),
          ),
          // トグル
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: enabled,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF0A0A0A),
              activeTrackColor: const Color(0xFFFFD700),
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: const Color(0xFF2A2A2A),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 危険度インジケーター（デモ） ──
class _RiskCard extends StatelessWidget {
  final L10n l10n;
  const _RiskCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final isHighRisk = (hour >= 4 && hour <= 7) || (hour >= 17 && hour <= 20);
    final riskLevel = isHighRisk ? 0.72 : 0.35;
    final riskLabel = isHighRisk ? l10n.get('riskHigh') : l10n.get('riskLow');
    final riskColor = isHighRisk ? const Color(0xFFFF6600) : const Color(0xFF44AA44);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF888888), size: 16),
              const SizedBox(width: 6),
              Text(l10n.get('riskTitle'),
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const Spacer(),
              Text(riskLabel,
                  style: TextStyle(
                    color: riskColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: riskLevel,
              minHeight: 6,
              backgroundColor: const Color(0xFF2A2A2A),
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHighRisk ? l10n.get('riskHighMsg') : l10n.get('riskLowMsg'),
            style: const TextStyle(color: Color(0xFF666666), fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── 緊急撃退ボタン（待機中）──
class _EmergencyButton extends StatefulWidget {
  final String label;
  final VoidCallback onLongPress;
  const _EmergencyButton({required this.label, required this.onLongPress});

  @override
  State<_EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<_EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _progress = _ctrl;
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onLongPress();
        _ctrl.reset();
        setState(() => _pressing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() => _pressing = true);
        _ctrl.forward();
      },
      onLongPressEnd: (_) {
        if (_ctrl.status != AnimationStatus.completed) {
          _ctrl.reset();
          setState(() => _pressing = false);
        }
      },
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, __) => Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [const Color(0xFF8B0000), const Color(0xFFCC0000)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _pressing
                  ? Colors.red.withValues(alpha: 0.8)
                  : const Color(0xFF660000),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: _pressing ? 0.3 : 0.15),
                blurRadius: _pressing ? 24 : 12,
                spreadRadius: _pressing ? 2 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 長押しプログレス
              if (_pressing)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: LinearProgressIndicator(
                      value: _progress.value,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(Color(0x33FFFFFF)),
                      minHeight: 80,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ── 緊急撃退ボタン（発動中）──
class _ActiveEmergencyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _ActiveEmergencyButton({required this.label, required this.onTap});

  @override
  State<_ActiveEmergencyButton> createState() => _ActiveEmergencyButtonState();
}

class _ActiveEmergencyButtonState extends State<_ActiveEmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Color.lerp(const Color(0xFFCC0000), const Color(0xFFFF2222), _pulse.value),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3 + _pulse.value * 0.2),
                blurRadius: 20 + _pulse.value * 16,
                spreadRadius: _pulse.value * 4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }
}
