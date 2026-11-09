import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import 'tanto_service.dart';

final tantoServiceProvider = Provider<TantoService>((ref) {
  return TantoService(ref.watch(apiClientProvider));
});
