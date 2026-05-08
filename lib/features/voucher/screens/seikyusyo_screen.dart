import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/seikyu_month.dart';
import '../providers/voucher_provider.dart';

// 請求書発行画面。月選択 + 小計フラグ + 「PDF を発行」ボタン。
class SeikyusyoScreen extends ConsumerStatefulWidget {
  const SeikyusyoScreen({super.key});

  @override
  ConsumerState<SeikyusyoScreen> createState() => _SeikyusyoScreenState();
}

class _SeikyusyoScreenState extends ConsumerState<SeikyusyoScreen> {
  bool _isLoading = true;
  bool _isIssuing = false;
  String? _error;
  List<SeikyuMonth> _months = [];
  String? _selectedYm;
  bool _showSyokei = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadMonths);
  }

  Future<void> _loadMonths() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = ref.read(authProvider).user;
      final shopId = user?.shopId;
      if (shopId == null) {
        setState(() {
          _isLoading = false;
          _error = 'ログイン情報が取得できませんでした。';
        });
        return;
      }
      final service = ref.read(voucherServiceProvider);
      final months = await service.availableMonths(shopId: shopId);
      setState(() {
        _months = months;
        _selectedYm = months.isNotEmpty ? months.first.yearMonth : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = '月リストの取得に失敗しました';
      });
    }
  }

  Future<void> _issue() async {
    final user = ref.read(authProvider).user;
    final shopId = user?.shopId;
    final ym = _selectedYm;
    if (shopId == null || ym == null) return;

    setState(() => _isIssuing = true);
    try {
      final opener = ref.read(pdfOpenerProvider);
      final result = await opener.fetchAndOpen(
        path: '/api/pcwMobileApi/shop/seikyusyo/issue',
        data: {
          'shop_id': shopId,
          'year_month': ym,
          'syokei': _showSyokei,
        },
        fileBaseName: 'seikyusyo_${ym.replaceAll('-', '')}',
      );
      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? '請求書の発行に失敗しました')),
        );
      }
    } finally {
      if (mounted) setState(() => _isIssuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('請求書発行'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _loadMonths, child: const Text('再読み込み')),
          ],
        ),
      );
    }
    if (_months.isEmpty) {
      return const Center(child: Text('発行可能な請求月がありません'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('請求月',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedYm,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _months
                .map((m) => DropdownMenuItem<String>(
                      value: m.yearMonth,
                      child: Text(m.display),
                    ))
                .toList(),
            onChanged:
                _isIssuing ? null : (v) => setState(() => _selectedYm = v),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ご利用者ごとの小計を印刷する'),
            value: _showSyokei,
            onChanged:
                _isIssuing ? null : (v) => setState(() => _showSyokei = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isIssuing ? null : _issue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _isIssuing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf),
            label: Text(_isIssuing ? '発行中…（最大数分）' : '請求書 PDF を発行'),
          ),
          const SizedBox(height: 8),
          Text(
            '※ 発行には数十秒〜数分かかる場合があります（売上 SQL の重さによる）。',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
