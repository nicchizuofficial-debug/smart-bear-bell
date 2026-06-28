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

  // チュートリアルのページ定義
  static const _pages = [
    _Page(
      icon: '🐻',
      title: '街に熊が出没しています',
      body: '近年、全国の市街地・住宅街・公園でツキノワグマの目撃が急増しています。\n\nSmart Bear Bell はあなたと熊との不意な遭遇を防ぎ、万が一の遭遇時の生存率を高めるアプリです。',
      color: Color(0xFFCC4400),
    ),
    _Page(
      icon: '🔔',
      title: '予防モード（スマート鈴）',
      body: '画面中央のトグルをONにすると、\n歩行中だけ自動で鈴音が鳴ります。\n\n止まると自動でフェードアウト。\n音はランダムに変化するため、熊が「慣れる」のを防ぎます。',
      color: Color(0xFFB8860B),
      showBell: true,
    ),
    _Page(
      icon: '🗺️',
      title: 'ジオフェンス自動ミュート',
      body: '設定から「鳴らさないエリア」を登録できます。\n\n自宅・職場・スーパーなど安全な場所に入ると自動でミュート。\n緑地帯・河川敷に入ると自動でONになります。',
      color: Color(0xFF1A5C1A),
    ),
    _Page(
      icon: '🚨',
      title: '緊急撃退モード',
      body: 'クマと遭遇したら——\n\n① 画面下部の赤いボタンを長押し\nまたは\n② スマホを激しく振る\n\nLEDストロボ＋大音量撃退音で威嚇します。\n登録した連絡先にGPS付きSOSも自動送信。',
      color: Color(0xFFCC0000),
    ),
    _Page(
      icon: '⚙️',
      title: '使い始める前に設定を',
      body: '右上の ⚙️ 設定ボタンから\n\n✅ 緊急SOS連絡先を登録\n✅ 言語を選択（日本語・English・中文・한국어）\n\nを行ってください。\nいざという時のために必ず設定しておきましょう。',
      color: Color(0xFF1A3A5C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // ── ページビュー ──
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageView(page: _pages[i]),
              ),
            ),

            // ── インジケーター ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
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

            // ── ボタン ──
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
                        child: const Text('戻る', style: TextStyle(color: Colors.grey)),
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
                      onPressed: _page < _pages.length - 1
                          ? () => _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : widget.onDone,
                      child: Text(
                        _page < _pages.length - 1 ? '次へ' : 'アプリを始める',
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

class _Page {
  final String icon;
  final String title;
  final String body;
  final Color color;
  final bool showBell;

  const _Page({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.showBell = false,
  });
}

class _PageView extends StatelessWidget {
  final _Page page;
  const _PageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // アクセントライン
          Container(width: 48, height: 4,
              decoration: BoxDecoration(color: page.color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 32),

          // アイコン
          if (page.showBell)
            const BearBellIcon(size: 72, color: Color(0xFFFFD700))
          else
            Text(page.icon, style: const TextStyle(fontSize: 64)),

          const SizedBox(height: 24),

          // タイトル
          Text(
            page.title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 20),

          // 本文
          Text(
            page.body,
            style: TextStyle(color: Colors.grey[300], fontSize: 15, height: 1.7),
          ),
        ],
      ),
    );
  }
}
