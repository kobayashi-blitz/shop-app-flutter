import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/legal_links.dart';
import '../../../core/utils/external_launch.dart';
import '../../auth/providers/auth_provider.dart';

/// マイページ。ログインユーザーのプロフィールと、申請/サポート用の情報導線を表示する。
///
/// 表示のみ（Dio 直叩きなし）。ユーザー情報は [authProvider] から取得する。
class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final shopName = user?.shopName ?? '';
    final staffName = user?.shopSyainName ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _ProfileCard(shopName: shopName, staffName: staffName),
          const _SectionHeader('情報'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () =>
                launchExternalUrl(context, LegalLinks.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('データ削除のお問い合わせ'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchExternalUrl(context, LegalLinks.contactFormUrl),
          ),
          const Divider(height: 1),
          const _VersionTile(),
        ],
      ),
    );
  }
}

/// 店舗名・担当者名を表示するプロフィールカード。値が空の行は出さない。
class _ProfileCard extends StatelessWidget {
  final String shopName;
  final String staffName;

  const _ProfileCard({required this.shopName, required this.staffName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.indigo.shade50,
              child: Icon(Icons.person, color: Colors.indigo.shade400),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shopName.isNotEmpty)
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (staffName.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: shopName.isEmpty ? 0 : 4),
                      child: Text(
                        '$staffName 様',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (shopName.isEmpty && staffName.isEmpty)
                    Text(
                      'ログインユーザー',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// リスト内の見出し。
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade700,
        ),
      ),
    );
  }
}

/// アプリのバージョンを表示する行（非タップ）。
class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final versionText =
            info == null ? '—' : '${info.version} (build ${info.buildNumber})';
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('バージョン'),
          trailing: Text(
            versionText,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        );
      },
    );
  }
}
