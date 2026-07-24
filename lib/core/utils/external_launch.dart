import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 外部リンク・メール起動の共通ヘルパ。
///
/// `canLaunchUrl` でゲートせず直接 `launchUrl` し、失敗（戻り値 false / 例外）は
/// SnackBar で通知する（delivery_detail_screen.dart の `_dialPhone` と同方針）。

/// 外部ブラウザで [url] を開く。
Future<void> launchExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    _showSnack(context, 'リンクを開けませんでした');
    return;
  }
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) _showSnack(context, 'リンクを開けませんでした');
  } catch (_) {
    if (!context.mounted) return;
    _showSnack(context, 'リンクを開けませんでした');
  }
}

/// [email] 宛の `mailto:` でメールアプリを開く。[subject] を件名に入れられる。
Future<void> launchMailto(
  BuildContext context,
  String email, {
  String? subject,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    query: (subject == null || subject.isEmpty)
        ? null
        : 'subject=${Uri.encodeComponent(subject)}',
  );
  try {
    final ok = await launchUrl(uri);
    if (!context.mounted) return;
    if (!ok) _showSnack(context, 'メールアプリを開けませんでした');
  } catch (_) {
    if (!context.mounted) return;
    _showSnack(context, 'メールアプリを開けませんでした');
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
