import 'package:flutter/material.dart';
import 'motion_bell_service.dart';
import 'emergency_mode.dart';
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

class _MainScreenState extends State<MainScreen> {
  final MotionBellService _bell = MotionBellService();
  final EmergencyMode _emergency = EmergencyMode();
  final SosService _sos = SosService();

  bool _bellEnabled = false;
  bool _emergencyActive = false;
  AppLanguage _lang = AppLanguage.ja;
  String? _statusMessage;
  bool _showOnboarding = true;

  L10n get l => L10n(_lang);

  @override
  void initState() {
    super.initState();
    _emergency.startShakeDetection();
  }

  void _toggleBell(bool value) async {
    setState(() => _bellEnabled = value);
    if (value) {
      await _bell.start();
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
        title: Text(l.get('sosDialogTitle'), style: const TextStyle(color: Colors.white)),
        content: Text(
          '${l.get('sosDialogBody')}\n\n送信先: ${_sos.contact!.name}（${_sos.contact!.phone}）',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.get('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        _showStatus('${l.get('sosSent')}（Webデモ: コンソール出力）');
      case SosResult.noContact:
        _showStatus(l.get('sosNoContact'));
      case SosResult.failed:
        _showStatus('SOS送信に失敗しました');
    }
  }

  void _showStatus(String msg) {
    setState(() => _statusMessage = msg);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _statusMessage = null);
    });
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
        builder: (_, scrollCtrl) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: OnboardingScreen(
            l10n: l,
            onDone: () => Navigator.pop(context),
          ),
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
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // ── ヘッダー ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                children: [
                  const BearBellIcon(size: 36, color: Color(0xFFFFD700)),
                  const SizedBox(width: 12),
                  Text(
                    l.get('appTitle'),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.grey),
                    onPressed: _showHelp,
                    tooltip: '使い方',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.grey),
                    onPressed: _openSettings,
                    tooltip: l.get('settings'),
                  ),
                ],
              ),
            ),

            // ── ステータスメッセージ ──
            if (_statusMessage != null)
              AnimatedOpacity(
                opacity: _statusMessage != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: Text(_statusMessage!, style: const TextStyle(color: Color(0xFFFFD700))),
                ),
              ),

            // ── 予防モードトグル ──
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.get('preventMode'),
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Transform.scale(
                      scale: 2.0,
                      child: Switch(
                        value: _bellEnabled,
                        onChanged: _toggleBell,
                        activeThumbColor: const Color(0xFFFFD700),
                        activeTrackColor: const Color(0xFFB8860B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bellEnabled ? l.get('walkingActive') : l.get('off'),
                      style: TextStyle(
                        color: _bellEnabled ? const Color(0xFFFFD700) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 緊急撃退ボタン ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _emergencyActive
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        minimumSize: const Size.fromHeight(80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.stop, color: Colors.white, size: 32),
                      label: Text(
                        l.get('emergencyActive'),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      onPressed: _deactivateEmergency,
                    )
                  : GestureDetector(
                      onLongPress: _activateEmergency,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC0000),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                              Text(
                                l.get('emergencyBtn'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bell.stop();
    _emergency.dispose();
    super.dispose();
  }
}
