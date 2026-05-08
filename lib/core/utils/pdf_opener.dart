import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';

class PdfOpenResult {
  final bool ok;
  final String? errorMessage;

  const PdfOpenResult.success()
      : ok = true,
        errorMessage = null;
  const PdfOpenResult.failure(String message)
      : ok = false,
        errorMessage = message;
}

class PdfOpener {
  final ApiClient _apiClient;

  PdfOpener(this._apiClient);

  /// pcw 側に POST して PDF バイナリを取得 → 一時ファイルに保存 → OS 既定アプリで開く
  Future<PdfOpenResult> fetchAndOpen({
    required String path,
    required Map<String, dynamic> data,
    required String fileBaseName,
    Duration receiveTimeout = const Duration(seconds: 180),
  }) async {
    try {
      final res = await _apiClient.postBytes(
        path,
        data: data,
        receiveTimeout: receiveTimeout,
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) {
        return const PdfOpenResult.failure('PDF が空でした');
      }

      // pcw が text/html (504/エラー JSON) を返した場合は弾く
      final contentType = res.headers.value('content-type') ?? '';
      if (!contentType.toLowerCase().contains('application/pdf')) {
        return PdfOpenResult.failure(
            'サーバから PDF が返りませんでした (content-type: $contentType)');
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/${fileBaseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        return PdfOpenResult.failure('PDF を開けませんでした: ${result.message}');
      }
      return const PdfOpenResult.success();
    } catch (e) {
      return PdfOpenResult.failure('通信エラー: $e');
    }
  }
}
