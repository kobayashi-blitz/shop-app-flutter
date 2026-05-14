import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/sinsei_models.dart';
import 'sinsei_service.dart';

final sinseiServiceProvider = Provider<SinseiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SinseiService(apiClient);
});

/// 申請フォーム画面の状態。
class SinseiCreateState {
  final SinseiCreateData? data;
  final bool isLoading;
  final String? error;

  /// 申請送信中
  final bool isSubmitting;

  /// 送信失敗時のエラーメッセージ（成功時 / 未送信時は null）
  final String? submitError;

  /// 送信成功時の sinsei_syonin_id（未送信時は null）
  final int? completedSinseiSyoninId;

  const SinseiCreateState({
    this.data,
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
    this.submitError,
    this.completedSinseiSyoninId,
  });

  SinseiCreateState copyWith({
    SinseiCreateData? data,
    bool? isLoading,
    Object? error = _sentinel,
    bool? isSubmitting,
    Object? submitError = _sentinel,
    Object? completedSinseiSyoninId = _sentinel,
  }) {
    return SinseiCreateState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: identical(submitError, _sentinel)
          ? this.submitError
          : submitError as String?,
      completedSinseiSyoninId: identical(completedSinseiSyoninId, _sentinel)
          ? this.completedSinseiSyoninId
          : completedSinseiSyoninId as int?,
    );
  }

  static const _sentinel = Object();
}

class SinseiNotifier extends StateNotifier<SinseiCreateState> {
  final SinseiService _service;
  final int shopId;
  final int riyosyaId;

  SinseiNotifier(this._service, this.shopId, this.riyosyaId)
      : super(const SinseiCreateState(isLoading: true)) {
    fetchInit();
  }

  /// 初期データ取得。`sinseiKubun` / `selectRentalHoryuId` を切替えるたびに呼ぶ。
  Future<void> fetchInit({
    String sinseiKubun = '1',
    int? selectRentalHoryuId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _service.fetchCreate(
        shopId: shopId,
        riyosyaId: riyosyaId,
        sinseiKubun: sinseiKubun,
        selectRentalHoryuId: selectRentalHoryuId,
      );
      state = state.copyWith(data: data, isLoading: false, error: null);
    } on SinseiApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '取得に失敗しました');
    }
  }

  /// 申請を送信する。成功時に state.completedSinseiSyoninId にセット。
  Future<void> submit({
    required String sinseiKubun,
    required String sinseiFromDate,
    String? sinseiToDate,
    String? sinseiRiyu,
    required List<int> horyucheck,
    required List<int> rentalid,
    required List<String> tankaflag,
    List<int?>? rentalHoryuSyohinId,
    List<String?>? oldHoryuDateFrom,
    List<String?>? oldHoryuDateTo,
  }) async {
    state = state.copyWith(isSubmitting: true, submitError: null);
    try {
      final id = await _service.regist(
        shopId: shopId,
        riyosyaId: riyosyaId,
        sinseiKubun: sinseiKubun,
        sinseiFromDate: sinseiFromDate,
        sinseiToDate: sinseiToDate,
        sinseiRiyu: sinseiRiyu,
        horyucheck: horyucheck,
        rentalid: rentalid,
        tankaflag: tankaflag,
        rentalHoryuSyohinId: rentalHoryuSyohinId,
        oldHoryuDateFrom: oldHoryuDateFrom,
        oldHoryuDateTo: oldHoryuDateTo,
      );
      state = state.copyWith(
        isSubmitting: false,
        completedSinseiSyoninId: id,
        submitError: null,
      );
    } on SinseiApiException catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e.message);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: '申請の送信に失敗しました',
      );
    }
  }
}

/// `(shopId, riyosyaId)` ごとに独立した Notifier を生成。
/// 画面 pop 時に状態破棄。
final sinseiProvider = StateNotifierProvider.autoDispose
    .family<SinseiNotifier, SinseiCreateState, SinseiProviderArgs>(
  (ref, args) => SinseiNotifier(
    ref.watch(sinseiServiceProvider),
    args.shopId,
    args.riyosyaId,
  ),
);

/// `sinseiProvider` の family 引数。
/// (Dart 3 record でも代替可能だが、`==` / `hashCode` を明示する方が安全)
class SinseiProviderArgs {
  final int shopId;
  final int riyosyaId;
  const SinseiProviderArgs({required this.shopId, required this.riyosyaId});

  @override
  bool operator ==(Object other) =>
      other is SinseiProviderArgs &&
      other.shopId == shopId &&
      other.riyosyaId == riyosyaId;

  @override
  int get hashCode => Object.hash(shopId, riyosyaId);
}
