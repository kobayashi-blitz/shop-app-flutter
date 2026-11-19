import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/notifications/push_notification_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/auth_service.dart';
import 'features/auth/providers/session_controller.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

/// 背面/終了時の FCM メッセージを処理するトップレベルハンドラ（別 isolate のため Firebase 再初期化が必須）。
/// `notification` ペイロードは OS が自動でトレイ表示するため、ここでは表示処理はしない。
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 画面を縦固定（Portrait ロック）。iOS/Android のネイティブ側でも縦のみに制限している。
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<void>? _unauthorizedSub;

  @override
  void initState() {
    super.initState();
    // 401 (トークンが無効) を受けたらログアウトしてログイン画面に戻す。
    // AuthWrapper は画面を移ると消えるので、アプリのルートで受ける。
    _unauthorizedSub = ref
        .read(apiClientProvider)
        .unauthorizedEvents
        .listen((_) => _onUnauthorized());
  }

  Future<void> _onUnauthorized() async {
    await ref.read(sessionControllerProvider).expire();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '介護ショップ担当者アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      locale: const Locale('ja', 'JP'),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final auth = ref.read(authProvider.notifier);
    await auth.initialized;
    // 旧版でログインしたまま更新した人は、トークンが無いので 1 回だけ再ログインしてもらう。
    // push の init より前に行い、旧 shop_syain_id での FCM 登録を解除しておく。
    if (auth.startupCheck is SessionNeedsRelogin) {
      await ref.read(sessionControllerProvider).forceRelogin();
    }
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(pushNotificationServiceProvider).resume();
    }

    // FCM 初期化（許諾・チャネル・リスナ・トークン登録）。認証解決後に一度だけ。
    await ref.read(pushNotificationServiceProvider).init();

    if (mounted) {
      setState(() {
        _isChecking = false;
      });

      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        // 終了状態からの通知タップ（保留分）をダッシュボードの上に積む
        ref.read(pushNotificationServiceProvider).processPendingTap();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const LoginScreen();
  }
}
