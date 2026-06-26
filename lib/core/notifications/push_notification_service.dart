import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/screens/today_delivery_completed_list_screen.dart';
import '../../features/dashboard/screens/tomorrow_delivery_list_screen.dart';
import '../api/api_client.dart';

/// FCM 通知チャネル。AndroidManifest の `default_notification_channel_id` および
/// pcw 送信ペイロードの `android.notification.channel_id` と**同一文字列**にする。
const String kPushChannelId = 'haisou_push';
const String kPushChannelName = '配送通知';
const String kPushChannelDesc = '配送予定・配送完了のお知らせ';

/// 背面/終了からのタップ遷移に使うグローバル NavigatorKey（`MaterialApp` に設定）。
final navigatorKey = GlobalKey<NavigatorState>();

/// 終了状態(cold launch)からのタップを保留し、認証解決後に処理する。
Map<String, dynamic>? pendingPushTap;

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(apiClientProvider));
});

/// FCM（Android）の受信・トークン登録・タップ遷移をまとめたサービス。
///
/// - 匿名トークン取得（Firebase Auth 不要）→ 当アプリのログイン(`shop_syain_id`)で pcw に紐付け
/// - 前面: ローカル通知で表示／背面・終了: OS が `notification` を自動表示
class PushNotificationService {
  PushNotificationService(this._apiClient);

  final ApiClient _apiClient;
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// アプリ起動後（認証解決後）に一度呼ぶ。許諾・チャネル作成・リスナ登録・トークン登録。
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 通知許諾は FirebaseMessaging に一本化（iOS のダイアログもこれで出す）
    await FirebaseMessaging.instance.requestPermission();

    // ローカル通知（前面表示用）初期化 + 高重要度チャネル作成。
    // iOS の許諾は上で取得済みなので Darwin 側の権限要求は false（二重ダイアログ防止）。
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _fln.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
      onDidReceiveNotificationResponse: (resp) {
        final data = _decodePayload(resp.payload);
        if (data != null) _handleTap(data);
      },
    );
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          kPushChannelId,
          kPushChannelName,
          description: kPushChannelDesc,
          importance: Importance.high,
        ));

    // 前面メッセージ → ローカル通知で表示（背面/終了は OS が自動表示するので二重表示しない）
    FirebaseMessaging.onMessage.listen(_showForeground);
    // 背面からのタップ
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));

    // 終了状態(cold launch)からのタップは保留し、認証後に処理する。
    // FCM 通知由来は getInitialMessage、前面ローカル通知由来は FLN の launch details から拾う。
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      pendingPushTap = initial.data;
    } else {
      final flnLaunch = await _fln.getNotificationAppLaunchDetails();
      if (flnLaunch?.didNotificationLaunchApp ?? false) {
        final data = _decodePayload(flnLaunch?.notificationResponse?.payload);
        if (data != null) pendingPushTap = data;
      }
    }

    // トークン取得 + リフレッシュ（許諾の可否に関わらず登録。表示のみ許諾依存）
    final token = await _getFcmToken();
    if (token != null) await registerToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(registerToken);
  }

  /// FCM トークンを取得。iOS は APNs トークン確定後でないと取得できないため待機する。
  /// 未確定（許諾前/APNs 未設定）なら null を返し、後続の onTokenRefresh で再登録される。
  Future<String?> _getFcmToken() async {
    if (Platform.isIOS) {
      var apns = await FirebaseMessaging.instance.getAPNSToken();
      for (var i = 0; apns == null && i < 3; i++) {
        await Future.delayed(const Duration(seconds: 1));
        apns = await FirebaseMessaging.instance.getAPNSToken();
      }
      if (apns == null) return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  /// ログイン直後に呼ぶ（`shop_syain_id` 確定後のトークン登録）。
  Future<void> onLoggedIn() async {
    final token = await _getFcmToken();
    if (token != null) await registerToken(token);
  }

  /// ログイン済みなら保留中のタップ（cold launch 分）を処理する。
  void processPendingTap() {
    final data = pendingPushTap;
    if (data != null) {
      pendingPushTap = null;
      _handleTap(data);
    }
  }

  /// FCM トークンを pcw に登録（`shop_syain_id` と紐付け）。未ログイン時は no-op。
  Future<void> registerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final shopSyainId = prefs.getString('sp_shop_syain_id');
    final shopId = prefs.getString('sp_shop_id');
    if (shopSyainId == null || shopId == null) return; // ログイン後に再登録
    try {
      await _apiClient.post(
        '/api/pcwMobileApi/shop/device-token/register',
        data: {
          'shop_id': int.tryParse(shopId),
          'shop_syain_id': int.tryParse(shopSyainId),
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } catch (e) {
      // pcw 側エンドポイント未実装の段階では失敗してもアプリは継続
      debugPrint('### device-token register failed: $e');
    }
  }

  /// ログアウト時：pcw からトークンを解除し、端末トークンも破棄。
  Future<void> unregisterToken() async {
    final prefs = await SharedPreferences.getInstance();
    final shopSyainId = prefs.getString('sp_shop_syain_id');
    final token = await _getFcmToken();
    if (shopSyainId != null && token != null) {
      try {
        await _apiClient.post(
          '/api/pcwMobileApi/shop/device-token/unregister',
          data: {'shop_syain_id': int.tryParse(shopSyainId), 'token': token},
        );
      } catch (e) {
        debugPrint('### device-token unregister failed: $e');
      }
    }
    await FirebaseMessaging.instance.deleteToken();
  }

  void _showForeground(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return; // data only は前面表示しない
    _fln.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          kPushChannelId,
          kPushChannelName,
          channelDescription: kPushChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(m.data),
    );
  }

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  /// payload `type` に応じて遷移（ナビゲータが既知＝認証完了後でのみ呼ばれる前提）。
  void _handleTap(Map<String, dynamic> data) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    switch (data['type']?.toString()) {
      case 'haisou_yotei':
        nav.push(MaterialPageRoute(
          builder: (_) => TomorrowDeliveryListScreen(
            targetDate: _parseDate(data['date']?.toString()),
          ),
        ));
        break;
      case 'haisou_kanryo':
        nav.push(MaterialPageRoute(
          builder: (_) => const TodayDeliveryCompletedListScreen(),
        ));
        break;
      default:
        nav.push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
    }
  }

  /// payload の `date`(YYYY-MM-DD) をパース。無ければ翌日。
  DateTime _parseDate(String? s) {
    if (s != null) {
      final d = DateTime.tryParse(s);
      if (d != null) return d;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }
}
