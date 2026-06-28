import 'package:flutter/material.dart';
import 'bear_bell_icon.dart';
import 'l10n.dart';

class OnboardingScreen extends StatefulWidget {
  final L10n l10n;
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.l10n, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pageCount = 5;
  static const _colors = [
    Color(0xFFCC4400),
    Color(0xFFB8860B),
    Color(0xFF1A5C1A),
    Color(0xFFCC0000),
    Color(0xFF1A3A5C),
  ];
  static const _icons = ['🐻', '🔔', '🗺️', '🚨', '⚙️'];
  static const _showBell = [false, true, false, false, false];

  L10n get l => widget.l10n;

  String _title(int i) => l.get('onb${i}Title');
  String _body(int i) => l.get('onb${i}Body');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pageCount,
                itemBuilder: (_, i) => _PageView(
                  icon: _icons[i],
                  title: _title(i),
                  body: _body(i),
                  color: _colors[i],
                  showBell: _showBell[i],
                ),
              ),
            ),

            // インジケーター
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                width: _page == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? const Color(0xFFFFD700) : Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),

            // ボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: Text(l.get('onbBack'), style: const TextStyle(color: Colors.grey)),
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _page < _pageCount - 1
                          ? () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : widget.onDone,
                      child: Text(
                        _page < _pageCount - 1 ? l.get('onbNext') : l.get('onbStart'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _PageView extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  final Color color;
  final bool showBell;

  const _PageView({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.showBell,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 48, height: 4,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 32),

          if (showBell)
            const BearBellIcon(size: 72, color: Color(0xFFFFD700))
          else
            Text(icon, style: const TextStyle(fontSize: 64)),

          const SizedBox(height: 24),

          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 20),

          Text(
            body,
            style: TextStyle(color: Colors.grey[300], fontSize: 15, height: 1.7),
          ),
        ],
      ),
    );
  }
}