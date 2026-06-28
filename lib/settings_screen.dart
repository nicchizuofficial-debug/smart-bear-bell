import 'package:flutter/material.dart';
import 'l10n.dart';
import 'sos_service.dart';
import 'audio_service.dart';
import 'bell_settings.dart';

class SettingsScreen extends StatefulWidget {
  final L10n l10n;
  final SosService sosService;
  final AppLanguage currentLang;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final BellSettings bellSettings;
  final AudioService audioService;

  const SettingsScreen({
    super.key,
    required this.l10n,
    required this.sosService,
    required this.currentLang,
    required this.onLanguageChanged,
    required this.bellSettings,
    required this.audioService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saved = false;
  bool _previewing = false;

  // ローカル状態（保存前にリアルタイム反映）
  late double _volume;
  late BellSoundType _soundType;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.sosService.contact?.name  ?? '');
    _phoneCtrl = TextEditingController(text: widget.sosService.contact?.phone ?? '');
    _volume    = widget.bellSettings.volume;
    _soundType = widget.bellSettings.soundType;
  }

  L10n get l => widget.l10n;

  void _save() {
    widget.sosService.setContact(
      SosContact(name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim()),
    );
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _onVolumeChanged(double v) async {
    setState(() => _volume = v);
    await widget.bellSettings.setVolume(v);
    await widget.audioService.applySettings(widget.bellSettings);
  }

  Future<void> _onSoundChanged(BellSoundType t) async {
    setState(() => _soundType = t);
    await widget.bellSettings.setSoundType(t);
    await widget.audioService.applySettings(widget.bellSettings);
  }

  Future<void> _preview() async {
    if (_previewing) return;
    setState(() => _previewing = true);
    await widget.audioService.previewBell(widget.bellSettings);
    if (mounted) setState(() => _previewing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(l.get('settings'), style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          // ── 言語選択 ──
          _sectionLabel(l.get('language')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: AppLanguage.values.map((lang) {
              final selected = lang == widget.currentLang;
              return ChoiceChip(
                label: Text(L10n.langLabels[lang]!),
                selected: selected,
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF1A1A1A),
                labelStyle: TextStyle(color: selected ? Colors.black : Colors.white),
                onSelected: (_) => widget.onLanguageChanged(lang),
              );
            }).toList(),
          ),

          _divider(),

          // ── 鈴音の種類 ──
          _sectionLabel(l.get('bellSound')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: BellSoundType.values.map((t) {
              final selected = t == _soundType;
              return ChoiceChip(
                label: Text(l.get(t.l10nKey)),
                selected: selected,
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF1A1A1A),
                labelStyle: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                onSelected: (_) => _onSoundChanged(t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── 試聴ボタン ──
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF444444)),
              foregroundColor: const Color(0xFFFFD700),
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _previewing ? null : _preview,
            icon: _previewing
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)))
                : const Icon(Icons.play_circle_outline, size: 18),
            label: Text(l.get('bellPreview')),
          ),

          _divider(),

          // ── 音量 ──
          Row(
            children: [
              _sectionLabel(l.get('bellVolume')),
              const Spacer(),
              Text('${(_volume * 100).round()}%',
                  style: const TextStyle(color: Color(0xFFFFD700),
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFFD700),
              inactiveTrackColor: const Color(0xFF333333),
              thumbColor: const Color(0xFFFFD700),
              overlayColor: const Color(0x33FFD700),
              trackHeight: 4,
            ),
            child: Slider(
              value: _volume,
              min: 0.0, max: 1.0,
              divisions: 10,
              onChanged: _onVolumeChanged,
            ),
          ),

          _divider(),

          // ── SOS連絡先 ──
          _sectionLabel(l.get('sosTitle')),
          const SizedBox(height: 16),
          _buildField(l.get('sosName'),  _nameCtrl,  TextInputType.name),
          const SizedBox(height: 12),
          _buildField(l.get('sosPhone'), _phoneCtrl, TextInputType.phone),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _save,
            child: Text(_saved ? l.get('sosSaved') : l.get('sosSave'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(color: Color(0xFFFFD700),
          fontSize: 14, fontWeight: FontWeight.bold));

  Widget _divider() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(color: Color(0xFF2A2A2A)));

  Widget _buildField(String label, TextEditingController ctrl, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF333333))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF333333))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFFFD700))),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }
}