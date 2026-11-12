import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/push_notification_service.dart';
import 'auth_provider.dart';

final sessionControllerProvider = Provider<SessionController>((ref) {
  return SessionController(ref);
});

/// ログアウトの手順をまとめる (自分でログアウト・401・アプリ更新後の再ログイン)。
///
/// 画面の移動はしない。呼び出し側 (ダッシュボード・アプリのルート) が行う。
class SessionController {
  SessionController(this._ref);

  final Ref _ref;
  Future<void>? _running;

  static const expiredNotice = 'ログインの有効期限が切れました。もう一度ログインしてください。';
  static const reloginNotice = 'アプリを更新したため、もう一度ログインしてください。';

  /// ログアウトボタンから。pcw 側の今のトークンも消す。
  Future<void> logout() => _end(callServer: true);

  /// 401 を受けたとき。トークンはもう無効なので pcw には送らない。
  Future<void> expire() => _end(callServer: false, notice: expiredNotice);

  /// 旧版でログインしたまま更新し、トークンを持っていないとき。
  Future<void> forceRelogin() => _end(callServer: false, notice: reloginNotice);

  /// 実行中に別の理由で呼ばれても (logout 中の 401 など)、処理は 1 回だけにする。
  Future<void> _end({required bool callServer, String? notice}) {
    return _running ??= _endSession(callServer: callServer, notice: notice)
        .whenComplete(() => _running = null);
  }

  Future<void> _endSession({required bool callServer, String? notice}) async {
    final push = _ref.read(pushNotificationServiceProvider);
    final authService = _ref.read(authServiceProvider);
    push.suspend();
    // どちらかに失敗しても、残りの手順と端末のログイン情報の削除は必ず行う。
    try {
      // shop_syain_id が prefs に残っているうちに FCM トークンを解除する。
      await push.unregisterToken();
    } catch (_) {}
    if (callServer) {
      try {
        await authService.logoutRemote();
      } catch (_) {}
    }
    try {
      await authService.clearSession();
    } finally {
      // ダッシュボードなどログイン中の人に属する Provider は
      // authProvider の user を watch しているので、ここで作り直される。
      _ref.read(authProvider.notifier).reset(notice: notice);
    }
  }
}
