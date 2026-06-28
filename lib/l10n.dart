import 'package:flutter/material.dart';

enum AppLanguage { ja, en, zh, ko }

class L10n {
  final AppLanguage lang;
  const L10n(this.lang);

  static const _strings = {
    AppLanguage.ja: {
      'appTitle': 'Smart Bear Bell',
      'preventMode': '予防モード（スマート鈴）',
      'walkingActive': '歩行中に自動で音を鳴らします',
      'off': 'オフ',
      'emergencyBtn': '緊急撃退  長押しで発動',
      'emergencyActive': '撃退中 — タップして停止',
      'settings': '設定',
      'language': '言語',
      'sosTitle': '緊急SOS連絡先',
      'sosName': '名前',
      'sosPhone': '電話番号',
      'sosSave': '保存',
      'sosSaved': '保存しました',
      'sosSending': 'SOS送信中...',
      'sosSent': 'SOSを送信しました',
      'sosMessage': '【緊急】クマと遭遇しました！現在地: ',
      'sosNoContact': 'SOS連絡先が未登録です。設定から登録してください。',
      'sosDialogTitle': 'SOS送信確認',
      'sosDialogBody': '登録された連絡先にGPS座標付きSOSを送信します。',
      'cancel': 'キャンセル',
      'send': '送信',
    },
    AppLanguage.en: {
      'appTitle': 'Smart Bear Bell',
      'preventMode': 'Prevention Mode (Smart Bell)',
      'walkingActive': 'Auto sound while walking',
      'off': 'Off',
      'emergencyBtn': 'EMERGENCY  Hold to activate',
      'emergencyActive': 'Active — Tap to stop',
      'settings': 'Settings',
      'language': 'Language',
      'sosTitle': 'Emergency SOS Contact',
      'sosName': 'Name',
      'sosPhone': 'Phone number',
      'sosSave': 'Save',
      'sosSaved': 'Saved',
      'sosSending': 'Sending SOS...',
      'sosSent': 'SOS sent',
      'sosMessage': '[EMERGENCY] Bear encounter! Location: ',
      'sosNoContact': 'No SOS contact registered. Please add one in Settings.',
      'sosDialogTitle': 'Confirm SOS',
      'sosDialogBody': 'Send SOS with GPS coordinates to your registered contact.',
      'cancel': 'Cancel',
      'send': 'Send',
    },
    AppLanguage.zh: {
      'appTitle': 'Smart Bear Bell',
      'preventMode': '预防模式（智能铃）',
      'walkingActive': '步行时自动发声',
      'off': '关闭',
      'emergencyBtn': '紧急驱熊  长按启动',
      'emergencyActive': '驱熊中 — 点击停止',
      'settings': '设置',
      'language': '语言',
      'sosTitle': '紧急SOS联系人',
      'sosName': '姓名',
      'sosPhone': '电话号码',
      'sosSave': '保存',
      'sosSaved': '已保存',
      'sosSending': '正在发送SOS...',
      'sosSent': 'SOS已发送',
      'sosMessage': '【紧急】遭遇熊！当前位置: ',
      'sosNoContact': '未注册SOS联系人，请在设置中添加。',
      'sosDialogTitle': '确认发送SOS',
      'sosDialogBody': '向注册联系人发送含GPS坐标的SOS。',
      'cancel': '取消',
      'send': '发送',
    },
    AppLanguage.ko: {
      'appTitle': 'Smart Bear Bell',
      'preventMode': '예방 모드（스마트 벨）',
      'walkingActive': '보행 중 자동으로 소리를 냅니다',
      'off': '끄기',
      'emergencyBtn': '긴급 퇴치  길게 눌러 작동',
      'emergencyActive': '퇴치 중 — 탭하여 중지',
      'settings': '설정',
      'language': '언어',
      'sosTitle': '긴급 SOS 연락처',
      'sosName': '이름',
      'sosPhone': '전화번호',
      'sosSave': '저장',
      'sosSaved': '저장되었습니다',
      'sosSending': 'SOS 발송 중...',
      'sosSent': 'SOS 발송 완료',
      'sosMessage': '【긴급】곰과 조우했습니다！현재 위치: ',
      'sosNoContact': 'SOS 연락처가 등록되지 않았습니다. 설정에서 등록해 주세요.',
      'sosDialogTitle': 'SOS 발송 확인',
      'sosDialogBody': '등록된 연락처에 GPS 좌표가 포함된 SOS를 발송합니다.',
      'cancel': '취소',
      'send': '발송',
    },
  };

  String get(String key) => _strings[lang]?[key] ?? key;

  static const langLabels = {
    AppLanguage.ja: '日本語',
    AppLanguage.en: 'English',
    AppLanguage.zh: '中文',
    AppLanguage.ko: '한국어',
  };

  Locale get locale => switch (lang) {
        AppLanguage.ja => const Locale('ja'),
        AppLanguage.en => const Locale('en'),
        AppLanguage.zh => const Locale('zh'),
        AppLanguage.ko => const Locale('ko'),
      };
}
