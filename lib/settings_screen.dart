import 'package:flutter/material.dart';
import 'l10n.dart';
import 'sos_service.dart';

class SettingsScreen extends StatefulWidget {
  final L10n l10n;
  final SosService sosService;
  final AppLanguage currentLang;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.l10n,
    required this.sosService,
    required this.currentLang,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.sosService.contact?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.sosService.contact?.phone ?? '');
  }

  void _save() {
    widget.sosService.setContact(
      SosContact(name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim()),
    );
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l10n;
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
          Text(l.get('language'),
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
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

          const SizedBox(height: 36),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 24),

          // ── SOS連絡先 ──
          Text(l.get('sosTitle'),
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildField(l.get('sosName'), _nameCtrl, TextInputType.name),
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
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFFD700)),
        ),
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
