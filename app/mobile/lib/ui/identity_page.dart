import 'dart:async';

import 'package:flutter/material.dart';
import 'package:osn_identity/osn_identity.dart';
import 'package:osn_protocol/osn_protocol.dart';

/// Phase 0.2 的内存身份演示页。
///
/// 这里刻意**不**做持久化：身份只存在内存中，重启即丢失。
/// 页面展示的是协议真实行为（生成密钥、签名、独立验签、篡改后失败），
/// 而不是一个假的"创建成功"流程。
class IdentityPage extends StatefulWidget {
  const IdentityPage({super.key});

  static const regenerateButtonKey = Key('identity.regenerate');
  static const tamperButtonKey = Key('identity.tamper');
  static const statusChipKey = Key('identity.status');
  static const tamperedStatusKey = Key('identity.tamperedStatus');

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage> {
  PeerIdentity? _identity;
  Envelope? _envelope;
  bool? _verified;
  Envelope? _tamperedEnvelope;
  bool? _tamperedVerified;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_generate());
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
      _identity = null;
      _envelope = null;
      _verified = null;
      _tamperedEnvelope = null;
      _tamperedVerified = null;
    });

    try {
      final identity = await PeerIdentity.generate();
      final now = DateTime.now().toUtc();
      final sentAt = formatUtcTimestamp(now);
      final expiresAt = formatUtcTimestamp(now.add(const Duration(hours: 2)));
      final envelope = await identity.signEnvelope(
        type: MessageType.requestCreated,
        sentAt: sentAt,
        payload: <String, Object?>{
          'request_id': '00000000-0000-4000-8000-000000000001',
          'category': 'delivery',
          'title': '从图书馆带一本书',
          'price': <String, Object?>{'amount_minor': 5000, 'currency': 'CNY'},
          'origin': <String, Object?>{
            'label': '图书馆（仅区域，不广播精确坐标）',
            'precision_m': 100,
          },
          'expires_at': expiresAt,
          'nonce': 'AAECAwQFBgcICQoLDA0ODw',
        },
      );
      final verified = await verifyEnvelopeSignature(envelope);
      if (!mounted) {
        return;
      }
      setState(() {
        _identity = identity;
        _envelope = envelope;
        _verified = verified;
        _busy = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = '生成身份失败：$error';
      });
    }
  }

  Future<void> _tamper() async {
    final original = _envelope;
    if (original == null) {
      return;
    }
    final changedPayload = Map<String, Object?>.from(original.payload);
    changedPayload['title'] = '（已篡改）${changedPayload['title']}';
    final tampered = Envelope(
      schemaVersion: original.schemaVersion,
      type: original.type,
      payload: changedPayload,
      senderId: original.senderId,
      sentAt: original.sentAt,
      signature: original.signature,
    );
    final verified = await verifyEnvelopeSignature(tampered);
    if (!mounted) {
      return;
    }
    setState(() {
      _tamperedEnvelope = tampered;
      _tamperedVerified = verified;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地身份（内存）'),
        actions: [
          IconButton(
            key: IdentityPage.regenerateButtonKey,
            onPressed: _busy ? null : _generate,
            tooltip: '重新生成身份',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (_error != null) _ErrorCard(message: _error!),
                  if (!_busy && _error == null && _identity == null)
                    const _ErrorCard(message: '尚未生成身份'),
                  if (_identity != null && _envelope != null) ...[
                    _StatusCard(
                      verified: _verified == true,
                      envelope: _envelope!,
                    ),
                    const SizedBox(height: 16),
                    _IdentityCard(identity: _identity!),
                    const SizedBox(height: 16),
                    _EnvelopeCard(envelope: _envelope!),
                    const SizedBox(height: 16),
                    _VerificationCard(
                      tamperedEnvelope: _tamperedEnvelope,
                      tamperedVerified: _tamperedVerified,
                      onTamper: _tamper,
                    ),
                    const SizedBox(height: 16),
                    const _LimitsCard(),
                  ],
                ],
              ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.verified, required this.envelope});

  final bool verified;
  final Envelope envelope;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              verified ? Icons.verified_outlined : Icons.error_outline,
              color: verified ? scheme.primary : scheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        key: IdentityPage.statusChipKey,
                        label: Text(verified ? '签名有效' : '验签失败'),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: verified
                            ? scheme.primaryContainer
                            : scheme.errorContainer,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '这条信封的签名已用 sender_id 对应的公钥独立验证。'
                    '签名只证明"该密钥签署了这段内容"，不证明需求真实发生。',
                    style: textTheme.bodySmall,
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.identity});

  final PeerIdentity identity;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final publicKeyHex = identity.publicKey
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('身份标识', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            SelectableText(
              identity.identityId,
              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Text('Ed25519 公钥（hex，可公开）', style: textTheme.labelMedium),
            const SizedBox(height: 4),
            SelectableText(
              publicKeyHex,
              style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Text(
              '私钥只保存在这个页面进程的内存里，没有导出接口，也不会写入日志。'
              '关闭页面即丢失；加密备份与持久化属于 Phase 1 / Phase 0.3。',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvelopeCard extends StatelessWidget {
  const _EnvelopeCard({required this.envelope});

  final Envelope envelope;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canonical = canonicalize(envelope.signingPayload());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('演示信封', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            _Field(label: 'type', value: envelope.type.wire),
            _Field(label: 'sender_id', value: envelope.senderId),
            _Field(label: 'sent_at', value: envelope.sentAt),
            _Field(label: 'signature', value: envelope.signature),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text('查看被签名的规范化 JSON', style: textTheme.labelLarge),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
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

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.tamperedEnvelope,
    required this.tamperedVerified,
    required this.onTamper,
  });

  final Envelope? tamperedEnvelope;
  final bool? tamperedVerified;
  final VoidCallback onTamper;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('验证演示', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              '点击按钮会保留原签名、只改 payload 里的标题，再用同一把公钥验签。'
              '预期结果是失败——这正是签名覆盖内容的意义。',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: IdentityPage.tamperButtonKey,
              onPressed: onTamper,
              icon: const Icon(Icons.edit_note),
              label: const Text('篡改标题并验签'),
            ),
            if (tamperedEnvelope != null) ...[
              const SizedBox(height: 12),
              Chip(
                key: IdentityPage.tamperedStatusKey,
                label: Text(
                  tamperedVerified == true ? '篡改后仍然验签通过（异常）' : '篡改后验签失败（符合预期）',
                ),
                visualDensity: VisualDensity.compact,
                backgroundColor: tamperedVerified == true
                    ? scheme.errorContainer
                    : scheme.secondaryContainer,
                side: BorderSide.none,
              ),
              const SizedBox(height: 8),
              Text(
                '篡改后的标题：${tamperedEnvelope!.payload['title']}',
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LimitsCard extends StatelessWidget {
  const _LimitsCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前限制', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final line in const <String>[
              '身份只在内存中，重启应用即丢失。',
              '没有数据库、没有网络、没有 P2P 传输。',
              '不能发布真实需求，也不能用于真实交易。',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· '),
                    Expanded(child: Text(line, style: textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelSmall),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}
