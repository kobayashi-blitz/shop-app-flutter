import 'package:flutter/material.dart';

import '../../../core/utils/display_format.dart';
import '../../../core/widgets/riyosya_name_text.dart';
import '../models/tanto_models.dart';

/// 利用者 1 行 (チェック・氏名・住所・担当者・契約件数)。
class TantoRiyosyaCard extends StatelessWidget {
  const TantoRiyosyaCard({
    super.key,
    required this.item,
    required this.checked,
    required this.onChanged,
    this.note,
  });

  final TantoRiyosyaItem item;
  final bool checked;

  /// null のときはチェックを操作できない。
  final ValueChanged<bool>? onChanged;

  /// 行の下に出す案内 (自分の担当で外せない理由など)。
  final String? note;

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey.shade700;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                onChanged:
                    onChanged == null ? null : (v) => onChanged!(v ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RiyosyaNameText(
                      name: item.riyosyaName ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((item.riyosyaKana ?? '').trim().isNotEmpty)
                      Text(
                        item.riyosyaKana!,
                        style: TextStyle(fontSize: 12, color: grey),
                      ),
                    if (item.jyusyo.isNotEmpty)
                      Text(
                        item.jyusyo,
                        style: TextStyle(fontSize: 12, color: grey),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 16,
                          color:
                              item.isMisettei ? Colors.orange.shade800 : grey,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.tantoLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: item.isMisettei
                                  ? Colors.orange.shade800
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '契約中 ${item.keiyakutyuCount}件・過去 ${item.kakoCount}件',
                          style: TextStyle(fontSize: 12, color: grey),
                        ),
                      ],
                    ),
                    if (note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ページ移動。件数が 0 でも、範囲外のページから戻れるように前へのボタンは残す。
class TantoPager extends StatelessWidget {
  const TantoPager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.enabled,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final bool enabled;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1 && page <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: '前のページ',
            onPressed: enabled && page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$page / $totalPages ページ'),
          IconButton(
            tooltip: '次のページ',
            onPressed:
                enabled && page < totalPages ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// 確認ダイアログや結果メッセージ用に、利用者名を最大 [max] 人まで並べる。
String describeRiyosyaNames(Iterable<TantoRiyosyaItem> items, {int max = 5}) {
  final list = items.toList();
  final names = list
      .take(max)
      .map((e) => formatRiyosyaName(e.riyosyaName ?? ''))
      .join('、');
  final rest = list.length - max;
  return rest > 0 ? '$names ほか$rest人' : names;
}

/// 選んでいる利用者を一覧で見て外せるシート。今のページや条件に出ていない人も外せる。
Future<void> showTantoSelectionSheet({
  required BuildContext context,
  required String title,
  required Map<int, TantoRiyosyaItem> selection,
  required ValueChanged<int> onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final items = selection.values.toList();
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('$title（${items.length}人）'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
                const Divider(height: 1),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('選んでいる利用者はいません。'),
                  ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        title: RiyosyaNameText(name: item.riyosyaName ?? ''),
                        subtitle: Text(item.tantoLabel),
                        trailing: TextButton(
                          onPressed: () {
                            onRemove(item.riyosyaId);
                            setSheetState(() {});
                          },
                          child: const Text('外す'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
