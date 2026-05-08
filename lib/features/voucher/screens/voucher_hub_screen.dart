import 'package:flutter/material.dart';

import 'denpyo_search_screen.dart';
import 'seikyusyo_screen.dart';

// 伝票照会のハブ。請求書発行 / お客様控え伝票検索の 2 メニュー。
class VoucherHubScreen extends StatelessWidget {
  const VoucherHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('伝票照会'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            icon: Icons.receipt_long,
            title: '請求書発行',
            description: '指定月の請求書を PDF で発行',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SeikyusyoScreen(),
              ));
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.description_outlined,
            title: 'お客様控え伝票検索',
            description: '納品 / 返却 / 預かり 等の控え伝票を検索・PDF 表示',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DenpyoSearchScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.indigo.shade700, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}
