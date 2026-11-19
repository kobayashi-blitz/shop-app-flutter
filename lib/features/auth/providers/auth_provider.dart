import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/models/user.dart';
import 'auth_service.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient, ref.watch(tokenStorageProvider));
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  /// ログイン画面に出す案内 (セッション切れ・アプリ更新後の再ログインなど)。
  final String? notice;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.notice,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notice: notice,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  late final Future<void> initialized;

  /// 起動時の判定結果。旧版からの更新 (SessionNeedsRelogin) の検出に使う。
  SessionCheck startupCheck = const SessionLoggedOut();

  AuthNotifier(this._authService) : super(AuthState()) {
    initialized = _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      startupCheck = await _authService.checkSession();
    } catch (_) {
      startupCheck = const SessionLoggedOut();
    }
    final check = startupCheck;
    if (check is SessionLoggedIn) {
      state = state.copyWith(user: check.user);
    }
  }

  Future<bool> login(String loginId, String loginPassword) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _authService.login(
        loginId,
        loginPassword,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// ログアウト後の状態にする。端末の保存値の削除は SessionController が行う。
  void reset({String? notice}) {
    state = AuthState(notice: notice);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
