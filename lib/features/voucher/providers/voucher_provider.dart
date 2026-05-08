import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pdf_opener.dart';
import '../../auth/providers/auth_provider.dart';
import 'voucher_service.dart';

final voucherServiceProvider = Provider<VoucherService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VoucherService(apiClient);
});

final pdfOpenerProvider = Provider<PdfOpener>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PdfOpener(apiClient);
});
