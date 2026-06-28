import 'package:flutter/foundation.dart';

class SosContact {
  final String name;
  final String phone;
  const SosContact({required this.name, required this.phone});
}

class SosService {
  SosContact? _contact;

  SosContact? get contact => _contact;

  void setContact(SosContact contact) {
    _contact = contact;
  }

  // GPS座標を取得（デモ：固定値、実機はgeolocatorで取得）
  Future<String> _getLocationText() async {
    if (kIsWeb) {
      // WebデモではGeolocation APIをJS経由で呼ぶことも可能だが、
      // ここではデモ用固定値を返す
      return '35.6762° N, 139.6503° E（デモ位置情報）';
    }
    // 実機実装例（geolocatorを追加した場合）:
    // final pos = await Geolocator.getCurrentPosition();
    // return '${pos.latitude}° N, ${pos.longitude}° E';
    return '35.6762° N, 139.6503° E（デモ位置情報）';
  }

  // SMS送信（モバイル実機ではsms:スキームでネイティブSMSアプリを開く）
  Future<SosResult> sendSos(String messagePrefix) async {
    if (_contact == null) {
      return SosResult.noContact;
    }

    final location = await _getLocationText();
    final message = '$messagePrefix$location';

    if (kIsWeb) {
      // Web版ではSMS送信不可のため、ダイアログで内容を表示するのみ
      debugPrint('[SOS] 送信先: ${_contact!.phone}');
      debugPrint('[SOS] メッセージ: $message');
      return SosResult.webDemo;
    }

    // 実機実装（url_launcherを追加した場合）:
    // final uri = Uri(
    //   scheme: 'sms',
    //   path: _contact!.phone,
    //   queryParameters: {'body': message},
    // );
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri);
    //   return SosResult.sent;
    // }
    return SosResult.failed;
  }
}

enum SosResult { sent, noContact, failed, webDemo }
