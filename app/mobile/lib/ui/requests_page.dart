import 'dart:async';

import 'package:flutter/material.dart';
import 'package:osn_identity/osn_identity.dart';
import 'package:osn_protocol/osn_protocol.dart';

/// Phase 0.2b 的内存需求公告板。
///
/// 需求由本机临时身份签名，并立即用 `sender_id` 对应的公钥独立验签。
/// 没有网络、没有数据库：列表只存在当前页面状态里，关闭即丢失。
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  static const publishButtonKey = Key('requests.publish');
  static const emptyStateKey = Key('requests.empty');

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  PeerIdentity? _identity;
  final List<_SignedRequest> _items = <_SignedRequest>[];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final identity = await PeerIdentity.generate();
      final first = await _createSignedRequest(identity, 0);
      if (!mounted) {
        return;
      }
      setState(() {
        _identity = identity;
        _items
          ..clear()
          ..add(first);
        _busy = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = '初始化公告板失败：$error';
      });
    }
  }

  Future<void> _publish() async {
    final identity = _identity;
    if (identity == null || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final item = await _createSignedRequest(identity, _items.length);
      if (!mounted) {
        return;
      }
      setState(() {
        _items.insert(0, item);
        _busy = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = '发布失败：$error';
      });
    }
  }

  Future<_SignedRequest> _createSignedRequest(
    PeerIdentity identity,
    int index,
  ) async {
    final now = DateTime.now().toUtc();
    final createdAt = formatUtcTimestamp(now);
    final expiresAt = formatUtcTimestamp(now.add(const Duration(hours: 2)));
    final start = formatUtcTimestamp(now.add(const Duration(minutes: 30)));
    final end = formatUtcTimestamp(now.add(const Duration(minutes: 90)));

    final request = Request(
      requestId: Request.newId(),
      creatorId: identity.identityId,
      category: RequestCategory.values[index % 3],
      title: _demoTitles[index % _demoTitles.length],
      description: '这是本机生成的内存示例需求；没有网络，也不会广播。',
      origin: Place(label: _demoPlaces[index % _demoPlaces.length]),
      destination: Place(label: _demoPlaces[(index + 1) % _demoPlaces.length]),
      timeWindow: TimeWindow(start: start, end: end),
      price: const Price(amountMinor: 5000, currency: 'CNY'),
      createdAt: createdAt,
      expiresAt: expiresAt,
      nonce: Request.newNonce(),
    );

    // 先经过一次模型校验，避免把 UI 里的笔误签进信封。
    final validated = Request.fromJson(request.toJson());
    final envelope = await identity.signEnvelope(
      type: MessageType.requestCreated,
      sentAt: createdAt,
      payload: validated.toJson(),
    );
    final verified = await verifyEnvelopeSignature(envelope);
    return _SignedRequest(
      request: validated,
      envelope: envelope,
      verified: verified,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('需求公告板（内存）')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('本机内存公告板', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '每条需求都由本机临时身份签名，并立即用 sender_id 对应的公钥独立验签。'
                      '没有网络，所以只有这台设备能看到；关闭页面即丢失。',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: RequestsPage.publishButtonKey,
                      onPressed: _busy ? null : _publish,
                      icon: const Icon(Icons.add),
                      label: const Text('发布示例需求'),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!),
                ),
              ),
            ],
            if (_busy && _items.isEmpty) ...[
              const SizedBox(height: 32),
              const Center(child: CircularProgressIndicator()),
            ],
            if (!_busy && _items.isEmpty) ...[
              const SizedBox(height: 24),
              const Center(
                key: RequestsPage.emptyStateKey,
                child: Text('还没有需求'),
              ),
            ],
            for (final item in _items) ...[
              const SizedBox(height: 16),
              _RequestCard(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignedRequest {
  const _SignedRequest({
    required this.request,
    required this.envelope,
    required this.verified,
  });

  final Request request;
  final Envelope envelope;
  final bool verified;
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item});

  final _SignedRequest item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final request = item.request;
    final canonical = canonicalize(item.envelope.signingPayload());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(request.title, style: textTheme.titleMedium),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_categoryLabel(request.category)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: scheme.secondaryContainer,
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatAmount(request.price)} · '
              '${_shortTime(request.timeWindow.start)}–'
              '${_shortTime(request.timeWindow.end)} UTC',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${request.origin?.label ?? '未指定起点'} → '
              '${request.destination?.label ?? '未指定终点'}',
              style: textTheme.bodySmall,
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.description, style: textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: Icon(
                    item.verified
                        ? Icons.verified_outlined
                        : Icons.error_outline,
                    size: 16,
                    color: item.verified ? scheme.primary : scheme.error,
                  ),
                  label: Text(item.verified ? '签名有效' : '验签失败'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: item.verified
                      ? scheme.primaryContainer
                      : scheme.errorContainer,
                  side: BorderSide.none,
                ),
                Text(
                  'request.created · ${_shortTime(request.createdAt)} UTC',
                  style: textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              'request_id: ${request.requestId}',
              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text('查看签名与规范化 JSON', style: textTheme.labelLarge),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'signature: ${item.envelope.signature}',
                    style: textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    canonical,
                    style: textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _demoTitles = <String>['从图书馆带一本书', '帮忙取一份快递', '顺路带一杯咖啡'];

const List<String> _demoPlaces = <String>['图书馆', '东门', '地铁站', '便利店'];

String _categoryLabel(RequestCategory category) => switch (category) {
  RequestCategory.ride => '出行',
  RequestCategory.delivery => '带物',
  RequestCategory.food => '餐饮',
  RequestCategory.errand => '跑腿',
  RequestCategory.other => '其他',
};

String _formatAmount(Price price) {
  final major = price.amountMinor ~/ 100;
  final cents = (price.amountMinor % 100).toString().padLeft(2, '0');
  return '${price.currency} $major.$cents';
}

String _shortTime(String timestamp) => timestamp.substring(11, 16);
